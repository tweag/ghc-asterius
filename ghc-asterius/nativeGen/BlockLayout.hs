--
-- Copyright (c) 2018 Andreas Klebinger
--

{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleContexts #-}

module BlockLayout
    ( sequenceTop )
where

#include "HsVersions.h"
import GhcPrelude

import Instruction
import NCGMonad
import CFG

import BlockId
import Cmm
import Hoopl.Collections
import Hoopl.Label

import DynFlags (gopt, GeneralFlag(..), DynFlags, backendMaintainsCfg)
import UniqFM
import Util
import Unique

import Digraph
import Outputable
import Maybes

-- DEBUGGING ONLY
--import Debug
--import Debug.Trace
import ListSetOps (removeDups)

import OrdList
import Data.List
import Data.Foldable (toList)

import qualified Data.Set as Set
import Data.STRef
import Control.Monad.ST.Strict
import Control.Monad (foldM)

{-
  Note [CFG based code layout]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  The major steps in placing blocks are as follow:
  * Compute a CFG based on the Cmm AST, see getCfgProc.
    This CFG will have edge weights representing a guess
    on how important they are.
  * After we convert Cmm to Asm we run `optimizeCFG` which
    adds a few more "educated guesses" to the equation.
  * Then we run loop analysis on the CFG (`loopInfo`) which tells us
    about loop headers, loop nesting levels and the sort.
  * Based on the CFG and loop information refine the edge weights
    in the CFG and normalize them relative to the most often visited
    node. (See `mkGlobalWeights`)
  * Feed this CFG into the block layout code (`sequenceTop`) in this
    module. Which will then produce a code layout based on the input weights.

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ~~~ Note [Chain based CFG serialization]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  For additional information also look at
  https://gitlab.haskell.org/ghc/ghc/wikis/commentary/compiler/code-layout

  We have a CFG with edge weights based on which we try to place blocks next to
  each other.

  Edge weights not only represent likelyhood of control transfer between blocks
  but also how much a block would benefit from being placed sequentially after
  it's predecessor.
  For example blocks which are preceeded by an info table are more likely to end
  up in a different cache line than their predecessor and we can't eliminate the jump
  so there is less benefit to placing them sequentially.

  For example consider this example:

  A:  ...
      jmp cond D (weak successor)
      jmp B
  B:  ...
      jmp C
  C:  ...
      jmp X
  D:  ...
      jmp B (weak successor)

  We determine a block layout by building up chunks (calling them chains) of
  possible control flows for which blocks will be placed sequentially.

  Eg for our example we might end up with two chains like:
  [A->B->C->X],[D]. Blocks inside chains will always be placed sequentially.
  However there is no particular order in which chains are placed since
  (hopefully) the blocks for which sequentiality is important have already
  been placed in the same chain.

  -----------------------------------------------------------------------------
     1) First try to create a list of good chains.
  -----------------------------------------------------------------------------

  Good chains are these which allow us to eliminate jump instructions.
  Which further eliminate often executed jumps first.

  We do so by:

  *)  Ignore edges which represent instructions which can not be replaced
      by fall through control flow. Primarily calls and edges to blocks which
      are prefixed by a info table we have to jump across.

  *)  Then process remaining edges in order of frequency taken and:

    +)  If source and target have not been placed build a new chain from them.

    +)  If source and target have been placed, and are ends of differing chains
        try to merge the two chains.

    +)  If one side of the edge is a end/front of a chain, add the other block of
        to edge to the same chain

        Eg if we look at edge (B -> C) and already have the chain (A -> B)
        then we extend the chain to (A -> B -> C).

    +)  If the edge was used to modify or build a new chain remove the edge from
        our working list.

  *) If there any blocks not being placed into a chain after these steps we place
     them into a chain consisting of only this block.

  Ranking edges by their taken frequency, if
  two edges compete for fall through on the same target block, the one taken
  more often will automatically win out. Resulting in fewer instructions being
  executed.

  Creating singleton chains is required for situations where we have code of the
  form:

    A: goto B:
    <infoTable>
    B: goto C:
    <infoTable>
    C: ...

  As the code in block B is only connected to the rest of the program via edges
  which will be ignored in this step we make sure that B still ends up in a chain
  this way.

  -----------------------------------------------------------------------------
     2) We also try to fuse chains.
  -----------------------------------------------------------------------------

  As a result from the above step we still end up with multiple chains which
  represent sequential control flow chunks. But they are not yet suitable for
  code layout as we need to place *all* blocks into a single sequence.

  In this step we combine chains result from the above step via these steps:

  *)  Look at the ranked list of *all* edges, including calls/jumps across info tables
      and the like.

  *)  Look at each edge and

    +) Given an edge (A -> B) try to find two chains for which
      * Block A is at the end of one chain
      * Block B is at the front of the other chain.
    +) If we find such a chain we "fuse" them into a single chain, remove the
       edge from working set and continue.
    +) If we can't find such chains we skip the edge and continue.

  -----------------------------------------------------------------------------
     3) Place indirect successors (neighbours) after each other
  -----------------------------------------------------------------------------

  We might have chains [A,B,C,X],[E] in a CFG of the sort:

    A ---> B ---> C --------> X(exit)
                   \- ->E- -/

  While E does not follow X it's still beneficial to place them near each other.
  This can be advantageous if eg C,X,E will end up in the same cache line.

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ~~~ Note [Triangle Control Flow]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Checking if an argument is already evaluated leads to a somewhat
  special case  which looks like this:

    A:
        if (R1 & 7 != 0) goto Leval; else goto Lwork;
    Leval: // global
        call (I64[R1])(R1) returns to Lwork, args: 8, res: 8, upd: 8;
    Lwork: // global
        ...

        A
        |\
        | Leval
        |/ - (This edge can be missing because of optimizations)
        Lwork

  Once we hit the metal the call instruction is just 2-3 bytes large
  depending on the register used. So we lay out the assembly like this:

        movq %rbx,%rax
        andl $7,%eax
        cmpq $1,%rax
        jne Lwork
    Leval:
        jmp *(%rbx) # encoded in 2-3 bytes.
    <info table>
    Lwork:
        ...

  We could explicitly check for this control flow pattern.

  This is advantageous because:
  * It's optimal if the argument isn't evaluated.
  * If it's evaluated we only have the extra cost of jumping over
    the 2-3 bytes for the call.
  * Guarantees the smaller encoding for the conditional jump.

  However given that Lwork usually has an info table we
  penalize this edge. So Leval should get placed first
  either way and things work out for the best.

  Optimizing for the evaluated case instead would penalize
  the other code path. It adds an jump as we can't fall through
  to Lwork because of the info table.
  Assuming that Lwork is large the chance that the "call" ends up
  in the same cache line is also fairly small.

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ~~~ Note [Layout relevant edge weights]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  The input to the chain based code layout algorithm is a CFG
  with edges annotated with their frequency. The frequency
  of traversal corresponds quite well to the cost of not placing
  the connected blocks next to each other.

  However even if having the same frequency certain edges are
  inherently more or less relevant to code layout.

  In particular:

  * Edges which cross an info table are less relevant than others.

    If we place the blocks across this edge next to each other
    they are still separated by the info table which negates
    much of the benefit. It makes it less likely both blocks
    will share a cache line reducing the benefits from locality.
    But it also prevents us from eliminating jump instructions.

  * Conditional branches and switches are slightly less relevant.

    We can completely remove unconditional jumps by placing them
    next to each other. This is not true for conditional branch edges.
    We apply a small modifier to them to ensure edges for which we can
    eliminate the overhead completely are considered first. See also #18053.

  * Edges constituted by a call are ignored.

    Considering these hardly helped with performance and ignoring
    them helps quite a bit to improve compiler performance.

  So we perform a preprocessing step where we apply a multiplicator
  to these kinds of edges.

  -}


-- | Look at X number of blocks in two chains to determine
--   if they are "neighbours".
neighbourOverlapp :: Int
neighbourOverlapp = 2

-- | Maps blocks near the end of a chain to it's chain AND
-- the other blocks near the end.
-- [A,B,C,D,E] Gives entries like (B -> ([A,B], [A,B,C,D,E]))
-- where [A,B] are blocks in the end region of a chain.
-- This is cheaper then recomputing the ends multiple times.
type FrontierMap = LabelMap ([BlockId],BlockChain)

-- | A non empty ordered sequence of basic blocks.
--   It is suitable for serialization in this order.
--
--   We use OrdList instead of [] to allow fast append on both sides
--   when combining chains.
newtype BlockChain
    = BlockChain { chainBlocks :: (OrdList BlockId) }

-- All chains are constructed the same way so comparison
-- including structure is faster.
instance Eq BlockChain where
    BlockChain b1 == BlockChain b2 = strictlyEqOL b1 b2

-- Useful for things like sets and debugging purposes, sorts by blocks
-- in the chain.
instance Ord (BlockChain) where
   (BlockChain lbls1) `compare` (BlockChain lbls2)
       = ASSERT(toList lbls1 /= toList lbls2 || lbls1 `strictlyEqOL` lbls2)
         strictlyOrdOL lbls1 lbls2

instance Outputable (BlockChain) where
    ppr (BlockChain blks) =
        parens (text "Chain:" <+> ppr (fromOL $ blks) )

chainFoldl :: (b -> BlockId -> b) -> b -> BlockChain -> b
chainFoldl f z (BlockChain blocks) = foldl' f z blocks

noDups :: [BlockChain] -> Bool
noDups chains =
    let chainBlocks = concatMap chainToBlocks chains :: [BlockId]
        (_blocks, dups) = removeDups compare chainBlocks
    in if null dups then True
        else pprTrace "Duplicates:" (ppr (map toList dups) $$ text "chains" <+> ppr chains ) False

inFront :: BlockId -> BlockChain -> Bool
inFront bid (BlockChain seq)
  = headOL seq == bid

chainSingleton :: BlockId -> BlockChain
chainSingleton lbl
    = BlockChain (unitOL lbl)

chainFromList :: [BlockId] -> BlockChain
chainFromList = BlockChain . toOL

chainSnoc :: BlockChain -> BlockId -> BlockChain
chainSnoc (BlockChain blks) lbl
  = BlockChain (blks `snocOL` lbl)

chainCons :: BlockId -> BlockChain -> BlockChain
chainCons lbl (BlockChain blks)
  = BlockChain (lbl `consOL` blks)

chainConcat :: BlockChain -> BlockChain -> BlockChain
chainConcat (BlockChain blks1) (BlockChain blks2)
  = BlockChain (blks1 `appOL` blks2)

chainToBlocks :: BlockChain -> [BlockId]
chainToBlocks (BlockChain blks) = fromOL blks

-- | Given the Chain A -> B -> C -> D and we break at C
--   we get the two Chains (A -> B, C -> D) as result.
breakChainAt :: BlockId -> BlockChain
             -> (BlockChain,BlockChain)
breakChainAt bid (BlockChain blks)
    | not (bid == head rblks)
    = panic "Block not in chain"
    | otherwise
    = (BlockChain (toOL lblks),
       BlockChain (toOL rblks))
  where
    (lblks, rblks) = break (\lbl -> lbl == bid) (fromOL blks)

takeR :: Int -> BlockChain -> [BlockId]
takeR n (BlockChain blks) =
    take n . fromOLReverse $ blks

takeL :: Int -> BlockChain -> [BlockId]
takeL n (BlockChain blks) =
    take n . fromOL $ blks

-- Note [Combining neighborhood chains]
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- See also Note [Chain based CFG serialization]
-- We have the chains (A-B-C-D) and (E-F) and an Edge C->E.
--
-- While placing the latter after the former doesn't result in sequential
-- control flow it is still benefical. As block C and E might end
-- up in the same cache line.
--
-- So we place these chains next to each other even if we can't fuse them.
--
--   A -> B -> C -> D
--             v
--             - -> E -> F ...
--
-- A simple heuristic to chose which chains we want to combine:
--   * Process edges in descending priority.
--   * Check if there is a edge near the end of one chain which goes
--     to a block near the start of another edge.
--
-- While we could take into account the space between the two blocks which
-- share an edge this blows up compile times quite a bit. It requires
-- us to find all edges between two chains, check the distance for all edges,
-- rank them based on the distance and and only then we can select two chains
-- to combine. Which would add a lot of complexity for little gain.
--
-- So instead we just rank by the strength of the edge and use the first pair we
-- find.

-- | For a given list of chains and edges try to combine chains with strong
--   edges between them.
combineNeighbourhood  :: [CfgEdge] -- ^ Edges to consider
                      -> [BlockChain] -- ^ Current chains of blocks
                      -> ([BlockChain], Set.Set (BlockId,BlockId))
                      -- ^ Resulting list of block chains, and a set of edges which
                      -- were used to fuse chains and as such no longer need to be
                      -- considered.
combineNeighbourhood edges chains
    = -- pprTraceIt "Neigbours" $
    --   pprTrace "combineNeighbours" (ppr edges) $
      applyEdges edges endFrontier startFrontier (Set.empty)
    where
        --Build maps from chain ends to chains
        endFrontier, startFrontier :: FrontierMap
        endFrontier =
            mapFromList $ concatMap (\chain ->
                                let ends = getEnds chain :: [BlockId]
                                    entry = (ends,chain)
                                in map (\x -> (x,entry)) ends ) chains
        startFrontier =
            mapFromList $ concatMap (\chain ->
                                let front = getFronts chain
                                    entry = (front,chain)
                                in map (\x -> (x,entry)) front) chains
        applyEdges :: [CfgEdge] -> FrontierMap -> FrontierMap -> Set.Set (BlockId, BlockId)
                   -> ([BlockChain], Set.Set (BlockId,BlockId))
        applyEdges [] chainEnds _chainFronts combined =
            (ordNub $ map snd $ mapElems chainEnds, combined)
        applyEdges ((CfgEdge from to _w):edges) chainEnds chainFronts combined
            | Just (c1_e,c1) <- mapLookup from chainEnds
            , Just (c2_f,c2) <- mapLookup to chainFronts
            , c1 /= c2 -- Avoid trying to concat a chain with itself.
            = let newChain = chainConcat c1 c2
                  newChainFrontier = getFronts newChain
                  newChainEnds = getEnds newChain
                  newFronts :: FrontierMap
                  newFronts =
                    let withoutOld =
                            foldl' (\m b -> mapDelete b m :: FrontierMap) chainFronts (c2_f ++ getFronts c1)
                        entry =
                            (newChainFrontier,newChain) --let bound to ensure sharing
                    in foldl' (\m x -> mapInsert x entry m)
                              withoutOld newChainFrontier

                  newEnds =
                    let withoutOld = foldl' (\m b -> mapDelete b m) chainEnds (c1_e ++ getEnds c2)
                        entry = (newChainEnds,newChain) --let bound to ensure sharing
                    in foldl' (\m x -> mapInsert x entry m)
                              withoutOld newChainEnds
              in
                -- pprTrace "ApplyEdges"
                --  (text "before" $$
                --   text "fronts" <+> ppr chainFronts $$
                --   text "ends" <+> ppr chainEnds $$

                --   text "various" $$
                --   text "newChain" <+> ppr newChain $$
                --   text "newChainFrontier" <+> ppr newChainFrontier $$
                --   text "newChainEnds" <+> ppr newChainEnds $$
                --   text "drop" <+> ppr ((c2_f ++ getFronts c1) ++ (c1_e ++ getEnds c2)) $$

                --   text "after" $$
                --   text "fronts" <+> ppr newFronts $$
                --   text "ends" <+> ppr newEnds
                --   )
                 applyEdges edges newEnds newFronts (Set.insert (from,to) combined)
            | otherwise
            = applyEdges edges chainEnds chainFronts combined
         where

        getFronts chain = takeL neighbourOverlapp chain
        getEnds chain = takeR neighbourOverlapp chain

-- In the last stop we combine all chains into a single one.
-- Trying to place chains with strong edges next to each other.
mergeChains :: [CfgEdge] -> [BlockChain]
            -> (BlockChain)
mergeChains edges chains
    = -- pprTrace "combine" (ppr edges) $
      runST $ do
        let addChain m0 chain = do
                ref <- newSTRef chain
                return $ chainFoldl (\m' b -> mapInsert b ref m') m0 chain
        chainMap' <- foldM (\m0 c -> addChain m0 c) mapEmpty chains
        merge edges chainMap'
    where
        -- We keep a map from ALL blocks to their respective chain (sigh)
        -- This is required since when looking at an edge we need to find
        -- the associated chains quickly.
        -- We use a map of STRefs, maintaining a invariant of one STRef per chain.
        -- When merging chains we can update the
        -- STRef of one chain once (instead of writing to the map for each block).
        -- We then overwrite the STRefs for the other chain so there is again only
        -- a single STRef for the combined chain.
        -- The difference in terms of allocations saved is ~0.2% with -O so actually
        -- significant compared to using a regular map.

        merge :: forall s. [CfgEdge] -> LabelMap (STRef s BlockChain) -> ST s BlockChain
        merge [] chains = do
            chains' <- ordNub <$> (mapM readSTRef $ mapElems chains) :: ST s [BlockChain]
            return $ foldl' chainConcat (head chains') (tail chains')
        merge ((CfgEdge from to _):edges) chains
        --   | pprTrace "merge" (ppr (from,to) <> ppr chains) False
        --   = undefined
          | cFrom == cTo
          = merge edges chains
          | otherwise
          = do
            chains' <- mergeComb cFrom cTo
            merge edges chains'
          where
            mergeComb :: STRef s BlockChain -> STRef s BlockChain -> ST s (LabelMap (STRef s BlockChain))
            mergeComb refFrom refTo = do
                cRight <- readSTRef refTo
                chain <- pure chainConcat <*> readSTRef refFrom <*> pure cRight
                writeSTRef refFrom chain
                return $ chainFoldl (\m b -> mapInsert b refFrom m) chains cRight

            cFrom = expectJust "mergeChains:chainMap:from" $ mapLookup from chains
            cTo = expectJust "mergeChains:chainMap:to"   $ mapLookup to   chains


-- See Note [Chain based CFG serialization] for the general idea.
-- This creates and fuses chains at the same time for performance reasons.

-- Try to build chains from a list of edges.
-- Edges must be sorted **descending** by their priority.
-- Returns the constructed chains, along with all edges which
-- are irrelevant past this point, this information doesn't need
-- to be complete - it's only used to speed up the process.
-- An Edge is irrelevant if the ends are part of the same chain.
-- We say these edges are already linked
buildChains :: [CfgEdge] -> [BlockId]
            -> ( LabelMap BlockChain  -- Resulting chains, indexd by end if chain.
               , Set.Set (BlockId, BlockId)) --List of fused edges.
buildChains edges blocks
  = runST $ buildNext setEmpty mapEmpty mapEmpty edges Set.empty
  where
    -- buildNext builds up chains from edges one at a time.

    -- We keep a map from the ends of chains to the chains.
    -- This we we can easily check if an block should be appended to an
    -- existing chain!
    -- We store them using STRefs so we don't have to rebuild the spine of both
    -- maps every time we update a chain.
    buildNext :: forall s. LabelSet
              -> LabelMap (STRef s BlockChain) -- Map from end of chain to chain.
              -> LabelMap (STRef s BlockChain) -- Map from start of chain to chain.
              -> [CfgEdge] -- Edges to check - ordered by decreasing weight
              -> Set.Set (BlockId, BlockId) -- Used edges
              -> ST s   ( LabelMap BlockChain -- Chains by end
                        , Set.Set (BlockId, BlockId) --List of fused edges
                        )
    buildNext placed _chainStarts chainEnds  [] linked = do
        ends' <- sequence $ mapMap readSTRef chainEnds :: ST s (LabelMap BlockChain)
        -- Any remaining blocks have to be made to singleton chains.
        -- They might be combined with other chains later on outside this function.
        let unplaced = filter (\x -> not (setMember x placed)) blocks
            singletons = map (\x -> (x,chainSingleton x)) unplaced :: [(BlockId,BlockChain)]
        return (foldl' (\m (k,v) -> mapInsert k v m) ends' singletons , linked)
    buildNext placed chainStarts chainEnds (edge:todo) linked
        | from == to
        -- We skip self edges
        = buildNext placed chainStarts chainEnds todo (Set.insert (from,to) linked)
        | not (alreadyPlaced from) &&
          not (alreadyPlaced to)
        = do
            --pprTraceM "Edge-Chain:" (ppr edge)
            chain' <- newSTRef $ chainFromList [from,to]
            buildNext
                (setInsert to (setInsert from placed))
                (mapInsert from chain' chainStarts)
                (mapInsert to chain' chainEnds)
                todo
                (Set.insert (from,to) linked)

        | (alreadyPlaced from) &&
          (alreadyPlaced to)
        , Just predChain <- mapLookup from chainEnds
        , Just succChain <- mapLookup to chainStarts
        , predChain /= succChain -- Otherwise we try to create a cycle.
        = do
            -- pprTraceM "Fusing edge" (ppr edge)
            fuseChain predChain succChain

        | (alreadyPlaced from) &&
          (alreadyPlaced to)
        =   --pprTraceM "Skipping:" (ppr edge) >>
            buildNext placed chainStarts chainEnds todo linked

        | otherwise
        = do -- pprTraceM "Finding chain for:" (ppr edge $$
             --         text "placed" <+> ppr placed)
             findChain
      where
        from = edgeFrom edge
        to   = edgeTo   edge
        alreadyPlaced blkId = (setMember blkId placed)

        -- Combine two chains into a single one.
        fuseChain :: STRef s BlockChain -> STRef s BlockChain
                  -> ST s   ( LabelMap BlockChain -- Chains by end
                            , Set.Set (BlockId, BlockId) --List of fused edges
                            )
        fuseChain fromRef toRef = do
            fromChain <- readSTRef fromRef
            toChain <- readSTRef toRef
            let newChain = chainConcat fromChain toChain
            ref <- newSTRef newChain
            let start = head $ takeL 1 newChain
            let end = head $ takeR 1 newChain
            -- chains <- sequence $ mapMap readSTRef chainStarts
            -- pprTraceM "pre-fuse chains:" $ ppr chains
            buildNext
                placed
                (mapInsert start ref $ mapDelete to $ chainStarts)
                (mapInsert end ref $ mapDelete from $ chainEnds)
                todo
                (Set.insert (from,to) linked)


        --Add the block to a existing chain or creates a new chain
        findChain :: ST s   ( LabelMap BlockChain -- Chains by end
                            , Set.Set (BlockId, BlockId) --List of fused edges
                            )
        findChain
          -- We can attach the block to the end of a chain
          | alreadyPlaced from
          , Just predChain <- mapLookup from chainEnds
          = do
            chain <- readSTRef predChain
            let newChain = chainSnoc chain to
            writeSTRef predChain newChain
            let chainEnds' = mapInsert to predChain $ mapDelete from chainEnds
            -- chains <- sequence $ mapMap readSTRef chainStarts
            -- pprTraceM "from chains:" $ ppr chains
            buildNext (setInsert to placed) chainStarts chainEnds' todo (Set.insert (from,to) linked)
          -- We can attack it to the front of a chain
          | alreadyPlaced to
          , Just succChain <- mapLookup to chainStarts
          = do
            chain <- readSTRef succChain
            let newChain = from `chainCons` chain
            writeSTRef succChain newChain
            let chainStarts' = mapInsert from succChain $ mapDelete to chainStarts
            -- chains <- sequence $ mapMap readSTRef chainStarts'
            -- pprTraceM "to chains:" $ ppr chains
            buildNext (setInsert from placed) chainStarts' chainEnds todo (Set.insert (from,to) linked)
          -- The placed end of the edge is part of a chain already and not an end.
          | otherwise
          = do
            let block    = if alreadyPlaced to then from else to
            --pprTraceM "Singleton" $ ppr block
            let newChain = chainSingleton block
            ref <- newSTRef newChain
            buildNext (setInsert block placed) (mapInsert block ref chainStarts)
                      (mapInsert block ref chainEnds) todo (linked)
            where
              alreadyPlaced blkId = (setMember blkId placed)

-- | Place basic blocks based on the given CFG.
-- See Note [Chain based CFG serialization]
sequenceChain :: forall a i. (Instruction i, Outputable i)
              => LabelMap a -- ^ Keys indicate an info table on the block.
              -> CFG -- ^ Control flow graph and some meta data.
              -> [GenBasicBlock i] -- ^ List of basic blocks to be placed.
              -> [GenBasicBlock i] -- ^ Blocks placed in sequence.
sequenceChain _info _weights    [] = []
sequenceChain _info _weights    [x] = [x]
sequenceChain  info weights'     blocks@((BasicBlock entry _):_) =
    let weights :: CFG
        weights = --pprTrace "cfg'" (pprEdgeWeights cfg')
                  cfg'
          where
            (_, globalEdgeWeights) = {-# SCC mkGlobalWeights #-} mkGlobalWeights entry weights'
            cfg' = {-# SCC rewriteEdges #-}
                    mapFoldlWithKey
                        (\cfg from m ->
                            mapFoldlWithKey
                                (\cfg to w -> setEdgeWeight cfg (EdgeWeight w) from to )
                                cfg m )
                        weights'
                        globalEdgeWeights

        directEdges :: [CfgEdge]
        directEdges = sortBy (flip compare) $ catMaybes . map relevantWeight $ (infoEdgeList weights)
          where
            -- Apply modifiers to turn edge frequencies into useable weights
            -- for computing code layout.
            -- See also Note [Layout relevant edge weights]
            relevantWeight :: CfgEdge -> Maybe CfgEdge
            relevantWeight edge@(CfgEdge from to edgeInfo)
                | (EdgeInfo CmmSource { trans_cmmNode = CmmCall {} } _) <- edgeInfo
                -- Ignore edges across calls.
                = Nothing
                | mapMember to info
                , w <- edgeWeight edgeInfo
                -- The payoff is quite small if we jump over an info table
                = Just (CfgEdge from to edgeInfo { edgeWeight = w/8 })
                | (EdgeInfo CmmSource { trans_cmmNode = exitNode } _) <- edgeInfo
                , cantEliminate exitNode
                , w <- edgeWeight edgeInfo
                -- A small penalty to edge types which
                -- we can't optimize away by layout.
                -- w * 0.96875 == w - w/32
                = Just (CfgEdge from to edgeInfo { edgeWeight = w * 0.96875 })
                | otherwise
                = Just edge
                where
                  cantEliminate CmmCondBranch {} = True
                  cantEliminate CmmSwitch {} = True
                  cantEliminate _ = False

        blockMap :: LabelMap (GenBasicBlock i)
        blockMap
            = foldl' (\m blk@(BasicBlock lbl _ins) ->
                        mapInsert lbl blk m)
                     mapEmpty blocks

        (builtChains, builtEdges)
            = {-# SCC "buildChains" #-}
              --pprTraceIt "generatedChains" $
              --pprTrace "blocks" (ppr (mapKeys blockMap)) $
              buildChains directEdges (mapKeys blockMap)

        rankedEdges :: [CfgEdge]
        -- Sort descending by weight, remove fused edges
        rankedEdges =
            filter (\edge -> not (Set.member (edgeFrom edge,edgeTo edge) builtEdges)) $
            directEdges

        (neighbourChains, combined)
            = ASSERT(noDups $ mapElems builtChains)
              {-# SCC "groupNeighbourChains" #-}
            --   pprTraceIt "NeighbourChains" $
              combineNeighbourhood rankedEdges (mapElems builtChains)


        allEdges :: [CfgEdge]
        allEdges = {-# SCC allEdges #-}
                   sortOn (relevantWeight) $ filter (not . deadEdge) $ (infoEdgeList weights)
          where
            deadEdge :: CfgEdge -> Bool
            deadEdge (CfgEdge from to _) = let e = (from,to) in Set.member e combined || Set.member e builtEdges
            relevantWeight :: CfgEdge -> EdgeWeight
            relevantWeight (CfgEdge _ _ edgeInfo)
                | EdgeInfo (CmmSource { trans_cmmNode = CmmCall {}}) _ <- edgeInfo
                -- Penalize edges across calls
                = weight/(64.0)
                | otherwise
                = weight
              where
                -- negate to sort descending
                weight = negate (edgeWeight edgeInfo)

        masterChain =
            {-# SCC "mergeChains" #-}
            -- pprTraceIt "MergedChains" $
            mergeChains allEdges neighbourChains

        --Make sure the first block stays first
        prepedChains
            | inFront entry masterChain
            = [masterChain]
            | (rest,entry) <- breakChainAt entry masterChain
            = [entry,rest]
            | otherwise = pprPanic "Entry point eliminated" $
                            ppr masterChain

        blockList
            = ASSERT(noDups [masterChain])
              (concatMap fromOL $ map chainBlocks prepedChains)

        --chainPlaced = setFromList $ map blockId blockList :: LabelSet
        chainPlaced = setFromList $ blockList :: LabelSet
        unplaced =
            let blocks = mapKeys blockMap
                isPlaced b = setMember (b) chainPlaced
            in filter (\block -> not (isPlaced block)) blocks

        placedBlocks =
            -- We want debug builds to catch this as it's a good indicator for
            -- issues with CFG invariants. But we don't want to blow up production
            -- builds if something slips through.
            ASSERT(null unplaced)
            --pprTraceIt "placedBlocks" $
            -- ++ [] is stil kinda expensive
            if null unplaced then blockList else blockList ++ unplaced
        getBlock bid = expectJust "Block placment" $ mapLookup bid blockMap
    in
        --Assert we placed all blocks given as input
        ASSERT(all (\bid -> mapMember bid blockMap) placedBlocks)
        dropJumps info $ map getBlock placedBlocks

{-# SCC dropJumps #-}
-- | Remove redundant jumps between blocks when we can rely on
-- fall through.
dropJumps :: forall a i. Instruction i => LabelMap a -> [GenBasicBlock i]
          -> [GenBasicBlock i]
dropJumps _    [] = []
dropJumps info ((BasicBlock lbl ins):todo)
    | not . null $ ins --This can happen because of shortcutting
    , [dest] <- jumpDestsOfInstr (last ins)
    , ((BasicBlock nextLbl _) : _) <- todo
    , not (mapMember dest info)
    , nextLbl == dest
    = BasicBlock lbl (init ins) : dropJumps info todo
    | otherwise
    = BasicBlock lbl ins : dropJumps info todo


-- -----------------------------------------------------------------------------
-- Sequencing the basic blocks

-- Cmm BasicBlocks are self-contained entities: they always end in a
-- jump, either non-local or to another basic block in the same proc.
-- In this phase, we attempt to place the basic blocks in a sequence
-- such that as many of the local jumps as possible turn into
-- fallthroughs.

sequenceTop
    :: (Instruction instr, Outputable instr)
    => DynFlags -- Determine which layout algo to use
    -> NcgImpl statics instr jumpDest
    -> Maybe CFG -- ^ CFG if we have one.
    -> NatCmmDecl statics instr -- ^ Function to serialize
    -> NatCmmDecl statics instr

sequenceTop _     _       _           top@(CmmData _ _) = top
sequenceTop dflags ncgImpl edgeWeights
            (CmmProc info lbl live (ListGraph blocks))
  | (gopt Opt_CfgBlocklayout dflags) && backendMaintainsCfg dflags
  --Use chain based algorithm
  , Just cfg <- edgeWeights
  = CmmProc info lbl live ( ListGraph $ ncgMakeFarBranches ncgImpl info $
                            {-# SCC layoutBlocks #-}
                            sequenceChain info cfg blocks )
  | otherwise
  --Use old algorithm
  = let cfg = if dontUseCfg then Nothing else edgeWeights
    in  CmmProc info lbl live ( ListGraph $ ncgMakeFarBranches ncgImpl info $
                                {-# SCC layoutBlocks #-}
                                sequenceBlocks cfg info blocks)
  where
    dontUseCfg = gopt Opt_WeightlessBlocklayout dflags ||
                 (not $ backendMaintainsCfg dflags)

-- The old algorithm:
-- It is very simple (and stupid): We make a graph out of
-- the blocks where there is an edge from one block to another iff the
-- first block ends by jumping to the second.  Then we topologically
-- sort this graph.  Then traverse the list: for each block, we first
-- output the block, then if it has an out edge, we move the
-- destination of the out edge to the front of the list, and continue.

-- FYI, the classic layout for basic blocks uses postorder DFS; this
-- algorithm is implemented in Hoopl.

sequenceBlocks :: Instruction inst => Maybe CFG -> LabelMap a
               -> [GenBasicBlock inst] -> [GenBasicBlock inst]
sequenceBlocks _edgeWeight _ [] = []
sequenceBlocks edgeWeights infos (entry:blocks) =
    let entryNode = mkNode edgeWeights entry
        bodyNodes = reverse
                    (flattenSCCs (sccBlocks edgeWeights blocks))
    in dropJumps infos . seqBlocks infos $ ( entryNode : bodyNodes)
  -- the first block is the entry point ==> it must remain at the start.

sccBlocks
        :: Instruction instr
        => Maybe CFG -> [NatBasicBlock instr]
        -> [SCC (Node BlockId (NatBasicBlock instr))]
sccBlocks edgeWeights blocks =
    stronglyConnCompFromEdgedVerticesUniqR
        (map (mkNode edgeWeights) blocks)

mkNode :: (Instruction t)
       => Maybe CFG -> GenBasicBlock t
       -> Node BlockId (GenBasicBlock t)
mkNode edgeWeights block@(BasicBlock id instrs) =
    DigraphNode block id outEdges
  where
    outEdges :: [BlockId]
    outEdges
      --Select the heaviest successor, ignore weights <= zero
      = successor
      where
        successor
          | Just successors <- fmap (`getSuccEdgesSorted` id)
                                    edgeWeights -- :: Maybe [(Label, EdgeInfo)]
          = case successors of
            [] -> []
            ((target,info):_)
              | length successors > 2 || edgeWeight info <= 0 -> []
              | otherwise -> [target]
          | otherwise
          = case jumpDestsOfInstr (last instrs) of
                [one] -> [one]
                _many -> []


seqBlocks :: LabelMap i -> [Node BlockId (GenBasicBlock t1)]
                        -> [GenBasicBlock t1]
seqBlocks infos blocks = placeNext pullable0 todo0
  where
    -- pullable: Blocks that are not yet placed
    -- todo:     Original order of blocks, to be followed if we have no good
    --           reason not to;
    --           may include blocks that have already been placed, but then
    --           these are not in pullable
    pullable0 = listToUFM [ (i,(b,n)) | DigraphNode b i n <- blocks ]
    todo0     = map node_key blocks

    placeNext _ [] = []
    placeNext pullable (i:rest)
        | Just (block, pullable') <- lookupDeleteUFM pullable i
        = place pullable' rest block
        | otherwise
        -- We already placed this block, so ignore
        = placeNext pullable rest

    place pullable todo (block,[])
                          = block : placeNext pullable todo
    place pullable todo (block@(BasicBlock id instrs),[next])
        | mapMember next infos
        = block : placeNext pullable todo
        | Just (nextBlock, pullable') <- lookupDeleteUFM pullable next
        = BasicBlock id instrs : place pullable' todo nextBlock
        | otherwise
        = block : placeNext pullable todo
    place _ _ (_,tooManyNextNodes)
        = pprPanic "seqBlocks" (ppr tooManyNextNodes)


lookupDeleteUFM :: Uniquable key => UniqFM elt -> key
                -> Maybe (elt, UniqFM elt)
lookupDeleteUFM m k = do -- Maybe monad
    v <- lookupUFM m k
    return (v, delFromUFM m k)

