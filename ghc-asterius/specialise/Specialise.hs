{-
(c) The GRASP/AQUA Project, Glasgow University, 1993-1998

\section[Specialise]{Stamping out overloading, and (optionally) polymorphism}
-}

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE ViewPatterns #-}
module Specialise ( specProgram, specUnfolding ) where

#include "HsVersions.h"

import GhcPrelude

import Id
import TcType hiding( substTy )
import Type   hiding( substTy, extendTvSubstList )
import Predicate
import Module( Module, HasModule(..) )
import Coercion( Coercion )
import CoreMonad
import qualified CoreSubst as Core
import CoreUnfold
import Var              ( isLocalVar )
import VarSet
import VarEnv
import CoreSyn
import Rules
import CoreOpt          ( collectBindersPushingCo )
import CoreUtils        ( exprIsTrivial, mkCast, exprType, getIdFromTrivialExpr_maybe )
import CoreFVs
import CoreArity        ( etaExpandToJoinPointRule )
import UniqSupply
import Name
import MkId             ( voidArgId, voidPrimId )
import TysPrim            ( voidPrimTy )
import Maybes           ( mapMaybe, maybeToList, isJust )
import MonadUtils       ( foldlM )
import BasicTypes
import HscTypes
import Bag
import DynFlags
import Util
import Outputable
import FastString
import State
import UniqDFM
import TyCoRep (TyCoBinder (..))

import Control.Monad
import qualified Control.Monad.Fail as MonadFail

{-
************************************************************************
*                                                                      *
\subsection[notes-Specialise]{Implementation notes [SLPJ, Aug 18 1993]}
*                                                                      *
************************************************************************

These notes describe how we implement specialisation to eliminate
overloading.

The specialisation pass works on Core
syntax, complete with all the explicit dictionary application,
abstraction and construction as added by the type checker.  The
existing type checker remains largely as it is.

One important thought: the {\em types} passed to an overloaded
function, and the {\em dictionaries} passed are mutually redundant.
If the same function is applied to the same type(s) then it is sure to
be applied to the same dictionary(s)---or rather to the same {\em
values}.  (The arguments might look different but they will evaluate
to the same value.)

Second important thought: we know that we can make progress by
treating dictionary arguments as static and worth specialising on.  So
we can do without binding-time analysis, and instead specialise on
dictionary arguments and no others.

The basic idea
~~~~~~~~~~~~~~
Suppose we have

        let f = <f_rhs>
        in <body>

and suppose f is overloaded.

STEP 1: CALL-INSTANCE COLLECTION

We traverse <body>, accumulating all applications of f to types and
dictionaries.

(Might there be partial applications, to just some of its types and
dictionaries?  In principle yes, but in practice the type checker only
builds applications of f to all its types and dictionaries, so partial
applications could only arise as a result of transformation, and even
then I think it's unlikely.  In any case, we simply don't accumulate such
partial applications.)


STEP 2: EQUIVALENCES

So now we have a collection of calls to f:
        f t1 t2 d1 d2
        f t3 t4 d3 d4
        ...
Notice that f may take several type arguments.  To avoid ambiguity, we
say that f is called at type t1/t2 and t3/t4.

We take equivalence classes using equality of the *types* (ignoring
the dictionary args, which as mentioned previously are redundant).

STEP 3: SPECIALISATION

For each equivalence class, choose a representative (f t1 t2 d1 d2),
and create a local instance of f, defined thus:

        f@t1/t2 = <f_rhs> t1 t2 d1 d2

f_rhs presumably has some big lambdas and dictionary lambdas, so lots
of simplification will now result.  However we don't actually *do* that
simplification.  Rather, we leave it for the simplifier to do.  If we
*did* do it, though, we'd get more call instances from the specialised
RHS.  We can work out what they are by instantiating the call-instance
set from f's RHS with the types t1, t2.

Add this new id to f's IdInfo, to record that f has a specialised version.

Before doing any of this, check that f's IdInfo doesn't already
tell us about an existing instance of f at the required type/s.
(This might happen if specialisation was applied more than once, or
it might arise from user SPECIALIZE pragmas.)

Recursion
~~~~~~~~~
Wait a minute!  What if f is recursive?  Then we can't just plug in
its right-hand side, can we?

But it's ok.  The type checker *always* creates non-recursive definitions
for overloaded recursive functions.  For example:

        f x = f (x+x)           -- Yes I know its silly

becomes

        f a (d::Num a) = let p = +.sel a d
                         in
                         letrec fl (y::a) = fl (p y y)
                         in
                         fl

We still have recursion for non-overloaded functions which we
specialise, but the recursive call should get specialised to the
same recursive version.


Polymorphism 1
~~~~~~~~~~~~~~

All this is crystal clear when the function is applied to *constant
types*; that is, types which have no type variables inside.  But what if
it is applied to non-constant types?  Suppose we find a call of f at type
t1/t2.  There are two possibilities:

(a) The free type variables of t1, t2 are in scope at the definition point
of f.  In this case there's no problem, we proceed just as before.  A common
example is as follows.  Here's the Haskell:

        g y = let f x = x+x
              in f y + f y

After typechecking we have

        g a (d::Num a) (y::a) = let f b (d'::Num b) (x::b) = +.sel b d' x x
                                in +.sel a d (f a d y) (f a d y)

Notice that the call to f is at type type "a"; a non-constant type.
Both calls to f are at the same type, so we can specialise to give:

        g a (d::Num a) (y::a) = let f@a (x::a) = +.sel a d x x
                                in +.sel a d (f@a y) (f@a y)


(b) The other case is when the type variables in the instance types
are *not* in scope at the definition point of f.  The example we are
working with above is a good case.  There are two instances of (+.sel a d),
but "a" is not in scope at the definition of +.sel.  Can we do anything?
Yes, we can "common them up", a sort of limited common sub-expression deal.
This would give:

        g a (d::Num a) (y::a) = let +.sel@a = +.sel a d
                                    f@a (x::a) = +.sel@a x x
                                in +.sel@a (f@a y) (f@a y)

This can save work, and can't be spotted by the type checker, because
the two instances of +.sel weren't originally at the same type.

Further notes on (b)

* There are quite a few variations here.  For example, the defn of
  +.sel could be floated ouside the \y, to attempt to gain laziness.
  It certainly mustn't be floated outside the \d because the d has to
  be in scope too.

* We don't want to inline f_rhs in this case, because
that will duplicate code.  Just commoning up the call is the point.

* Nothing gets added to +.sel's IdInfo.

* Don't bother unless the equivalence class has more than one item!

Not clear whether this is all worth it.  It is of course OK to
simply discard call-instances when passing a big lambda.

Polymorphism 2 -- Overloading
~~~~~~~~~~~~~~
Consider a function whose most general type is

        f :: forall a b. Ord a => [a] -> b -> b

There is really no point in making a version of g at Int/Int and another
at Int/Bool, because it's only instantiating the type variable "a" which
buys us any efficiency. Since g is completely polymorphic in b there
ain't much point in making separate versions of g for the different
b types.

That suggests that we should identify which of g's type variables
are constrained (like "a") and which are unconstrained (like "b").
Then when taking equivalence classes in STEP 2, we ignore the type args
corresponding to unconstrained type variable.  In STEP 3 we make
polymorphic versions.  Thus:

        f@t1/ = /\b -> <f_rhs> t1 b d1 d2

We do this.


Dictionary floating
~~~~~~~~~~~~~~~~~~~
Consider this

        f a (d::Num a) = let g = ...
                         in
                         ...(let d1::Ord a = Num.Ord.sel a d in g a d1)...

Here, g is only called at one type, but the dictionary isn't in scope at the
definition point for g.  Usually the type checker would build a
definition for d1 which enclosed g, but the transformation system
might have moved d1's defn inward.  Solution: float dictionary bindings
outwards along with call instances.

Consider

        f x = let g p q = p==q
                  h r s = (r+s, g r s)
              in
              h x x


Before specialisation, leaving out type abstractions we have

        f df x = let g :: Eq a => a -> a -> Bool
                     g dg p q = == dg p q
                     h :: Num a => a -> a -> (a, Bool)
                     h dh r s = let deq = eqFromNum dh
                                in (+ dh r s, g deq r s)
              in
              h df x x

After specialising h we get a specialised version of h, like this:

                    h' r s = let deq = eqFromNum df
                             in (+ df r s, g deq r s)

But we can't naively make an instance for g from this, because deq is not in scope
at the defn of g.  Instead, we have to float out the (new) defn of deq
to widen its scope.  Notice that this floating can't be done in advance -- it only
shows up when specialisation is done.

User SPECIALIZE pragmas
~~~~~~~~~~~~~~~~~~~~~~~
Specialisation pragmas can be digested by the type checker, and implemented
by adding extra definitions along with that of f, in the same way as before

        f@t1/t2 = <f_rhs> t1 t2 d1 d2

Indeed the pragmas *have* to be dealt with by the type checker, because
only it knows how to build the dictionaries d1 and d2!  For example

        g :: Ord a => [a] -> [a]
        {-# SPECIALIZE f :: [Tree Int] -> [Tree Int] #-}

Here, the specialised version of g is an application of g's rhs to the
Ord dictionary for (Tree Int), which only the type checker can conjure
up.  There might not even *be* one, if (Tree Int) is not an instance of
Ord!  (All the other specialision has suitable dictionaries to hand
from actual calls.)

Problem.  The type checker doesn't have to hand a convenient <f_rhs>, because
it is buried in a complex (as-yet-un-desugared) binding group.
Maybe we should say

        f@t1/t2 = f* t1 t2 d1 d2

where f* is the Id f with an IdInfo which says "inline me regardless!".
Indeed all the specialisation could be done in this way.
That in turn means that the simplifier has to be prepared to inline absolutely
any in-scope let-bound thing.


Again, the pragma should permit polymorphism in unconstrained variables:

        h :: Ord a => [a] -> b -> b
        {-# SPECIALIZE h :: [Int] -> b -> b #-}

We *insist* that all overloaded type variables are specialised to ground types,
(and hence there can be no context inside a SPECIALIZE pragma).
We *permit* unconstrained type variables to be specialised to
        - a ground type
        - or left as a polymorphic type variable
but nothing in between.  So

        {-# SPECIALIZE h :: [Int] -> [c] -> [c] #-}

is *illegal*.  (It can be handled, but it adds complication, and gains the
programmer nothing.)


SPECIALISING INSTANCE DECLARATIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider

        instance Foo a => Foo [a] where
                ...
        {-# SPECIALIZE instance Foo [Int] #-}

The original instance decl creates a dictionary-function
definition:

        dfun.Foo.List :: forall a. Foo a -> Foo [a]

The SPECIALIZE pragma just makes a specialised copy, just as for
ordinary function definitions:

        dfun.Foo.List@Int :: Foo [Int]
        dfun.Foo.List@Int = dfun.Foo.List Int dFooInt

The information about what instance of the dfun exist gets added to
the dfun's IdInfo in the same way as a user-defined function too.


Automatic instance decl specialisation?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Can instance decls be specialised automatically?  It's tricky.
We could collect call-instance information for each dfun, but
then when we specialised their bodies we'd get new call-instances
for ordinary functions; and when we specialised their bodies, we might get
new call-instances of the dfuns, and so on.  This all arises because of
the unrestricted mutual recursion between instance decls and value decls.

Still, there's no actual problem; it just means that we may not do all
the specialisation we could theoretically do.

Furthermore, instance decls are usually exported and used non-locally,
so we'll want to compile enough to get those specialisations done.

Lastly, there's no such thing as a local instance decl, so we can
survive solely by spitting out *usage* information, and then reading that
back in as a pragma when next compiling the file.  So for now,
we only specialise instance decls in response to pragmas.


SPITTING OUT USAGE INFORMATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To spit out usage information we need to traverse the code collecting
call-instance information for all imported (non-prelude?) functions
and data types. Then we equivalence-class it and spit it out.

This is done at the top-level when all the call instances which escape
must be for imported functions and data types.

*** Not currently done ***


Partial specialisation by pragmas
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
What about partial specialisation:

        k :: (Ord a, Eq b) => [a] -> b -> b -> [a]
        {-# SPECIALIZE k :: Eq b => [Int] -> b -> b -> [a] #-}

or even

        {-# SPECIALIZE k :: Eq b => [Int] -> [b] -> [b] -> [a] #-}

Seems quite reasonable.  Similar things could be done with instance decls:

        instance (Foo a, Foo b) => Foo (a,b) where
                ...
        {-# SPECIALIZE instance Foo a => Foo (a,Int) #-}
        {-# SPECIALIZE instance Foo b => Foo (Int,b) #-}

Ho hum.  Things are complex enough without this.  I pass.


Requirements for the simplifier
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The simplifier has to be able to take advantage of the specialisation.

* When the simplifier finds an application of a polymorphic f, it looks in
f's IdInfo in case there is a suitable instance to call instead.  This converts

        f t1 t2 d1 d2   ===>   f_t1_t2

Note that the dictionaries get eaten up too!

* Dictionary selection operations on constant dictionaries must be
  short-circuited:

        +.sel Int d     ===>  +Int

The obvious way to do this is in the same way as other specialised
calls: +.sel has inside it some IdInfo which tells that if it's applied
to the type Int then it should eat a dictionary and transform to +Int.

In short, dictionary selectors need IdInfo inside them for constant
methods.

* Exactly the same applies if a superclass dictionary is being
  extracted:

        Eq.sel Int d   ===>   dEqInt

* Something similar applies to dictionary construction too.  Suppose
dfun.Eq.List is the function taking a dictionary for (Eq a) to
one for (Eq [a]).  Then we want

        dfun.Eq.List Int d      ===> dEq.List_Int

Where does the Eq [Int] dictionary come from?  It is built in
response to a SPECIALIZE pragma on the Eq [a] instance decl.

In short, dfun Ids need IdInfo with a specialisation for each
constant instance of their instance declaration.

All this uses a single mechanism: the SpecEnv inside an Id


What does the specialisation IdInfo look like?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The SpecEnv of an Id maps a list of types (the template) to an expression

        [Type]  |->  Expr

For example, if f has this RuleInfo:

        [Int, a]  ->  \d:Ord Int. f' a

it means that we can replace the call

        f Int t  ===>  (\d. f' t)

This chucks one dictionary away and proceeds with the
specialised version of f, namely f'.


What can't be done this way?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
There is no way, post-typechecker, to get a dictionary for (say)
Eq a from a dictionary for Eq [a].  So if we find

        ==.sel [t] d

we can't transform to

        eqList (==.sel t d')

where
        eqList :: (a->a->Bool) -> [a] -> [a] -> Bool

Of course, we currently have no way to automatically derive
eqList, nor to connect it to the Eq [a] instance decl, but you
can imagine that it might somehow be possible.  Taking advantage
of this is permanently ruled out.

Still, this is no great hardship, because we intend to eliminate
overloading altogether anyway!

A note about non-tyvar dictionaries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Some Ids have types like

        forall a,b,c. Eq a -> Ord [a] -> tau

This seems curious at first, because we usually only have dictionary
args whose types are of the form (C a) where a is a type variable.
But this doesn't hold for the functions arising from instance decls,
which sometimes get arguments with types of form (C (T a)) for some
type constructor T.

Should we specialise wrt this compound-type dictionary?  We used to say
"no", saying:
        "This is a heuristic judgement, as indeed is the fact that we
        specialise wrt only dictionaries.  We choose *not* to specialise
        wrt compound dictionaries because at the moment the only place
        they show up is in instance decls, where they are simply plugged
        into a returned dictionary.  So nothing is gained by specialising
        wrt them."

But it is simpler and more uniform to specialise wrt these dicts too;
and in future GHC is likely to support full fledged type signatures
like
        f :: Eq [(a,b)] => ...


************************************************************************
*                                                                      *
\subsubsection{The new specialiser}
*                                                                      *
************************************************************************

Our basic game plan is this.  For let(rec) bound function
        f :: (C a, D c) => (a,b,c,d) -> Bool

* Find any specialised calls of f, (f ts ds), where
  ts are the type arguments t1 .. t4, and
  ds are the dictionary arguments d1 .. d2.

* Add a new definition for f1 (say):

        f1 = /\ b d -> (..body of f..) t1 b t3 d d1 d2

  Note that we abstract over the unconstrained type arguments.

* Add the mapping

        [t1,b,t3,d]  |->  \d1 d2 -> f1 b d

  to the specialisations of f.  This will be used by the
  simplifier to replace calls
                (f t1 t2 t3 t4) da db
  by
                (\d1 d1 -> f1 t2 t4) da db

  All the stuff about how many dictionaries to discard, and what types
  to apply the specialised function to, are handled by the fact that the
  SpecEnv contains a template for the result of the specialisation.

We don't build *partial* specialisations for f.  For example:

  f :: Eq a => a -> a -> Bool
  {-# SPECIALISE f :: (Eq b, Eq c) => (b,c) -> (b,c) -> Bool #-}

Here, little is gained by making a specialised copy of f.
There's a distinct danger that the specialised version would
first build a dictionary for (Eq b, Eq c), and then select the (==)
method from it!  Even if it didn't, not a great deal is saved.

We do, however, generate polymorphic, but not overloaded, specialisations:

  f :: Eq a => [a] -> b -> b -> b
  ... SPECIALISE f :: [Int] -> b -> b -> b ...

Hence, the invariant is this:

        *** no specialised version is overloaded ***


************************************************************************
*                                                                      *
\subsubsection{The exported function}
*                                                                      *
************************************************************************
-}

-- | Specialise calls to type-class overloaded functions occuring in a program.
specProgram :: ModGuts -> CoreM ModGuts
specProgram guts@(ModGuts { mg_module = this_mod
                          , mg_rules = local_rules
                          , mg_binds = binds })
  = do { dflags <- getDynFlags

             -- Specialise the bindings of this module
       ; (binds', uds) <- runSpecM dflags this_mod (go binds)

       ; (spec_rules, spec_binds) <- specImports dflags this_mod top_env
                                                 local_rules uds

       ; return (guts { mg_binds = spec_binds ++ binds'
                      , mg_rules = spec_rules ++ local_rules }) }
  where
        -- We need to start with a Subst that knows all the things
        -- that are in scope, so that the substitution engine doesn't
        -- accidentally re-use a unique that's already in use
        -- Easiest thing is to do it all at once, as if all the top-level
        -- decls were mutually recursive
    top_env = SE { se_subst = Core.mkEmptySubst $ mkInScopeSet $ mkVarSet $
                              bindersOfBinds binds
                 , se_interesting = emptyVarSet }

    go []           = return ([], emptyUDs)
    go (bind:binds) = do (binds', uds) <- go binds
                         (bind', uds') <- specBind top_env bind uds
                         return (bind' ++ binds', uds')

{-
Note [Wrap bindings returned by specImports]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'specImports' returns a set of specialized bindings. However, these are lacking
necessary floated dictionary bindings, which are returned by
UsageDetails(ud_binds). These dictionaries need to be brought into scope with
'wrapDictBinds' before the bindings returned by 'specImports' can be used. See,
for instance, the 'specImports' call in 'specProgram'.


Note [Disabling cross-module specialisation]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Since GHC 7.10 we have performed specialisation of INLINABLE bindings living
in modules outside of the current module. This can sometimes uncover user code
which explodes in size when aggressively optimized. The
-fno-cross-module-specialise option was introduced to allow users to being
bitten by such instances to revert to the pre-7.10 behavior.

See #10491
-}


{- *********************************************************************
*                                                                      *
                   Specialising imported functions
*                                                                      *
********************************************************************* -}

specImports :: DynFlags -> Module -> SpecEnv
            -> [CoreRule]
            -> UsageDetails
            -> CoreM ([CoreRule], [CoreBind])
specImports dflags this_mod top_env local_rules
            (MkUD { ud_binds = dict_binds, ud_calls = calls })
  | not $ gopt Opt_CrossModuleSpecialise dflags
    -- See Note [Disabling cross-module specialisation]
  = return ([], wrapDictBinds dict_binds [])

  | otherwise
  = do { hpt_rules <- getRuleBase
       ; let rule_base = extendRuleBaseList hpt_rules local_rules

       ; (spec_rules, spec_binds) <- spec_imports dflags this_mod top_env
                                                  [] rule_base
                                                  dict_binds calls

             -- Don't forget to wrap the specialized bindings with
             -- bindings for the needed dictionaries.
             -- See Note [Wrap bindings returned by specImports]
             -- and Note [Glom the bindings if imported functions are specialised]
       ; let final_binds
               | null spec_binds = wrapDictBinds dict_binds []
               | otherwise       = [Rec $ flattenBinds $
                                    wrapDictBinds dict_binds spec_binds]

       ; return (spec_rules, final_binds)
    }

-- | Specialise a set of calls to imported bindings
spec_imports :: DynFlags
             -> Module
             -> SpecEnv          -- Passed in so that all top-level Ids are in scope
             -> [Id]             -- Stack of imported functions being specialised
                                 -- See Note [specImport call stack]
             -> RuleBase         -- Rules from this module and the home package
                                 -- (but not external packages, which can change)
             -> Bag DictBind     -- Dict bindings, used /only/ for filterCalls
                                 -- See Note [Avoiding loops in specImports]
             -> CallDetails      -- Calls for imported things
             -> CoreM ( [CoreRule]   -- New rules
                      , [CoreBind] ) -- Specialised bindings
spec_imports dflags this_mod top_env
             callers rule_base dict_binds calls
  = do { let import_calls = dVarEnvElts calls
       -- ; debugTraceMsg (text "specImports {" <+>
       --                  vcat [ text "calls:" <+> ppr import_calls
       --                       , text "dict_binds:" <+> ppr dict_binds ])
       ; (rules, spec_binds) <- go rule_base import_calls
       -- ; debugTraceMsg (text "End specImports }" <+> ppr import_calls)

       ; return (rules, spec_binds) }
  where
    go :: RuleBase -> [CallInfoSet] -> CoreM ([CoreRule], [CoreBind])
    go _ [] = return ([], [])
    go rb (cis : other_calls)
      = do { -- debugTraceMsg (text "specImport {" <+> ppr cis)
           ; (rules1, spec_binds1) <- spec_import dflags this_mod top_env
                                                  callers rb dict_binds cis
           -- ; debugTraceMsg (text "specImport }" <+> ppr cis)

           ; (rules2, spec_binds2) <- go (extendRuleBaseList rb rules1) other_calls
           ; return (rules1 ++ rules2, spec_binds1 ++ spec_binds2) }

spec_import :: DynFlags
            -> Module
            -> SpecEnv               -- Passed in so that all top-level Ids are in scope
            -> [Id]                  -- Stack of imported functions being specialised
                                     -- See Note [specImport call stack]
            -> RuleBase              -- Rules from this module
            -> Bag DictBind          -- Dict bindings, used /only/ for filterCalls
                                     -- See Note [Avoiding loops in specImports]
            -> CallInfoSet           -- Imported function and calls for it
            -> CoreM ( [CoreRule]    -- New rules
                     , [CoreBind] )  -- Specialised bindings
spec_import dflags this_mod top_env callers
            rb dict_binds cis@(CIS fn _)
  | isIn "specImport" fn callers
  = return ([], [])     -- No warning.  This actually happens all the time
                        -- when specialising a recursive function, because
                        -- the RHS of the specialised function contains a recursive
                        -- call to the original function

  | null good_calls
  = do { -- debugTraceMsg (text "specImport:no valid calls")
       ; return ([], []) }

  | wantSpecImport dflags unfolding
  , Just rhs <- maybeUnfoldingTemplate unfolding
  = do {     -- Get rules from the external package state
             -- We keep doing this in case we "page-fault in"
             -- more rules as we go along
       ; hsc_env <- getHscEnv
       ; eps <- liftIO $ hscEPS hsc_env
       ; vis_orphs <- getVisibleOrphanMods
       ; let full_rb = unionRuleBase rb (eps_rule_base eps)
             rules_for_fn = getRules (RuleEnv full_rb vis_orphs) fn

       ; (rules1, spec_pairs, MkUD { ud_binds = dict_binds1, ud_calls = new_calls })
             <- do { -- debugTraceMsg (text "specImport1" <+> vcat [ppr fn, ppr good_calls, ppr rhs])
                   ; runSpecM dflags this_mod $
                     specCalls (Just this_mod) top_env rules_for_fn good_calls fn rhs }
       ; let spec_binds1 = [NonRec b r | (b,r) <- spec_pairs]
             -- After the rules kick in we may get recursion, but
             -- we rely on a global GlomBinds to sort that out later
             -- See Note [Glom the bindings if imported functions are specialised]

              -- Now specialise any cascaded calls
       -- ; debugTraceMsg (text "specImport 2" <+> (ppr fn $$ ppr rules1 $$ ppr spec_binds1))
       ; (rules2, spec_binds2) <- spec_imports dflags this_mod top_env
                                               (fn:callers)
                                               (extendRuleBaseList rb rules1)
                                               (dict_binds `unionBags` dict_binds1)
                                               new_calls

       ; let final_binds = wrapDictBinds dict_binds1 $
                           spec_binds2 ++ spec_binds1

       ; return (rules2 ++ rules1, final_binds) }

  | otherwise
  = do { tryWarnMissingSpecs dflags callers fn good_calls
       ; return ([], [])}

  where
    unfolding = realIdUnfolding fn   -- We want to see the unfolding even for loop breakers
    good_calls = filterCalls cis dict_binds
       -- SUPER IMPORTANT!  Drop calls that (directly or indirectly) refer to fn
       -- See Note [Avoiding loops in specImports]

-- | Returns whether or not to show a missed-spec warning.
-- If -Wall-missed-specializations is on, show the warning.
-- Otherwise, if -Wmissed-specializations is on, only show a warning
-- if there is at least one imported function being specialized,
-- and if all imported functions are marked with an inline pragma
-- Use the most specific warning as the reason.
tryWarnMissingSpecs :: DynFlags -> [Id] -> Id -> [CallInfo] -> CoreM ()
-- See Note [Warning about missed specialisations]
tryWarnMissingSpecs dflags callers fn calls_for_fn
  | wopt Opt_WarnMissedSpecs dflags
    && not (null callers)
    && allCallersInlined                  = doWarn $ Reason Opt_WarnMissedSpecs
  | wopt Opt_WarnAllMissedSpecs dflags    = doWarn $ Reason Opt_WarnAllMissedSpecs
  | otherwise                             = return ()
  where
    allCallersInlined = all (isAnyInlinePragma . idInlinePragma) callers
    doWarn reason =
      warnMsg reason
        (vcat [ hang (text ("Could not specialise imported function") <+> quotes (ppr fn))
                2 (vcat [ text "when specialising" <+> quotes (ppr caller)
                        | caller <- callers])
          , whenPprDebug (text "calls:" <+> vcat (map (pprCallInfo fn) calls_for_fn))
          , text "Probable fix: add INLINABLE pragma on" <+> quotes (ppr fn) ])

wantSpecImport :: DynFlags -> Unfolding -> Bool
-- See Note [Specialise imported INLINABLE things]
wantSpecImport dflags unf
 = case unf of
     NoUnfolding      -> False
     BootUnfolding    -> False
     OtherCon {}      -> False
     DFunUnfolding {} -> True
     CoreUnfolding { uf_src = src, uf_guidance = _guidance }
       | gopt Opt_SpecialiseAggressively dflags -> True
       | isStableSource src -> True
               -- Specialise even INLINE things; it hasn't inlined yet,
               -- so perhaps it never will.  Moreover it may have calls
               -- inside it that we want to specialise
       | otherwise -> False    -- Stable, not INLINE, hence INLINABLE

{- Note [Avoiding loops in specImports]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We must take great care when specialising instance declarations
(functions like $fOrdList) lest we accidentally build a recursive
dictionary. See Note [Avoiding loops].

The basic strategy of Note [Avoiding loops] is to use filterCalls
to discard loopy specialisations.  But to do that we must ensure
that the in-scope dict-binds (passed to filterCalls) contains
all the needed dictionary bindings.  In particular, in the recursive
call to spec_imorpts in spec_import, we must include the dict-binds
from the parent.  Lacking this caused #17151, a really nasty bug.

Here is what happened.
* Class struture:
    Source is a superclass of Mut
    Index is a superclass of Source

* We started with these dict binds
    dSource = $fSourcePix @Int $fIndexInt
    dIndex  = sc_sel dSource
    dMut    = $fMutPix @Int dIndex
  and these calls to specialise
    $fMutPix @Int dIndex
    $fSourcePix @Int $fIndexInt

* We specialised the call ($fMutPix @Int dIndex)
  ==> new call ($fSourcePix @Int dIndex)
      (because Source is a superclass of Mut)

* We specialised ($fSourcePix @Int dIndex)
  ==> produces specialised dict $s$fSourcePix,
      a record with dIndex as a field
      plus RULE forall d. ($fSourcePix @Int d) = $s$fSourcePix
  *** This is the bogus step ***

* Now we decide not to specialise the call
    $fSourcePix @Int $fIndexInt
  because we alredy have a RULE that matches it

* Finally the simplifer rewrites
    dSource = $fSourcePix @Int $fIndexInt
    ==>  dSource = $s$fSourcePix

Disaster. Now we have

Rewrite dSource's RHS to $s$fSourcePix   Disaster
    dSource = $s$fSourcePix
    dIndex  = sc_sel dSource
    $s$fSourcePix = MkSource dIndex ...

Solution: filterCalls should have stopped the bogus step,
by seeing that dIndex transitively uses $fSourcePix. But
it can only do that if it sees all the dict_binds.  Wow.

--------------
Here's another example (#13429).  Suppose we have
  class Monoid v => C v a where ...

We start with a call
   f @ [Integer] @ Integer $fC[]Integer

Specialising call to 'f' gives dict bindings
   $dMonoid_1 :: Monoid [Integer]
   $dMonoid_1 = M.$p1C @ [Integer] $fC[]Integer

   $dC_1 :: C [Integer] (Node [Integer] Integer)
   $dC_1 = M.$fCvNode @ [Integer] $dMonoid_1

...plus a recursive call to
   f @ [Integer] @ (Node [Integer] Integer) $dC_1

Specialising that call gives
   $dMonoid_2  :: Monoid [Integer]
   $dMonoid_2  = M.$p1C @ [Integer] $dC_1

   $dC_2 :: C [Integer] (Node [Integer] Integer)
   $dC_2 = M.$fCvNode @ [Integer] $dMonoid_2

Now we have two calls to the imported function
  M.$fCvNode :: Monoid v => C v a
  M.$fCvNode @v @a m = C m some_fun

But we must /not/ use the call (M.$fCvNode @ [Integer] $dMonoid_2)
for specialisation, else we get:

  $dC_1 = M.$fCvNode @ [Integer] $dMonoid_1
  $dMonoid_2 = M.$p1C @ [Integer] $dC_1
  $s$fCvNode = C $dMonoid_2 ...
    RULE M.$fCvNode [Integer] _ _ = $s$fCvNode

Now use the rule to rewrite the call in the RHS of $dC_1
and we get a loop!


Note [specImport call stack]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When specialising an imports function 'f', we may get new calls
of an imported fuction 'g', which we want to specialise in turn,
and similarly specialising 'g' might expose a new call to 'h'.

We track the stack of enclosing functions. So when specialising 'h' we
haev a specImport call stack of [g,f]. We do this for two reasons:
* Note [Warning about missed specialisations]
* Note [Avoiding recursive specialisation]

Note [Warning about missed specialisations]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Suppose
 * In module Lib, you carefully mark a function 'foo' INLINABLE
 * Import Lib(foo) into another module M
 * Call 'foo' at some specialised type in M
Then you jolly well expect it to be specialised in M.  But what if
'foo' calls another function 'Lib.bar'.  Then you'd like 'bar' to be
specialised too.  But if 'bar' is not marked INLINABLE it may well
not be specialised.  The warning Opt_WarnMissedSpecs warns about this.

It's more noisy to warning about a missed specialisation opportunity
for /every/ overloaded imported function, but sometimes useful. That
is what Opt_WarnAllMissedSpecs does.

ToDo: warn about missed opportunities for local functions.

Note [Avoiding recursive specialisation]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When we specialise 'f' we may find new overloaded calls to 'g', 'h' in
'f's RHS.  So we want to specialise g,h.  But we don't want to
specialise f any more!  It's possible that f's RHS might have a
recursive yet-more-specialised call, so we'd diverge in that case.
And if the call is to the same type, one specialisation is enough.
Avoiding this recursive specialisation loop is one reason for the
'callers' stack passed to specImports and specImport.

Note [Specialise imported INLINABLE things]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
What imported functions do we specialise?  The basic set is
 * DFuns and things with INLINABLE pragmas.
but with -fspecialise-aggressively we add
 * Anything with an unfolding template

#8874 has a good example of why we want to auto-specialise DFuns.

We have the -fspecialise-aggressively flag (usually off), because we
risk lots of orphan modules from over-vigorous specialisation.
However it's not a big deal: anything non-recursive with an
unfolding-template will probably have been inlined already.

Note [Glom the bindings if imported functions are specialised]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Suppose we have an imported, *recursive*, INLINABLE function
   f :: Eq a => a -> a
   f = /\a \d x. ...(f a d)...
In the module being compiled we have
   g x = f (x::Int)
Now we'll make a specialised function
   f_spec :: Int -> Int
   f_spec = \x -> ...(f Int dInt)...
   {-# RULE  f Int _ = f_spec #-}
   g = \x. f Int dInt x
Note that f_spec doesn't look recursive
After rewriting with the RULE, we get
   f_spec = \x -> ...(f_spec)...
BUT since f_spec was non-recursive before it'll *stay* non-recursive.
The occurrence analyser never turns a NonRec into a Rec.  So we must
make sure that f_spec is recursive.  Easiest thing is to make all
the specialisations for imported bindings recursive.



************************************************************************
*                                                                      *
\subsubsection{@specExpr@: the main function}
*                                                                      *
************************************************************************
-}

data SpecEnv
  = SE { se_subst :: Core.Subst
             -- We carry a substitution down:
             -- a) we must clone any binding that might float outwards,
             --    to avoid name clashes
             -- b) we carry a type substitution to use when analysing
             --    the RHS of specialised bindings (no type-let!)


       , se_interesting :: VarSet
             -- Dict Ids that we know something about
             -- and hence may be worth specialising against
             -- See Note [Interesting dictionary arguments]
     }

instance Outputable SpecEnv where
  ppr (SE { se_subst = subst, se_interesting = interesting })
    = text "SE" <+> braces (sep $ punctuate comma
        [ text "subst =" <+> ppr subst
        , text "interesting =" <+> ppr interesting ])

specVar :: SpecEnv -> Id -> CoreExpr
specVar env v = Core.lookupIdSubst (text "specVar") (se_subst env) v

specExpr :: SpecEnv -> CoreExpr -> SpecM (CoreExpr, UsageDetails)

---------------- First the easy cases --------------------
specExpr env (Type ty)     = return (Type     (substTy env ty), emptyUDs)
specExpr env (Coercion co) = return (Coercion (substCo env co), emptyUDs)
specExpr env (Var v)       = return (specVar env v, emptyUDs)
specExpr _   (Lit lit)     = return (Lit lit,       emptyUDs)
specExpr env (Cast e co)
  = do { (e', uds) <- specExpr env e
       ; return ((mkCast e' (substCo env co)), uds) }
specExpr env (Tick tickish body)
  = do { (body', uds) <- specExpr env body
       ; return (Tick (specTickish env tickish) body', uds) }

---------------- Applications might generate a call instance --------------------
specExpr env expr@(App {})
  = go expr []
  where
    go (App fun arg) args = do (arg', uds_arg) <- specExpr env arg
                               (fun', uds_app) <- go fun (arg':args)
                               return (App fun' arg', uds_arg `plusUDs` uds_app)

    go (Var f)       args = case specVar env f of
                                Var f' -> return (Var f', mkCallUDs env f' args)
                                e'     -> return (e', emptyUDs) -- I don't expect this!
    go other         _    = specExpr env other

---------------- Lambda/case require dumping of usage details --------------------
specExpr env e@(Lam _ _) = do
    (body', uds) <- specExpr env' body
    let (free_uds, dumped_dbs) = dumpUDs bndrs' uds
    return (mkLams bndrs' (wrapDictBindsE dumped_dbs body'), free_uds)
  where
    (bndrs, body) = collectBinders e
    (env', bndrs') = substBndrs env bndrs
        -- More efficient to collect a group of binders together all at once
        -- and we don't want to split a lambda group with dumped bindings

specExpr env (Case scrut case_bndr ty alts)
  = do { (scrut', scrut_uds) <- specExpr env scrut
       ; (scrut'', case_bndr', alts', alts_uds)
             <- specCase env scrut' case_bndr alts
       ; return (Case scrut'' case_bndr' (substTy env ty) alts'
                , scrut_uds `plusUDs` alts_uds) }

---------------- Finally, let is the interesting case --------------------
specExpr env (Let bind body)
  = do { -- Clone binders
         (rhs_env, body_env, bind') <- cloneBindSM env bind

         -- Deal with the body
       ; (body', body_uds) <- specExpr body_env body

        -- Deal with the bindings
      ; (binds', uds) <- specBind rhs_env bind' body_uds

        -- All done
      ; return (foldr Let body' binds', uds) }

--------------
specLam :: SpecEnv -> [OutBndr] -> InExpr -> SpecM (OutExpr, UsageDetails)
-- The binders have been substituted, but the body has not
specLam env bndrs body
  | null bndrs
  = specExpr env body
  | otherwise
  = do { (body', uds) <- specExpr env body
       ; let (free_uds, dumped_dbs) = dumpUDs bndrs uds
       ; return (mkLams bndrs (wrapDictBindsE dumped_dbs body'), free_uds) }

--------------
specTickish :: SpecEnv -> Tickish Id -> Tickish Id
specTickish env (Breakpoint ix ids)
  = Breakpoint ix [ id' | id <- ids, Var id' <- [specVar env id]]
  -- drop vars from the list if they have a non-variable substitution.
  -- should never happen, but it's harmless to drop them anyway.
specTickish _ other_tickish = other_tickish

--------------
specCase :: SpecEnv
         -> CoreExpr            -- Scrutinee, already done
         -> Id -> [CoreAlt]
         -> SpecM ( CoreExpr    -- New scrutinee
                  , Id
                  , [CoreAlt]
                  , UsageDetails)
specCase env scrut' case_bndr [(con, args, rhs)]
  | isDictId case_bndr           -- See Note [Floating dictionaries out of cases]
  , interestingDict env scrut'
  , not (isDeadBinder case_bndr && null sc_args')
  = do { (case_bndr_flt : sc_args_flt) <- mapM clone_me (case_bndr' : sc_args')

       ; let sc_rhss = [ Case (Var case_bndr_flt) case_bndr' (idType sc_arg')
                              [(con, args', Var sc_arg')]
                       | sc_arg' <- sc_args' ]

             -- Extend the substitution for RHS to map the *original* binders
             -- to their floated versions.
             mb_sc_flts :: [Maybe DictId]
             mb_sc_flts = map (lookupVarEnv clone_env) args'
             clone_env  = zipVarEnv sc_args' sc_args_flt
             subst_prs  = (case_bndr, Var case_bndr_flt)
                        : [ (arg, Var sc_flt)
                          | (arg, Just sc_flt) <- args `zip` mb_sc_flts ]
             env_rhs' = env_rhs { se_subst = Core.extendIdSubstList (se_subst env_rhs) subst_prs
                                , se_interesting = se_interesting env_rhs `extendVarSetList`
                                                   (case_bndr_flt : sc_args_flt) }

       ; (rhs', rhs_uds)   <- specExpr env_rhs' rhs
       ; let scrut_bind    = mkDB (NonRec case_bndr_flt scrut')
             case_bndr_set = unitVarSet case_bndr_flt
             sc_binds      = [(NonRec sc_arg_flt sc_rhs, case_bndr_set)
                             | (sc_arg_flt, sc_rhs) <- sc_args_flt `zip` sc_rhss ]
             flt_binds     = scrut_bind : sc_binds
             (free_uds, dumped_dbs) = dumpUDs (case_bndr':args') rhs_uds
             all_uds = flt_binds `addDictBinds` free_uds
             alt'    = (con, args', wrapDictBindsE dumped_dbs rhs')
       ; return (Var case_bndr_flt, case_bndr', [alt'], all_uds) }
  where
    (env_rhs, (case_bndr':args')) = substBndrs env (case_bndr:args)
    sc_args' = filter is_flt_sc_arg args'

    clone_me bndr = do { uniq <- getUniqueM
                       ; return (mkUserLocalOrCoVar occ uniq ty loc) }
       where
         name = idName bndr
         ty   = idType bndr
         occ  = nameOccName name
         loc  = getSrcSpan name

    arg_set = mkVarSet args'
    is_flt_sc_arg var =  isId var
                      && not (isDeadBinder var)
                      && isDictTy var_ty
                      && not (tyCoVarsOfType var_ty `intersectsVarSet` arg_set)
       where
         var_ty = idType var


specCase env scrut case_bndr alts
  = do { (alts', uds_alts) <- mapAndCombineSM spec_alt alts
       ; return (scrut, case_bndr', alts', uds_alts) }
  where
    (env_alt, case_bndr') = substBndr env case_bndr
    spec_alt (con, args, rhs) = do
          (rhs', uds) <- specExpr env_rhs rhs
          let (free_uds, dumped_dbs) = dumpUDs (case_bndr' : args') uds
          return ((con, args', wrapDictBindsE dumped_dbs rhs'), free_uds)
        where
          (env_rhs, args') = substBndrs env_alt args

{-
Note [Floating dictionaries out of cases]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider
   g = \d. case d of { MkD sc ... -> ...(f sc)... }
Naively we can't float d2's binding out of the case expression,
because 'sc' is bound by the case, and that in turn means we can't
specialise f, which seems a pity.

So we invert the case, by floating out a binding
for 'sc_flt' thus:
    sc_flt = case d of { MkD sc ... -> sc }
Now we can float the call instance for 'f'.  Indeed this is just
what'll happen if 'sc' was originally bound with a let binding,
but case is more efficient, and necessary with equalities. So it's
good to work with both.

You might think that this won't make any difference, because the
call instance will only get nuked by the \d.  BUT if 'g' itself is
specialised, then transitively we should be able to specialise f.

In general, given
   case e of cb { MkD sc ... -> ...(f sc)... }
we transform to
   let cb_flt = e
       sc_flt = case cb_flt of { MkD sc ... -> sc }
   in
   case cb_flt of bg { MkD sc ... -> ....(f sc_flt)... }

The "_flt" things are the floated binds; we use the current substitution
to substitute sc -> sc_flt in the RHS

************************************************************************
*                                                                      *
                     Dealing with a binding
*                                                                      *
************************************************************************
-}

specBind :: SpecEnv                     -- Use this for RHSs
         -> CoreBind                    -- Binders are already cloned by cloneBindSM,
                                        -- but RHSs are un-processed
         -> UsageDetails                -- Info on how the scope of the binding
         -> SpecM ([CoreBind],          -- New bindings
                   UsageDetails)        -- And info to pass upstream

-- Returned UsageDetails:
--    No calls for binders of this bind
specBind rhs_env (NonRec fn rhs) body_uds
  = do { (rhs', rhs_uds) <- specExpr rhs_env rhs

        ; let zapped_fn = zapIdDemandInfo fn
              -- We zap the demand info because the binding may float,
              -- which would invaidate the demand info (see #17810 for example).
              -- Destroying demand info is not terrible; specialisation is
              -- always followed soon by demand analysis.
      ; (fn', spec_defns, body_uds1) <- specDefn rhs_env body_uds zapped_fn rhs

       ; let pairs = spec_defns ++ [(fn', rhs')]
                        -- fn' mentions the spec_defns in its rules,
                        -- so put the latter first

             combined_uds = body_uds1 `plusUDs` rhs_uds

             (free_uds, dump_dbs, float_all) = dumpBindUDs [fn] combined_uds

             final_binds :: [DictBind]
             -- See Note [From non-recursive to recursive]
             final_binds
               | not (isEmptyBag dump_dbs)
               , not (null spec_defns)
               = [recWithDumpedDicts pairs dump_dbs]
               | otherwise
               = [mkDB $ NonRec b r | (b,r) <- pairs]
                 ++ bagToList dump_dbs

       ; if float_all then
             -- Rather than discard the calls mentioning the bound variables
             -- we float this (dictionary) binding along with the others
              return ([], free_uds `snocDictBinds` final_binds)
         else
             -- No call in final_uds mentions bound variables,
             -- so we can just leave the binding here
              return (map fst final_binds, free_uds) }


specBind rhs_env (Rec pairs) body_uds
       -- Note [Specialising a recursive group]
  = do { let (bndrs,rhss) = unzip pairs
       ; (rhss', rhs_uds) <- mapAndCombineSM (specExpr rhs_env) rhss
       ; let scope_uds = body_uds `plusUDs` rhs_uds
                       -- Includes binds and calls arising from rhss

       ; (bndrs1, spec_defns1, uds1) <- specDefns rhs_env scope_uds pairs

       ; (bndrs3, spec_defns3, uds3)
             <- if null spec_defns1  -- Common case: no specialisation
                then return (bndrs1, [], uds1)
                else do {            -- Specialisation occurred; do it again
                          (bndrs2, spec_defns2, uds2)
                              <- specDefns rhs_env uds1 (bndrs1 `zip` rhss)
                        ; return (bndrs2, spec_defns2 ++ spec_defns1, uds2) }

       ; let (final_uds, dumped_dbs, float_all) = dumpBindUDs bndrs uds3
             final_bind = recWithDumpedDicts (spec_defns3 ++ zip bndrs3 rhss')
                                             dumped_dbs

       ; if float_all then
              return ([], final_uds `snocDictBind` final_bind)
         else
              return ([fst final_bind], final_uds) }


---------------------------
specDefns :: SpecEnv
          -> UsageDetails               -- Info on how it is used in its scope
          -> [(OutId,InExpr)]           -- The things being bound and their un-processed RHS
          -> SpecM ([OutId],            -- Original Ids with RULES added
                    [(OutId,OutExpr)],  -- Extra, specialised bindings
                    UsageDetails)       -- Stuff to fling upwards from the specialised versions

-- Specialise a list of bindings (the contents of a Rec), but flowing usages
-- upwards binding by binding.  Example: { f = ...g ...; g = ...f .... }
-- Then if the input CallDetails has a specialised call for 'g', whose specialisation
-- in turn generates a specialised call for 'f', we catch that in this one sweep.
-- But not vice versa (it's a fixpoint problem).

specDefns _env uds []
  = return ([], [], uds)
specDefns env uds ((bndr,rhs):pairs)
  = do { (bndrs1, spec_defns1, uds1) <- specDefns env uds pairs
       ; (bndr1, spec_defns2, uds2)  <- specDefn env uds1 bndr rhs
       ; return (bndr1 : bndrs1, spec_defns1 ++ spec_defns2, uds2) }

---------------------------
specDefn :: SpecEnv
         -> UsageDetails                -- Info on how it is used in its scope
         -> OutId -> InExpr             -- The thing being bound and its un-processed RHS
         -> SpecM (Id,                  -- Original Id with added RULES
                   [(Id,CoreExpr)],     -- Extra, specialised bindings
                   UsageDetails)        -- Stuff to fling upwards from the specialised versions

specDefn env body_uds fn rhs
  = do { let (body_uds_without_me, calls_for_me) = callsForMe fn body_uds
             rules_for_me = idCoreRules fn
       ; (rules, spec_defns, spec_uds) <- specCalls Nothing env rules_for_me
                                                    calls_for_me fn rhs
       ; return ( fn `addIdSpecialisations` rules
                , spec_defns
                , body_uds_without_me `plusUDs` spec_uds) }
                -- It's important that the `plusUDs` is this way
                -- round, because body_uds_without_me may bind
                -- dictionaries that are used in calls_for_me passed
                -- to specDefn.  So the dictionary bindings in
                -- spec_uds may mention dictionaries bound in
                -- body_uds_without_me

---------------------------
specCalls :: Maybe Module      -- Just this_mod  =>  specialising imported fn
                               -- Nothing        =>  specialising local fn
          -> SpecEnv
          -> [CoreRule]        -- Existing RULES for the fn
          -> [CallInfo]
          -> OutId -> InExpr
          -> SpecM SpecInfo    -- New rules, specialised bindings, and usage details

-- This function checks existing rules, and does not create
-- duplicate ones. So the caller does not need to do this filtering.
-- See 'already_covered'

type SpecInfo = ( [CoreRule]       -- Specialisation rules
                , [(Id,CoreExpr)]  -- Specialised definition
                , UsageDetails )   -- Usage details from specialised RHSs

specCalls mb_mod env existing_rules calls_for_me fn rhs
        -- The first case is the interesting one
  |  notNull calls_for_me               -- And there are some calls to specialise
  && not (isNeverActive (idInlineActivation fn))
        -- Don't specialise NOINLINE things
        -- See Note [Auto-specialisation and RULES]

--   && not (certainlyWillInline (idUnfolding fn))      -- And it's not small
--      See Note [Inline specialisation] for why we do not
--      switch off specialisation for inline functions

  = -- pprTrace "specDefn: some" (ppr fn $$ ppr calls_for_me $$ ppr existing_rules) $
    foldlM spec_call ([], [], emptyUDs) calls_for_me

  | otherwise   -- No calls or RHS doesn't fit our preconceptions
  = WARN( not (exprIsTrivial rhs) && notNull calls_for_me,
          text "Missed specialisation opportunity for"
                                 <+> ppr fn $$ _trace_doc )
          -- Note [Specialisation shape]
    -- pprTrace "specDefn: none" (ppr fn <+> ppr calls_for_me) $
    return ([], [], emptyUDs)
  where
    _trace_doc = sep [ ppr rhs_bndrs, ppr (idInlineActivation fn) ]

    fn_type   = idType fn
    fn_arity  = idArity fn
    fn_unf    = realIdUnfolding fn  -- Ignore loop-breaker-ness here
    inl_prag  = idInlinePragma fn
    inl_act   = inlinePragmaActivation inl_prag
    is_local  = isLocalId fn
    is_dfun   = isDFunId fn

        -- Figure out whether the function has an INLINE pragma
        -- See Note [Inline specialisations]

    (rhs_bndrs, rhs_body) = collectBindersPushingCo rhs
                            -- See Note [Account for casts in binding]

    in_scope = Core.substInScope (se_subst env)

    already_covered :: DynFlags -> [CoreRule] -> [CoreExpr] -> Bool
    already_covered dflags new_rules args      -- Note [Specialisations already covered]
       = isJust (lookupRule dflags (in_scope, realIdUnfolding)
                            (const True) fn args
                            (new_rules ++ existing_rules))
         -- NB: we look both in the new_rules (generated by this invocation
         --     of specCalls), and in existing_rules (passed in to specCalls)

    ----------------------------------------------------------
        -- Specialise to one particular call pattern
    spec_call :: SpecInfo                         -- Accumulating parameter
              -> CallInfo                         -- Call instance
              -> SpecM SpecInfo
    spec_call spec_acc@(rules_acc, pairs_acc, uds_acc) _ci@(CI { ci_key = call_args })
      = -- See Note [Specialising Calls]
        do { let all_call_args | is_dfun   = call_args ++ repeat UnspecArg
                               | otherwise = call_args
                               -- See Note [Specialising DFuns]
           ; ( useful, rhs_env2, leftover_bndrs
             , rule_bndrs, rule_lhs_args
             , spec_bndrs1, dx_binds, spec_args) <- specHeader env rhs_bndrs all_call_args

--           ; pprTrace "spec_call" (vcat [ text "call info: " <+> ppr _ci
--                                        , text "useful:    " <+> ppr useful
--                                        , text "rule_bndrs:" <+> ppr rule_bndrs
--                                        , text "lhs_args:  " <+> ppr rule_lhs_args
--                                        , text "spec_bndrs:" <+> ppr spec_bndrs1
--                                        , text "spec_args: " <+> ppr spec_args
--                                        , text "dx_binds:  " <+> ppr dx_binds
--                                        , text "rhs_env2:  " <+> ppr (se_subst rhs_env2)
--                                        , ppr dx_binds ]) $
--             return ()

           ; dflags <- getDynFlags
           ; if not useful  -- No useful specialisation
                || already_covered dflags rules_acc rule_lhs_args
             then return spec_acc
             else
        do { -- Run the specialiser on the specialised RHS
             -- The "1" suffix is before we maybe add the void arg
           ; (spec_rhs1, rhs_uds) <- specLam rhs_env2 (spec_bndrs1 ++ leftover_bndrs) rhs_body
           ; let spec_fn_ty1 = exprType spec_rhs1

                 -- Maybe add a void arg to the specialised function,
                 -- to avoid unlifted bindings
                 -- See Note [Specialisations Must Be Lifted]
                 -- C.f. GHC.Core.Op.WorkWrap.Lib.mkWorkerArgs
                 add_void_arg = isUnliftedType spec_fn_ty1 && not (isJoinId fn)
                 (spec_bndrs, spec_rhs, spec_fn_ty)
                   | add_void_arg = ( voidPrimId : spec_bndrs1
                                    , Lam        voidArgId  spec_rhs1
                                    , mkVisFunTy voidPrimTy spec_fn_ty1)
                   | otherwise   = (spec_bndrs1, spec_rhs1, spec_fn_ty1)

                 join_arity_decr = length rule_lhs_args - length spec_bndrs
                 spec_join_arity | Just orig_join_arity <- isJoinId_maybe fn
                                 = Just (orig_join_arity - join_arity_decr)
                                 | otherwise
                                 = Nothing

           ; spec_fn <- newSpecIdSM fn spec_fn_ty spec_join_arity
           ; this_mod <- getModule
           ; let
                -- The rule to put in the function's specialisation is:
                --      forall x @b d1' d2'.
                --          f x @T1 @b @T2 d1' d2' = f1 x @b
                -- See Note [Specialising Calls]
                herald = case mb_mod of
                           Nothing        -- Specialising local fn
                               -> text "SPEC"
                           Just this_mod  -- Specialising imported fn
                               -> text "SPEC/" <> ppr this_mod

                rule_name = mkFastString $ showSDoc dflags $
                            herald <+> ftext (occNameFS (getOccName fn))
                                   <+> hsep (mapMaybe ppr_call_key_ty call_args)
                            -- This name ends up in interface files, so use occNameString.
                            -- Otherwise uniques end up there, making builds
                            -- less deterministic (See #4012 comment:61 ff)

                rule_wout_eta = mkRule
                                  this_mod
                                  True {- Auto generated -}
                                  is_local
                                  rule_name
                                  inl_act       -- Note [Auto-specialisation and RULES]
                                  (idName fn)
                                  rule_bndrs
                                  rule_lhs_args
                                  (mkVarApps (Var spec_fn) spec_bndrs)

                spec_rule
                  = case isJoinId_maybe fn of
                      Just join_arity -> etaExpandToJoinPointRule join_arity rule_wout_eta
                      Nothing -> rule_wout_eta

                -- Add the { d1' = dx1; d2' = dx2 } usage stuff
                -- See Note [Specialising Calls]
                spec_uds = foldr consDictBind rhs_uds dx_binds

                --------------------------------------
                -- Add a suitable unfolding if the spec_inl_prag says so
                -- See Note [Inline specialisations]
                (spec_inl_prag, spec_unf)
                  | not is_local && isStrongLoopBreaker (idOccInfo fn)
                  = (neverInlinePragma, noUnfolding)
                        -- See Note [Specialising imported functions] in OccurAnal

                  | InlinePragma { inl_inline = Inlinable } <- inl_prag
                  = (inl_prag { inl_inline = NoUserInline }, noUnfolding)

                  | otherwise
                  = (inl_prag, specUnfolding dflags spec_bndrs (`mkApps` spec_args)
                                             rule_lhs_args fn_unf)

                --------------------------------------
                -- Adding arity information just propagates it a bit faster
                --      See Note [Arity decrease] in Simplify
                -- Copy InlinePragma information from the parent Id.
                -- So if f has INLINE[1] so does spec_fn
                arity_decr     = count isValArg rule_lhs_args - count isId spec_bndrs
                spec_f_w_arity = spec_fn `setIdArity`      max 0 (fn_arity - arity_decr)
                                         `setInlinePragma` spec_inl_prag
                                         `setIdUnfolding`  spec_unf
                                         `asJoinId_maybe`  spec_join_arity

                _rule_trace_doc = vcat [ ppr fn <+> dcolon <+> ppr fn_type
                                       , ppr spec_fn  <+> dcolon <+> ppr spec_fn_ty
                                       , ppr rhs_bndrs, ppr call_args
                                       , ppr spec_rule
                                       ]

           ; -- pprTrace "spec_call: rule" _rule_trace_doc
             return ( spec_rule                  : rules_acc
                    , (spec_f_w_arity, spec_rhs) : pairs_acc
                    , spec_uds           `plusUDs` uds_acc
                    ) } }

{- Note [Specialising DFuns]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DFuns have a special sort of unfolding (DFunUnfolding), and these are
hard to specialise a DFunUnfolding to give another DFunUnfolding
unless the DFun is fully applied (#18120).  So, in the case of DFunIds
we simply extend the CallKey with trailing UnspecArgs, so we'll
generate a rule that completely saturates the DFun.

There is an ASSERT that checks this, in the DFunUnfolding case of
GHC.Core.Unfold.specUnfolding.

Note [Specialisation Must Preserve Sharing]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider a function:

    f :: forall a. Eq a => a -> blah
    f =
      if expensive
         then f1
         else f2

As written, all calls to 'f' will share 'expensive'. But if we specialise 'f'
at 'Int', eg:

    $sfInt = SUBST[a->Int,dict->dEqInt] (if expensive then f1 else f2)

    RULE "SPEC f"
      forall (d :: Eq Int).
        f Int _ = $sfIntf

We've now lost sharing between 'f' and '$sfInt' for 'expensive'. Yikes!

To avoid this, we only generate specialisations for functions whose arity is
enough to bind all of the arguments we need to specialise.  This ensures our
specialised functions don't do any work before receiving all of their dicts,
and thus avoids the 'f' case above.

Note [Specialisations Must Be Lifted]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider a function 'f':

    f = forall a. Eq a => Array# a

used like

    case x of
      True -> ...f @Int dEqInt...
      False -> 0

Naively, we might generate an (expensive) specialisation

    $sfInt :: Array# Int

even in the case that @x = False@! Instead, we add a dummy 'Void#' argument to
the specialisation '$sfInt' ($sfInt :: Void# -> Array# Int) in order to
preserve laziness.

Note [Specialising Calls]
~~~~~~~~~~~~~~~~~~~~~~~~~
Suppose we have a function with a complicated type:

    f :: forall a b c. Int -> Eq a => Show b => c -> Blah
    f @a @b @c i dEqA dShowA x = blah

and suppose it is called at:

    f 7 @T1 @T2 @T3 dEqT1 ($dfShow dShowT2) t3

This call is described as a 'CallInfo' whose 'ci_key' is:

    [ SpecType T1, SpecType T2, UnspecType, UnspecArg, SpecDict dEqT1
    , SpecDict ($dfShow dShowT2), UnspecArg ]

Why are 'a' and 'b' identified as 'SpecType', while 'c' is 'UnspecType'?
Because we must specialise the function on type variables that appear
free in its *dictionary* arguments; but not on type variables that do not
appear in any dictionaries, i.e. are fully polymorphic.

Because this call has dictionaries applied, we'd like to specialise
the call on any type argument that appears free in those dictionaries.
In this case, those are [a :-> T1, b :-> T2].

We also need to substitute the dictionary binders with their
specialised dictionaries. The simplest substitution would be
[dEqA :-> dEqT1, dShowA :-> $dfShow dShowT2], but this duplicates
work, since `$dfShow dShowT2` is a function application. Therefore, we
also want to *float the dictionary out* (via bindAuxiliaryDict),
creating a new dict binding

    dShow1 = $dfShow dShowT2

and the substitution [dEqA :-> dEqT1, dShowA :-> dShow1].

With the substitutions in hand, we can generate a specialised function:

    $sf :: forall c. Int -> c -> Blah
    $sf = SUBST[a :-> T1, b :-> T2, dEqA :-> dEqT1, dShowA :-> dShow1] (\@c i x -> blah)

Note that the substitution is applied to the whole thing.  This is
convenient, but just slightly fragile.  Notably:
  * There had better be no name clashes in a/b/c

We must construct a rewrite rule:

    RULE "SPEC f @T1 @T2 _"
      forall (@c :: Type) (i :: Int) (d1 :: Eq T1) (d2 :: Show T2).
        f @T1 @T2 @c i d1 d2 = $sf @c i

In the rule, d1 and d2 are just wildcards, not used in the RHS.  Note
additionally that 'x' isn't captured by this rule --- we bind only
enough etas in order to capture all of the *specialised* arguments.

Note [Drop dead args from specialisations]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When specialising a function, it’s possible some of the arguments may
actually be dead. For example, consider:

    f :: forall a. () -> Show a => a -> String
    f x y = show y ++ "!"

We might generate the following CallInfo for `f @Int`:

    [SpecType Int, UnspecArg, SpecDict $dShowInt, UnspecArg]

Normally we’d include both the x and y arguments in the
specialisation, since we’re not specialising on either of them. But
that’s silly, since x is actually unused! So we might as well drop it
in the specialisation:

    $sf :: Int -> String
    $sf y = show y ++ "!"

    {-# RULE "SPEC f @Int" forall x. f @Int x $dShow = $sf #-}

This doesn’t save us much, since the arg would be removed later by
worker/wrapper, anyway, but it’s easy to do. Note, however, that we
only drop dead arguments if:

  1. We don’t specialise on them.
  2. They come before an argument we do specialise on.

Doing the latter would require eta-expanding the RULE, which could
make it match less often, so it’s not worth it. Doing the former could
be more useful --- it would stop us from generating pointless
specialisations --- but it’s more involved to implement and unclear if
it actually provides much benefit in practice.

Note [Zap occ info in rule binders]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When we generate a specialisation RULE, we need to drop occurrence
info on the binders. If we don’t, things go wrong when we specialise a
function like

    f :: forall a. () -> Show a => a -> String
    f x y = show y ++ "!"

since we’ll generate a RULE like

    RULE "SPEC f @Int" forall x [Occ=Dead].
      f @Int x $dShow = $sf

and Core Lint complains, even though x only appears on the LHS (due to
Note [Drop dead args from specialisations]).

Why is that a Lint error? Because the arguments on the LHS of a rule
are syntactically expressions, not patterns, so Lint treats the
appearance of x as a use rather than a binding. Fortunately, the
solution is simple: we just make sure to zap the occ info before
using ids as wildcard binders in a rule.

Note [Account for casts in binding]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider
   f :: Eq a => a -> IO ()
   {-# INLINABLE f
       StableUnf = (/\a \(d:Eq a) (x:a). blah) |> g
     #-}
   f = ...

In f's stable unfolding we have done some modest simplification which
has pushed the cast to the outside.  (I wonder if this is the Right
Thing, but it's what happens now; see SimplUtils Note [Casts and
lambdas].)  Now that stable unfolding must be specialised, so we want
to push the cast back inside. It would be terrible if the cast
defeated specialisation!  Hence the use of collectBindersPushingCo.

Note [Evidence foralls]
~~~~~~~~~~~~~~~~~~~~~~~~~~
Suppose (#12212) that we are specialising
   f :: forall a b. (Num a, F a ~ F b) => blah
with a=b=Int. Then the RULE will be something like
   RULE forall (d:Num Int) (g :: F Int ~ F Int).
        f Int Int d g = f_spec
But both varToCoreExpr (when constructing the LHS args), and the
simplifier (when simplifying the LHS args), will transform to
   RULE forall (d:Num Int) (g :: F Int ~ F Int).
        f Int Int d <F Int> = f_spec
by replacing g with Refl.  So now 'g' is unbound, which results in a later
crash. So we use Refl right off the bat, and do not forall-quantify 'g':
 * varToCoreExpr generates a Refl
 * exprsFreeIdsList returns the Ids bound by the args,
   which won't include g

You might wonder if this will match as often, but the simplifier replaces
complicated Refl coercions with Refl pretty aggressively.

Note [Orphans and auto-generated rules]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When we specialise an INLINABLE function, or when we have
-fspecialise-aggressively, we auto-generate RULES that are orphans.
We don't want to warn about these, or we'd generate a lot of warnings.
Thus, we only warn about user-specified orphan rules.

Indeed, we don't even treat the module as an orphan module if it has
auto-generated *rule* orphans.  Orphan modules are read every time we
compile, so they are pretty obtrusive and slow down every compilation,
even non-optimised ones.  (Reason: for type class instances it's a
type correctness issue.)  But specialisation rules are strictly for
*optimisation* only so it's fine not to read the interface.

What this means is that a SPEC rules from auto-specialisation in
module M will be used in other modules only if M.hi has been read for
some other reason, which is actually pretty likely.

Note [From non-recursive to recursive]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Even in the non-recursive case, if any dict-binds depend on 'fn' we might
have built a recursive knot

      f a d x = <blah>
      MkUD { ud_binds = NonRec d7  (MkD ..f..)
           , ud_calls = ...(f T d7)... }

The we generate

     Rec { fs x = <blah>[T/a, d7/d]
           f a d x = <blah>
               RULE f T _ = fs
           d7 = ...f... }

Here the recursion is only through the RULE.

However we definitely should /not/ make the Rec in this wildly common
case:
      d = ...
      MkUD { ud_binds = NonRec d7 (...d...)
           , ud_calls = ...(f T d7)... }

Here we want simply to add d to the floats, giving
      MkUD { ud_binds = NonRec d (...)
                        NonRec d7 (...d...)
           , ud_calls = ...(f T d7)... }

In general, we need only make this Rec if
  - there are some specialisations (spec_binds non-empty)
  - there are some dict_binds that depend on f (dump_dbs non-empty)

Note [Avoiding loops]
~~~~~~~~~~~~~~~~~~~~~
When specialising /dictionary functions/ we must be very careful to
avoid building loops. Here is an example that bit us badly: #3591

     class Eq a => C a
     instance Eq [a] => C [a]

This translates to
     dfun :: Eq [a] -> C [a]
     dfun a d = MkD a d (meth d)

     d4 :: Eq [T] = <blah>
     d2 ::  C [T] = dfun T d4
     d1 :: Eq [T] = $p1 d2
     d3 ::  C [T] = dfun T d1

None of these definitions is recursive. What happened was that we
generated a specialisation:
     RULE forall d. dfun T d = dT  :: C [T]
     dT = (MkD a d (meth d)) [T/a, d1/d]
        = MkD T d1 (meth d1)

But now we use the RULE on the RHS of d2, to get
    d2 = dT = MkD d1 (meth d1)
    d1 = $p1 d2

and now d1 is bottom!  The problem is that when specialising 'dfun' we
should first dump "below" the binding all floated dictionary bindings
that mention 'dfun' itself.  So d2 and d3 (and hence d1) must be
placed below 'dfun', and thus unavailable to it when specialising
'dfun'.  That in turn means that the call (dfun T d1) must be
discarded.  On the other hand, the call (dfun T d4) is fine, assuming
d4 doesn't mention dfun.

Solution:
  Discard all calls that mention dictionaries that depend
  (directly or indirectly) on the dfun we are specialising.
  This is done by 'filterCalls'

--------------
Here's yet another example

  class C a where { foo,bar :: [a] -> [a] }

  instance C Int where
     foo x = r_bar x
     bar xs = reverse xs

  r_bar :: C a => [a] -> [a]
  r_bar xs = bar (xs ++ xs)

That translates to:

    r_bar a (c::C a) (xs::[a]) = bar a d (xs ++ xs)

    Rec { $fCInt :: C Int = MkC foo_help reverse
          foo_help (xs::[Int]) = r_bar Int $fCInt xs }

The call (r_bar $fCInt) mentions $fCInt,
                        which mentions foo_help,
                        which mentions r_bar
But we DO want to specialise r_bar at Int:

    Rec { $fCInt :: C Int = MkC foo_help reverse
          foo_help (xs::[Int]) = r_bar Int $fCInt xs

          r_bar a (c::C a) (xs::[a]) = bar a d (xs ++ xs)
            RULE r_bar Int _ = r_bar_Int

          r_bar_Int xs = bar Int $fCInt (xs ++ xs)
           }

Note that, because of its RULE, r_bar joins the recursive
group.  (In this case it'll unravel a short moment later.)


Note [Specialising a recursive group]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider
    let rec { f x = ...g x'...
            ; g y = ...f y'.... }
    in f 'a'
Here we specialise 'f' at Char; but that is very likely to lead to
a specialisation of 'g' at Char.  We must do the latter, else the
whole point of specialisation is lost.

But we do not want to keep iterating to a fixpoint, because in the
presence of polymorphic recursion we might generate an infinite number
of specialisations.

So we use the following heuristic:
  * Arrange the rec block in dependency order, so far as possible
    (the occurrence analyser already does this)

  * Specialise it much like a sequence of lets

  * Then go through the block a second time, feeding call-info from
    the RHSs back in the bottom, as it were

In effect, the ordering maxmimises the effectiveness of each sweep,
and we do just two sweeps.   This should catch almost every case of
monomorphic recursion -- the exception could be a very knotted-up
recursion with multiple cycles tied up together.

This plan is implemented in the Rec case of specBindItself.

Note [Specialisations already covered]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We obviously don't want to generate two specialisations for the same
argument pattern.  There are two wrinkles

1. We do the already-covered test in specDefn, not when we generate
the CallInfo in mkCallUDs.  We used to test in the latter place, but
we now iterate the specialiser somewhat, and the Id at the call site
might therefore not have all the RULES that we can see in specDefn

2. What about two specialisations where the second is an *instance*
of the first?  If the more specific one shows up first, we'll generate
specialisations for both.  If the *less* specific one shows up first,
we *don't* currently generate a specialisation for the more specific
one.  (See the call to lookupRule in already_covered.)  Reasons:
  (a) lookupRule doesn't say which matches are exact (bad reason)
  (b) if the earlier specialisation is user-provided, it's
      far from clear that we should auto-specialise further

Note [Auto-specialisation and RULES]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider:
   g :: Num a => a -> a
   g = ...

   f :: (Int -> Int) -> Int
   f w = ...
   {-# RULE f g = 0 #-}

Suppose that auto-specialisation makes a specialised version of
g::Int->Int That version won't appear in the LHS of the RULE for f.
So if the specialisation rule fires too early, the rule for f may
never fire.

It might be possible to add new rules, to "complete" the rewrite system.
Thus when adding
        RULE forall d. g Int d = g_spec
also add
        RULE f g_spec = 0

But that's a bit complicated.  For now we ask the programmer's help,
by *copying the INLINE activation pragma* to the auto-specialised
rule.  So if g says {-# NOINLINE[2] g #-}, then the auto-spec rule
will also not be active until phase 2.  And that's what programmers
should jolly well do anyway, even aside from specialisation, to ensure
that g doesn't inline too early.

This in turn means that the RULE would never fire for a NOINLINE
thing so not much point in generating a specialisation at all.

Note [Specialisation shape]
~~~~~~~~~~~~~~~~~~~~~~~~~~~
We only specialise a function if it has visible top-level lambdas
corresponding to its overloading.  E.g. if
        f :: forall a. Eq a => ....
then its body must look like
        f = /\a. \d. ...

Reason: when specialising the body for a call (f ty dexp), we want to
substitute dexp for d, and pick up specialised calls in the body of f.

This doesn't always work.  One example I came across was this:
        newtype Gen a = MkGen{ unGen :: Int -> a }

        choose :: Eq a => a -> Gen a
        choose n = MkGen (\r -> n)

        oneof = choose (1::Int)

It's a silly example, but we get
        choose = /\a. g `cast` co
where choose doesn't have any dict arguments.  Thus far I have not
tried to fix this (wait till there's a real example).

Mind you, then 'choose' will be inlined (since RHS is trivial) so
it doesn't matter.  This comes up with single-method classes

   class C a where { op :: a -> a }
   instance C a => C [a] where ....
==>
   $fCList :: C a => C [a]
   $fCList = $copList |> (...coercion>...)
   ....(uses of $fCList at particular types)...

So we suppress the WARN if the rhs is trivial.

Note [Inline specialisations]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Here is what we do with the InlinePragma of the original function
  * Activation/RuleMatchInfo: both transferred to the
                              specialised function
  * InlineSpec:
       (a) An INLINE pragma is transferred
       (b) An INLINABLE pragma is *not* transferred

Why (a): transfer INLINE pragmas? The point of INLINE was precisely to
specialise the function at its call site, and arguably that's not so
important for the specialised copies.  BUT *pragma-directed*
specialisation now takes place in the typechecker/desugarer, with
manually specified INLINEs.  The specialisation here is automatic.
It'd be very odd if a function marked INLINE was specialised (because
of some local use), and then forever after (including importing
modules) the specialised version wasn't INLINEd.  After all, the
programmer said INLINE!

You might wonder why we specialise INLINE functions at all.  After
all they should be inlined, right?  Two reasons:

 * Even INLINE functions are sometimes not inlined, when they aren't
   applied to interesting arguments.  But perhaps the type arguments
   alone are enough to specialise (even though the args are too boring
   to trigger inlining), and it's certainly better to call the
   specialised version.

 * The RHS of an INLINE function might call another overloaded function,
   and we'd like to generate a specialised version of that function too.
   This actually happens a lot. Consider
      replicateM_ :: (Monad m) => Int -> m a -> m ()
      {-# INLINABLE replicateM_ #-}
      replicateM_ d x ma = ...
   The strictness analyser may transform to
      replicateM_ :: (Monad m) => Int -> m a -> m ()
      {-# INLINE replicateM_ #-}
      replicateM_ d x ma = case x of I# x' -> $wreplicateM_ d x' ma

      $wreplicateM_ :: (Monad m) => Int# -> m a -> m ()
      {-# INLINABLE $wreplicateM_ #-}
      $wreplicateM_ = ...
   Now an importing module has a specialised call to replicateM_, say
   (replicateM_ dMonadIO).  We certainly want to specialise $wreplicateM_!
   This particular example had a huge effect on the call to replicateM_
   in nofib/shootout/n-body.

Why (b): discard INLINABLE pragmas? See #4874 for persuasive examples.
Suppose we have
    {-# INLINABLE f #-}
    f :: Ord a => [a] -> Int
    f xs = letrec f' = ...f'... in f'
Then, when f is specialised and optimised we might get
    wgo :: [Int] -> Int#
    wgo = ...wgo...
    f_spec :: [Int] -> Int
    f_spec xs = case wgo xs of { r -> I# r }
and we clearly want to inline f_spec at call sites.  But if we still
have the big, un-optimised of f (albeit specialised) captured in an
INLINABLE pragma for f_spec, we won't get that optimisation.

So we simply drop INLINABLE pragmas when specialising. It's not really
a complete solution; ignoring specialisation for now, INLINABLE functions
don't get properly strictness analysed, for example. But it works well
for examples involving specialisation, which is the dominant use of
INLINABLE.  See #4874.
-}

{- *********************************************************************
*                                                                      *
                   SpecArg, and specHeader
*                                                                      *
********************************************************************* -}

-- | An argument that we might want to specialise.
-- See Note [Specialising Calls] for the nitty gritty details.
data SpecArg
  =
    -- | Type arguments that should be specialised, due to appearing
    -- free in the type of a 'SpecDict'.
    SpecType Type

    -- | Type arguments that should remain polymorphic.
  | UnspecType

    -- | Dictionaries that should be specialised. mkCallUDs ensures
    -- that only "interesting" dictionary arguments get a SpecDict;
    -- see Note [Interesting dictionary arguments]
  | SpecDict DictExpr

    -- | Value arguments that should not be specialised.
  | UnspecArg

instance Outputable SpecArg where
  ppr (SpecType t) = text "SpecType" <+> ppr t
  ppr UnspecType   = text "UnspecType"
  ppr (SpecDict d) = text "SpecDict" <+> ppr d
  ppr UnspecArg    = text "UnspecArg"

specArgFreeVars :: SpecArg -> VarSet
specArgFreeVars (SpecType ty) = tyCoVarsOfType ty
specArgFreeVars (SpecDict dx) = exprFreeVars dx
specArgFreeVars UnspecType    = emptyVarSet
specArgFreeVars UnspecArg     = emptyVarSet

isSpecDict :: SpecArg -> Bool
isSpecDict (SpecDict {}) = True
isSpecDict _             = False

-- | Given binders from an original function 'f', and the 'SpecArg's
-- corresponding to its usage, compute everything necessary to build
-- a specialisation.
--
-- We will use the running example from Note [Specialising Calls]:
--
--     f :: forall a b c. Int -> Eq a => Show b => c -> Blah
--     f @a @b @c i dEqA dShowA x = blah
--
-- Suppose we decide to specialise it at the following pattern:
--
--     [ SpecType T1, SpecType T2, UnspecType, UnspecArg
--     , SpecDict dEqT1, SpecDict ($dfShow dShowT2), UnspecArg ]
--
-- We'd eventually like to build the RULE
--
--     RULE "SPEC f @T1 @T2 _"
--       forall (@c :: Type) (i :: Int) (d1 :: Eq T1) (d2 :: Show T2).
--         f @T1 @T2 @c i d1 d2 = $sf @c i
--
-- and the specialisation '$sf'
--
--     $sf :: forall c. Int -> c -> Blah
--     $sf = SUBST[a :-> T1, b :-> T2, dEqA :-> dEqT1, dShowA :-> dShow1] (\@c i x -> blah)
--
-- where dShow1 is a floated binding created by bindAuxiliaryDict.
--
-- The cases for 'specHeader' below are presented in the same order as this
-- running example. The result of 'specHeader' for this example is as follows:
--
--    ( -- Returned arguments
--      env + [a :-> T1, b :-> T2, dEqA :-> dEqT1, dShowA :-> dShow1]
--    , [x]
--
--      -- RULE helpers
--    , [c, i, d1, d2]
--    , [T1, T2, c, i, d1, d2]
--
--      -- Specialised function helpers
--    , [c, i, x]
--    , [dShow1 = $dfShow dShowT2]
--    , [T1, T2, c, i, dEqT1, dShow1]
--    )
specHeader
     :: SpecEnv
     -> [InBndr]    -- The binders from the original function 'f'
     -> [SpecArg]   -- From the CallInfo
     -> SpecM ( Bool     -- True <=> some useful specialisation happened
                         -- Not the same as any (isSpecDict args) because
                         -- the args might be longer than bndrs

                -- Returned arguments
              , SpecEnv      -- Substitution to apply to the body of 'f'
              , [OutBndr]    -- Leftover binders from the original function 'f'
                             --   that don’t have a corresponding SpecArg

                -- RULE helpers
              , [OutBndr]    -- Binders for the RULE
              , [OutExpr]    -- Args for the LHS of the rule

                -- Specialised function helpers
              , [OutBndr]    -- Binders for $sf
              , [DictBind]   -- Auxiliary dictionary bindings
              , [OutExpr]    -- Specialised arguments for unfolding
                             -- Same length as "args for LHS of rule"
              )

-- We want to specialise on type 'T1', and so we must construct a substitution
-- 'a->T1', as well as a LHS argument for the resulting RULE and unfolding
-- details.
specHeader env (bndr : bndrs) (SpecType t : args)
  = do { let env' = extendTvSubstList env [(bndr, t)]
       ; (useful, env'', leftover_bndrs, rule_bs, rule_es, bs', dx, spec_args)
            <- specHeader env' bndrs args
       ; pure ( useful
              , env''
              , leftover_bndrs
              , rule_bs
              , Type t : rule_es
              , bs'
              , dx
              , Type t : spec_args
              )
       }

-- Next we have a type that we don't want to specialise. We need to perform
-- a substitution on it (in case the type refers to 'a'). Additionally, we need
-- to produce a binder, LHS argument and RHS argument for the resulting rule,
-- /and/ a binder for the specialised body.
specHeader env (bndr : bndrs) (UnspecType : args)
  = do { let (env', bndr') = substBndr env bndr
       ; (useful, env'', leftover_bndrs, rule_bs, rule_es, bs', dx, spec_args)
            <- specHeader env' bndrs args
       ; pure ( useful
              , env''
              , leftover_bndrs
              , bndr' : rule_bs
              , varToCoreExpr bndr' : rule_es
              , bndr' : bs'
              , dx
              , varToCoreExpr bndr' : spec_args
              )
       }

-- Next we want to specialise the 'Eq a' dict away. We need to construct
-- a wildcard binder to match the dictionary (See Note [Specialising Calls] for
-- the nitty-gritty), as a LHS rule and unfolding details.
specHeader env (bndr : bndrs) (SpecDict d : args)
  = do { bndr' <- newDictBndr env bndr -- See Note [Zap occ info in rule binders]
       ; let (env', dx_bind, spec_dict) = bindAuxiliaryDict env bndr bndr' d
       ; (_, env'', leftover_bndrs, rule_bs, rule_es, bs', dx, spec_args)
             <- specHeader env' bndrs args
       ; pure ( True      -- Ha!  A useful specialisation!
              , env''
              , leftover_bndrs
              -- See Note [Evidence foralls]
              , exprFreeIdsList (varToCoreExpr bndr') ++ rule_bs
              , varToCoreExpr bndr' : rule_es
              , bs'
              , maybeToList dx_bind ++ dx
              , spec_dict : spec_args
              )
       }

-- Finally, we have the unspecialised argument 'i'. We need to produce
-- a binder, LHS and RHS argument for the RULE, and a binder for the
-- specialised body.
--
-- NB: Calls to 'specHeader' will trim off any trailing 'UnspecArg's, which is
-- why 'i' doesn't appear in our RULE above. But we have no guarantee that
-- there aren't 'UnspecArg's which come /before/ all of the dictionaries, so
-- this case must be here.
specHeader env (bndr : bndrs) (UnspecArg : args)
  = do { -- see Note [Zap occ info in rule binders]
         let (env', bndr') = substBndr env (zapIdOccInfo bndr)
       ; (useful, env'', leftover_bndrs, rule_bs, rule_es, bs', dx, spec_args)
             <- specHeader env' bndrs args
       ; pure ( useful
              , env''
              , leftover_bndrs
              , bndr' : rule_bs
              , varToCoreExpr bndr' : rule_es
              , if isDeadBinder bndr
                  then bs' -- see Note [Drop dead args from specialisations]
                  else bndr' : bs'
              , dx
              , varToCoreExpr bndr' : spec_args
              )
       }

-- If we run out of binders, stop immediately
-- See Note [Specialisation Must Preserve Sharing]
specHeader env [] _ = pure (False, env, [], [], [], [], [], [])

-- Return all remaining binders from the original function. These have the
-- invariant that they should all correspond to unspecialised arguments, so
-- it's safe to stop processing at this point.
specHeader env bndrs []
  = pure (False, env', bndrs', [], [], [], [], [])
  where
    (env', bndrs') = substBndrs env bndrs


-- | Binds a dictionary argument to a fresh name, to preserve sharing
bindAuxiliaryDict
  :: SpecEnv
  -> InId -> OutId -> OutExpr -- Original dict binder, and the witnessing expression
  -> ( SpecEnv        -- Substitute for orig_dict_id
     , Maybe DictBind -- Auxiliary dict binding, if any
     , OutExpr)        -- Witnessing expression (always trivial)
bindAuxiliaryDict env@(SE { se_subst = subst, se_interesting = interesting })
                  orig_dict_id fresh_dict_id dict_expr

  -- If the dictionary argument is trivial,
  -- don’t bother creating a new dict binding; just substitute
  | Just dict_id <- getIdFromTrivialExpr_maybe dict_expr
  = let env' = env { se_subst = Core.extendSubst subst orig_dict_id dict_expr
                                `Core.extendInScope` dict_id
                          -- See Note [Keep the old dictionaries interesting]
                   , se_interesting = interesting `extendVarSet` dict_id }
    in (env', Nothing, dict_expr)

  | otherwise  -- Non-trivial dictionary arg; make an auxiliary binding
  = let dict_bind = mkDB (NonRec fresh_dict_id dict_expr)
        env' = env { se_subst = Core.extendSubst subst orig_dict_id (Var fresh_dict_id)
                                `Core.extendInScope` fresh_dict_id
                      -- See Note [Make the new dictionaries interesting]
                   , se_interesting = interesting `extendVarSet` fresh_dict_id }
    in (env', Just dict_bind, Var fresh_dict_id)

{-
Note [Make the new dictionaries interesting]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Important!  We're going to substitute dx_id1 for d
and we want it to look "interesting", else we won't gather *any*
consequential calls. E.g.
    f d = ...g d....
If we specialise f for a call (f (dfun dNumInt)), we'll get
a consequent call (g d') with an auxiliary definition
    d' = df dNumInt
We want that consequent call to look interesting

Note [Keep the old dictionaries interesting]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
In bindAuxiliaryDict, we don’t bother creating a new dict binding if
the dict expression is trivial. For example, if we have

    f = \ @m1 (d1 :: Monad m1) -> ...

and we specialize it at the pattern

    [SpecType IO, SpecArg $dMonadIO]

it would be silly to create a new binding for $dMonadIO; it’s already
a binding! So we just extend the substitution directly:

    m1 :-> IO
    d1 :-> $dMonadIO

But this creates a new subtlety: the dict expression might be a dict
binding we floated out while specializing another function. For
example, we might have

    d2 = $p1Monad $dMonadIO -- floated out by bindAuxiliaryDict
    $sg = h @IO d2
    h = \ @m2 (d2 :: Applicative m2) -> ...

and end up specializing h at the following pattern:

    [SpecType IO, SpecArg d2]

When we created the d2 binding in the first place, we locally marked
it as interesting while specializing g as described above by
Note [Make the new dictionaries interesting]. But when we go to
specialize h, it isn’t in the SpecEnv anymore, so we’ve lost the
knowledge that we should specialize on it.

To fix this, we have to explicitly add d2 *back* to the interesting
set. That way, it will still be considered interesting while
specializing the body of h. See !2913.
-}


{- *********************************************************************
*                                                                      *
            UsageDetails and suchlike
*                                                                      *
********************************************************************* -}

data UsageDetails
  = MkUD {
      ud_binds :: !(Bag DictBind),
               -- See Note [Floated dictionary bindings]
               -- The order is important;
               -- in ds1 `union` ds2, bindings in ds2 can depend on those in ds1
               -- (Remember, Bags preserve order in GHC.)

      ud_calls :: !CallDetails

      -- INVARIANT: suppose bs = bindersOf ud_binds
      -- Then 'calls' may *mention* 'bs',
      -- but there should be no calls *for* bs
    }

-- | A 'DictBind' is a binding along with a cached set containing its free
-- variables (both type variables and dictionaries)
type DictBind = (CoreBind, VarSet)

{- Note [Floated dictionary bindings]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We float out dictionary bindings for the reasons described under
"Dictionary floating" above.  But not /just/ dictionary bindings.
Consider

   f :: Eq a => blah
   f a d = rhs

   $c== :: T -> T -> Bool
   $c== x y = ...

   $df :: Eq T
   $df = Eq $c== ...

   gurgle = ...(f @T $df)...

We gather the call info for (f @T $df), and we don't want to drop it
when we come across the binding for $df.  So we add $df to the floats
and continue.  But then we have to add $c== to the floats, and so on.
These all float above the binding for 'f', and and now we can
successfully specialise 'f'.

So the DictBinds in (ud_binds :: Bag DictBind) may contain
non-dictionary bindings too.
-}

instance Outputable UsageDetails where
  ppr (MkUD { ud_binds = dbs, ud_calls = calls })
        = text "MkUD" <+> braces (sep (punctuate comma
                [text "binds" <+> equals <+> ppr dbs,
                 text "calls" <+> equals <+> ppr calls]))

emptyUDs :: UsageDetails
emptyUDs = MkUD { ud_binds = emptyBag, ud_calls = emptyDVarEnv }

------------------------------------------------------------
type CallDetails  = DIdEnv CallInfoSet
  -- The order of specialized binds and rules depends on how we linearize
  -- CallDetails, so to get determinism we must use a deterministic set here.
  -- See Note [Deterministic UniqFM] in UniqDFM

data CallInfoSet = CIS Id (Bag CallInfo)
  -- The list of types and dictionaries is guaranteed to
  -- match the type of f
  -- The Bag may contain duplicate calls (i.e. f @T and another f @T)
  -- These dups are eliminated by already_covered in specCalls

data CallInfo
  = CI { ci_key  :: [SpecArg]   -- All arguments
       , ci_fvs  :: VarSet      -- Free vars of the ci_key
                                -- call (including tyvars)
                                -- [*not* include the main id itself, of course]
    }

type DictExpr = CoreExpr

ciSetFilter :: (CallInfo -> Bool) -> CallInfoSet -> CallInfoSet
ciSetFilter p (CIS id a) = CIS id (filterBag p a)

instance Outputable CallInfoSet where
  ppr (CIS fn map) = hang (text "CIS" <+> ppr fn)
                        2 (ppr map)

pprCallInfo :: Id -> CallInfo -> SDoc
pprCallInfo fn (CI { ci_key = key })
  = ppr fn <+> ppr key

ppr_call_key_ty :: SpecArg -> Maybe SDoc
ppr_call_key_ty (SpecType ty) = Just $ char '@' <+> pprParendType ty
ppr_call_key_ty UnspecType    = Just $ char '_'
ppr_call_key_ty (SpecDict _)  = Nothing
ppr_call_key_ty UnspecArg     = Nothing

instance Outputable CallInfo where
  ppr (CI { ci_key = key, ci_fvs = fvs })
    = text "CI" <> braces (hsep [ fsep (mapMaybe ppr_call_key_ty key), ppr fvs ])

unionCalls :: CallDetails -> CallDetails -> CallDetails
unionCalls c1 c2 = plusDVarEnv_C unionCallInfoSet c1 c2

unionCallInfoSet :: CallInfoSet -> CallInfoSet -> CallInfoSet
unionCallInfoSet (CIS f calls1) (CIS _ calls2) =
  CIS f (calls1 `unionBags` calls2)

callDetailsFVs :: CallDetails -> VarSet
callDetailsFVs calls =
  nonDetFoldUDFM (unionVarSet . callInfoFVs) emptyVarSet calls
  -- It's OK to use nonDetFoldUDFM here because we forget the ordering
  -- immediately by converting to a nondeterministic set.

callInfoFVs :: CallInfoSet -> VarSet
callInfoFVs (CIS _ call_info) =
  foldr (\(CI { ci_fvs = fv }) vs -> unionVarSet fv vs) emptyVarSet call_info

getTheta :: [TyCoBinder] -> [PredType]
getTheta = fmap tyBinderType . filter isInvisibleBinder . filter (not . isNamedBinder)


------------------------------------------------------------
singleCall :: Id -> [SpecArg] -> UsageDetails
singleCall id args
  = MkUD {ud_binds = emptyBag,
          ud_calls = unitDVarEnv id $ CIS id $
                     unitBag (CI { ci_key  = args -- used to be tys
                                 , ci_fvs  = call_fvs }) }
  where
    call_fvs = foldr (unionVarSet . specArgFreeVars) emptyVarSet args
        -- The type args (tys) are guaranteed to be part of the dictionary
        -- types, because they are just the constrained types,
        -- and the dictionary is therefore sure to be bound
        -- inside the binding for any type variables free in the type;
        -- hence it's safe to neglect tyvars free in tys when making
        -- the free-var set for this call
        -- BUT I don't trust this reasoning; play safe and include tys_fvs
        --
        -- We don't include the 'id' itself.

mkCallUDs, mkCallUDs' :: SpecEnv -> Id -> [CoreExpr] -> UsageDetails
mkCallUDs env f args
  = -- pprTrace "mkCallUDs" (vcat [ ppr f, ppr args, ppr res ])
    res
  where
    res = mkCallUDs' env f args

mkCallUDs' env f args
  |  not (want_calls_for f)  -- Imported from elsewhere
  || null ci_key             -- No useful specialisation
   -- See also Note [Specialisations already covered]
  = -- pprTrace "mkCallUDs: discarding" _trace_doc
    emptyUDs

  | otherwise
  = -- pprTrace "mkCallUDs: keeping" _trace_doc
    singleCall f ci_key
  where
    _trace_doc = vcat [ppr f, ppr args, ppr ci_key]
    pis                = fst $ splitPiTys $ idType f
    constrained_tyvars = tyCoVarsOfTypes $ getTheta pis

    ci_key :: [SpecArg]
    ci_key = dropWhileEndLE (not . isSpecDict) $
             zipWith mk_spec_arg args pis
             -- Drop trailing args until we get to a SpecDict
             -- In this way the RULE has as few args as possible,
             -- which broadens its applicability, since rules only
             -- fire when saturated

    mk_spec_arg :: CoreExpr -> TyCoBinder -> SpecArg
    mk_spec_arg arg (Named bndr)
      |  binderVar bndr `elemVarSet` constrained_tyvars
      = case arg of
          Type ty -> SpecType ty
          _       -> pprPanic "ci_key" $ ppr arg
      |  otherwise = UnspecType

    -- For "InvisArg", which are the type-class dictionaries,
    -- we decide on a case by case basis if we want to specialise
    -- on this argument; if so, SpecDict, if not UnspecArg
    mk_spec_arg arg (Anon InvisArg pred)
      | type_determines_value pred
      , interestingDict env arg -- Note [Interesting dictionary arguments]
      = SpecDict arg
      | otherwise = UnspecArg

    mk_spec_arg _ (Anon VisArg _)
      = UnspecArg

    want_calls_for f = isLocalId f || isJust (maybeUnfoldingTemplate (realIdUnfolding f))
         -- For imported things, we gather call instances if
         -- there is an unfolding that we could in principle specialise
         -- We might still decide not to use it (consulting dflags)
         -- in specImports
         -- Use 'realIdUnfolding' to ignore the loop-breaker flag!

    type_determines_value pred    -- See Note [Type determines value]
        = case classifyPredType pred of
            ClassPred cls _ -> not (isIPClass cls)  -- Superclasses can't be IPs
            EqPred {}       -> True
            IrredPred {}    -> True   -- Things like (D []) where D is a
                                      -- Constraint-ranged family; #7785
            ForAllPred {}   -> True

{-
Note [Type determines value]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Only specialise on non-IP *class* params, because these are the ones
whose *type* determines their *value*.  In particular, with implicit
params, the type args *don't* say what the value of the implicit param
is!  See #7101.

So we treat implicit params just like ordinary arguments for the
purposes of specialisation.  Note that we still want to specialise
functions with implicit params if they have *other* dicts which are
class params; see #17930.

One apparent additional complexity involves type families. For
example, consider
         type family D (v::*->*) :: Constraint
         type instance D [] = ()
         f :: D v => v Char -> Int
If we see a call (f "foo"), we'll pass a "dictionary"
  () |> (g :: () ~ D [])
and it's good to specialise f at this dictionary.

So the question is: can an implicit parameter "hide inside" a
type-family constraint like (D a).  Well, no.  We don't allow
        type instance D Maybe = ?x:Int
Hence the IrredPred case in type_determines_value.  See #7785.

Note [Interesting dictionary arguments]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Consider this
         \a.\d:Eq a.  let f = ... in ...(f d)...
There really is not much point in specialising f wrt the dictionary d,
because the code for the specialised f is not improved at all, because
d is lambda-bound.  We simply get junk specialisations.

What is "interesting"?  Just that it has *some* structure.  But what about
variables?

 * A variable might be imported, in which case its unfolding
   will tell us whether it has useful structure

 * Local variables are cloned on the way down (to avoid clashes when
   we float dictionaries), and cloning drops the unfolding
   (cloneIdBndr).  Moreover, we make up some new bindings, and it's a
   nuisance to give them unfoldings.  So we keep track of the
   "interesting" dictionaries as a VarSet in SpecEnv.
   We have to take care to put any new interesting dictionary
   bindings in the set.

We accidentally lost accurate tracking of local variables for a long
time, because cloned variables don't have unfoldings. But makes a
massive difference in a few cases, eg #5113. For nofib as a
whole it's only a small win: 2.2% improvement in allocation for ansi,
1.2% for bspt, but mostly 0.0!  Average 0.1% increase in binary size.
-}

interestingDict :: SpecEnv -> CoreExpr -> Bool
-- A dictionary argument is interesting if it has *some* structure
-- NB: "dictionary" arguments include constraints of all sorts,
--     including equality constraints; hence the Coercion case
interestingDict env (Var v) =  hasSomeUnfolding (idUnfolding v)
                            || isDataConWorkId v
                            || v `elemVarSet` se_interesting env
interestingDict _ (Type _)                = False
interestingDict _ (Coercion _)            = False
interestingDict env (App fn (Type _))     = interestingDict env fn
interestingDict env (App fn (Coercion _)) = interestingDict env fn
interestingDict env (Tick _ a)            = interestingDict env a
interestingDict env (Cast e _)            = interestingDict env e
interestingDict _ _                       = True

plusUDs :: UsageDetails -> UsageDetails -> UsageDetails
plusUDs (MkUD {ud_binds = db1, ud_calls = calls1})
        (MkUD {ud_binds = db2, ud_calls = calls2})
  = MkUD { ud_binds = db1    `unionBags`   db2
         , ud_calls = calls1 `unionCalls`  calls2 }

-----------------------------
_dictBindBndrs :: Bag DictBind -> [Id]
_dictBindBndrs dbs = foldr ((++) . bindersOf . fst) [] dbs

-- | Construct a 'DictBind' from a 'CoreBind'
mkDB :: CoreBind -> DictBind
mkDB bind = (bind, bind_fvs bind)

-- | Identify the free variables of a 'CoreBind'
bind_fvs :: CoreBind -> VarSet
bind_fvs (NonRec bndr rhs) = pair_fvs (bndr,rhs)
bind_fvs (Rec prs)         = foldl' delVarSet rhs_fvs bndrs
                           where
                             bndrs = map fst prs
                             rhs_fvs = unionVarSets (map pair_fvs prs)

pair_fvs :: (Id, CoreExpr) -> VarSet
pair_fvs (bndr, rhs) = exprSomeFreeVars interesting rhs
                       `unionVarSet` idFreeVars bndr
        -- idFreeVars: don't forget variables mentioned in
        -- the rules of the bndr.  C.f. OccAnal.addRuleUsage
        -- Also tyvars mentioned in its type; they may not appear
        -- in the RHS
        --      type T a = Int
        --      x :: T a = 3
  where
    interesting :: InterestingVarFun
    interesting v = isLocalVar v || (isId v && isDFunId v)
        -- Very important: include DFunIds /even/ if it is imported
        -- Reason: See Note [Avoiding loops], the second exmaple
        --         involving an imported dfun.  We must know whether
        --         a dictionary binding depends on an imported dfun,
        --         in case we try to specialise that imported dfun
        --         #13429 illustrates

-- | Flatten a set of "dumped" 'DictBind's, and some other binding
-- pairs, into a single recursive binding.
recWithDumpedDicts :: [(Id,CoreExpr)] -> Bag DictBind ->DictBind
recWithDumpedDicts pairs dbs
  = (Rec bindings, fvs)
  where
    (bindings, fvs) = foldr add
                               ([], emptyVarSet)
                               (dbs `snocBag` mkDB (Rec pairs))
    add (NonRec b r, fvs') (pairs, fvs) =
      ((b,r) : pairs, fvs `unionVarSet` fvs')
    add (Rec prs1,   fvs') (pairs, fvs) =
      (prs1 ++ pairs, fvs `unionVarSet` fvs')

snocDictBinds :: UsageDetails -> [DictBind] -> UsageDetails
-- Add ud_binds to the tail end of the bindings in uds
snocDictBinds uds dbs
  = uds { ud_binds = ud_binds uds `unionBags` listToBag dbs }

consDictBind :: DictBind -> UsageDetails -> UsageDetails
consDictBind bind uds = uds { ud_binds = bind `consBag` ud_binds uds }

addDictBinds :: [DictBind] -> UsageDetails -> UsageDetails
addDictBinds binds uds = uds { ud_binds = listToBag binds `unionBags` ud_binds uds }

snocDictBind :: UsageDetails -> DictBind -> UsageDetails
snocDictBind uds bind = uds { ud_binds = ud_binds uds `snocBag` bind }

wrapDictBinds :: Bag DictBind -> [CoreBind] -> [CoreBind]
wrapDictBinds dbs binds
  = foldr add binds dbs
  where
    add (bind,_) binds = bind : binds

wrapDictBindsE :: Bag DictBind -> CoreExpr -> CoreExpr
wrapDictBindsE dbs expr
  = foldr add expr dbs
  where
    add (bind,_) expr = Let bind expr

----------------------
dumpUDs :: [CoreBndr] -> UsageDetails -> (UsageDetails, Bag DictBind)
-- Used at a lambda or case binder; just dump anything mentioning the binder
dumpUDs bndrs uds@(MkUD { ud_binds = orig_dbs, ud_calls = orig_calls })
  | null bndrs = (uds, emptyBag)  -- Common in case alternatives
  | otherwise  = -- pprTrace "dumpUDs" (ppr bndrs $$ ppr free_uds $$ ppr dump_dbs) $
                 (free_uds, dump_dbs)
  where
    free_uds = MkUD { ud_binds = free_dbs, ud_calls = free_calls }
    bndr_set = mkVarSet bndrs
    (free_dbs, dump_dbs, dump_set) = splitDictBinds orig_dbs bndr_set
    free_calls = deleteCallsMentioning dump_set $   -- Drop calls mentioning bndr_set on the floor
                 deleteCallsFor bndrs orig_calls    -- Discard calls for bndr_set; there should be
                                                    -- no calls for any of the dicts in dump_dbs

dumpBindUDs :: [CoreBndr] -> UsageDetails -> (UsageDetails, Bag DictBind, Bool)
-- Used at a let(rec) binding.
-- We return a boolean indicating whether the binding itself is mentioned,
-- directly or indirectly, by any of the ud_calls; in that case we want to
-- float the binding itself;
-- See Note [Floated dictionary bindings]
dumpBindUDs bndrs (MkUD { ud_binds = orig_dbs, ud_calls = orig_calls })
  = -- pprTrace "dumpBindUDs" (ppr bndrs $$ ppr free_uds $$ ppr dump_dbs) $
    (free_uds, dump_dbs, float_all)
  where
    free_uds = MkUD { ud_binds = free_dbs, ud_calls = free_calls }
    bndr_set = mkVarSet bndrs
    (free_dbs, dump_dbs, dump_set) = splitDictBinds orig_dbs bndr_set
    free_calls = deleteCallsFor bndrs orig_calls
    float_all = dump_set `intersectsVarSet` callDetailsFVs free_calls

callsForMe :: Id -> UsageDetails -> (UsageDetails, [CallInfo])
callsForMe fn (MkUD { ud_binds = orig_dbs, ud_calls = orig_calls })
  = -- pprTrace ("callsForMe")
    --          (vcat [ppr fn,
    --                 text "Orig dbs ="     <+> ppr (_dictBindBndrs orig_dbs),
    --                 text "Orig calls ="   <+> ppr orig_calls,
    --                 text "Dep set ="      <+> ppr dep_set,
    --                 text "Calls for me =" <+> ppr calls_for_me]) $
    (uds_without_me, calls_for_me)
  where
    uds_without_me = MkUD { ud_binds = orig_dbs
                          , ud_calls = delDVarEnv orig_calls fn }
    calls_for_me = case lookupDVarEnv orig_calls fn of
                        Nothing -> []
                        Just cis -> filterCalls cis orig_dbs
         -- filterCalls: drop calls that (directly or indirectly)
         -- refer to fn.  See Note [Avoiding loops]

----------------------
filterCalls :: CallInfoSet -> Bag DictBind -> [CallInfo]
-- See Note [Avoiding loops]
filterCalls (CIS fn call_bag) dbs
  = filter ok_call (bagToList call_bag)
  where
    dump_set = foldl' go (unitVarSet fn) dbs
      -- This dump-set could also be computed by splitDictBinds
      --   (_,_,dump_set) = splitDictBinds dbs {fn}
      -- But this variant is shorter

    go so_far (db,fvs) | fvs `intersectsVarSet` so_far
                       = extendVarSetList so_far (bindersOf db)
                       | otherwise = so_far

    ok_call (CI { ci_fvs = fvs }) = not (fvs `intersectsVarSet` dump_set)

----------------------
splitDictBinds :: Bag DictBind -> IdSet -> (Bag DictBind, Bag DictBind, IdSet)
-- splitDictBinds dbs bndrs returns
--   (free_dbs, dump_dbs, dump_set)
-- where
--   * dump_dbs depends, transitively on bndrs
--   * free_dbs does not depend on bndrs
--   * dump_set = bndrs `union` bndrs(dump_dbs)
splitDictBinds dbs bndr_set
   = foldl' split_db (emptyBag, emptyBag, bndr_set) dbs
                -- Important that it's foldl' not foldr;
                -- we're accumulating the set of dumped ids in dump_set
   where
    split_db (free_dbs, dump_dbs, dump_idset) db@(bind, fvs)
        | dump_idset `intersectsVarSet` fvs     -- Dump it
        = (free_dbs, dump_dbs `snocBag` db,
           extendVarSetList dump_idset (bindersOf bind))

        | otherwise     -- Don't dump it
        = (free_dbs `snocBag` db, dump_dbs, dump_idset)


----------------------
deleteCallsMentioning :: VarSet -> CallDetails -> CallDetails
-- Remove calls *mentioning* bs in any way
deleteCallsMentioning bs calls
  = mapDVarEnv (ciSetFilter keep_call) calls
  where
    keep_call (CI { ci_fvs = fvs }) = not (fvs `intersectsVarSet` bs)

deleteCallsFor :: [Id] -> CallDetails -> CallDetails
-- Remove calls *for* bs
deleteCallsFor bs calls = delDVarEnvList calls bs

{-
************************************************************************
*                                                                      *
\subsubsection{Boring helper functions}
*                                                                      *
************************************************************************
-}

newtype SpecM a = SpecM (State SpecState a) deriving (Functor)

data SpecState = SpecState {
                     spec_uniq_supply :: UniqSupply,
                     spec_module :: Module,
                     spec_dflags :: DynFlags
                 }

instance Applicative SpecM where
    pure x = SpecM $ return x
    (<*>) = ap

instance Monad SpecM where
    SpecM x >>= f = SpecM $ do y <- x
                               case f y of
                                   SpecM z ->
                                       z
#if !MIN_VERSION_base(4,13,0)
    fail = MonadFail.fail
#endif

instance MonadFail.MonadFail SpecM where
   fail str = SpecM $ error str

instance MonadUnique SpecM where
    getUniqueSupplyM
        = SpecM $ do st <- get
                     let (us1, us2) = splitUniqSupply $ spec_uniq_supply st
                     put $ st { spec_uniq_supply = us2 }
                     return us1

    getUniqueM
        = SpecM $ do st <- get
                     let (u,us') = takeUniqFromSupply $ spec_uniq_supply st
                     put $ st { spec_uniq_supply = us' }
                     return u

instance HasDynFlags SpecM where
    getDynFlags = SpecM $ liftM spec_dflags get

instance HasModule SpecM where
    getModule = SpecM $ liftM spec_module get

runSpecM :: DynFlags -> Module -> SpecM a -> CoreM a
runSpecM dflags this_mod (SpecM spec)
    = do us <- getUniqueSupplyM
         let initialState = SpecState {
                                spec_uniq_supply = us,
                                spec_module = this_mod,
                                spec_dflags = dflags
                            }
         return $ evalState spec initialState

mapAndCombineSM :: (a -> SpecM (b, UsageDetails)) -> [a] -> SpecM ([b], UsageDetails)
mapAndCombineSM _ []     = return ([], emptyUDs)
mapAndCombineSM f (x:xs) = do (y, uds1) <- f x
                              (ys, uds2) <- mapAndCombineSM f xs
                              return (y:ys, uds1 `plusUDs` uds2)

extendTvSubstList :: SpecEnv -> [(TyVar,Type)] -> SpecEnv
extendTvSubstList env tv_binds
  = env { se_subst = Core.extendTvSubstList (se_subst env) tv_binds }

substTy :: SpecEnv -> Type -> Type
substTy env ty = Core.substTy (se_subst env) ty

substCo :: SpecEnv -> Coercion -> Coercion
substCo env co = Core.substCo (se_subst env) co

substBndr :: SpecEnv -> CoreBndr -> (SpecEnv, CoreBndr)
substBndr env bs = case Core.substBndr (se_subst env) bs of
                      (subst', bs') -> (env { se_subst = subst' }, bs')

substBndrs :: SpecEnv -> [CoreBndr] -> (SpecEnv, [CoreBndr])
substBndrs env bs = case Core.substBndrs (se_subst env) bs of
                      (subst', bs') -> (env { se_subst = subst' }, bs')

cloneBindSM :: SpecEnv -> CoreBind -> SpecM (SpecEnv, SpecEnv, CoreBind)
-- Clone the binders of the bind; return new bind with the cloned binders
-- Return the substitution to use for RHSs, and the one to use for the body
cloneBindSM env@(SE { se_subst = subst, se_interesting = interesting }) (NonRec bndr rhs)
  = do { us <- getUniqueSupplyM
       ; let (subst', bndr') = Core.cloneIdBndr subst us bndr
             interesting' | interestingDict env rhs
                          = interesting `extendVarSet` bndr'
                          | otherwise = interesting
       ; return (env, env { se_subst = subst', se_interesting = interesting' }
                , NonRec bndr' rhs) }

cloneBindSM env@(SE { se_subst = subst, se_interesting = interesting }) (Rec pairs)
  = do { us <- getUniqueSupplyM
       ; let (subst', bndrs') = Core.cloneRecIdBndrs subst us (map fst pairs)
             env' = env { se_subst = subst'
                        , se_interesting = interesting `extendVarSetList`
                                           [ v | (v,r) <- pairs, interestingDict env r ] }
       ; return (env', env', Rec (bndrs' `zip` map snd pairs)) }

newDictBndr :: SpecEnv -> CoreBndr -> SpecM CoreBndr
-- Make up completely fresh binders for the dictionaries
-- Their bindings are going to float outwards
newDictBndr env b = do { uniq <- getUniqueM
                        ; let n   = idName b
                              ty' = substTy env (idType b)
                        ; return (mkUserLocalOrCoVar (nameOccName n) uniq ty' (getSrcSpan n)) }

newSpecIdSM :: Id -> Type -> Maybe JoinArity -> SpecM Id
    -- Give the new Id a similar occurrence name to the old one
newSpecIdSM old_id new_ty join_arity_maybe
  = do  { uniq <- getUniqueM
        ; let name    = idName old_id
              new_occ = mkSpecOcc (nameOccName name)
              new_id  = mkUserLocalOrCoVar new_occ uniq new_ty (getSrcSpan name)
                          `asJoinId_maybe` join_arity_maybe
        ; return new_id }

{-
                Old (but interesting) stuff about unboxed bindings
                ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

What should we do when a value is specialised to a *strict* unboxed value?

        map_*_* f (x:xs) = let h = f x
                               t = map f xs
                           in h:t

Could convert let to case:

        map_*_Int# f (x:xs) = case f x of h# ->
                              let t = map f xs
                              in h#:t

This may be undesirable since it forces evaluation here, but the value
may not be used in all branches of the body. In the general case this
transformation is impossible since the mutual recursion in a letrec
cannot be expressed as a case.

There is also a problem with top-level unboxed values, since our
implementation cannot handle unboxed values at the top level.

Solution: Lift the binding of the unboxed value and extract it when it
is used:

        map_*_Int# f (x:xs) = let h = case (f x) of h# -> _Lift h#
                                  t = map f xs
                              in case h of
                                 _Lift h# -> h#:t

Now give it to the simplifier and the _Lifting will be optimised away.

The benefit is that we have given the specialised "unboxed" values a
very simple lifted semantics and then leave it up to the simplifier to
optimise it --- knowing that the overheads will be removed in nearly
all cases.

In particular, the value will only be evaluated in the branches of the
program which use it, rather than being forced at the point where the
value is bound. For example:

        filtermap_*_* p f (x:xs)
          = let h = f x
                t = ...
            in case p x of
                True  -> h:t
                False -> t
   ==>
        filtermap_*_Int# p f (x:xs)
          = let h = case (f x) of h# -> _Lift h#
                t = ...
            in case p x of
                True  -> case h of _Lift h#
                           -> h#:t
                False -> t

The binding for h can still be inlined in the one branch and the
_Lifting eliminated.


Question: When won't the _Lifting be eliminated?

Answer: When they at the top-level (where it is necessary) or when
inlining would duplicate work (or possibly code depending on
options). However, the _Lifting will still be eliminated if the
strictness analyser deems the lifted binding strict.
-}
