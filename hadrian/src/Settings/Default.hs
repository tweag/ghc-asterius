module Settings.Default (
    -- * Packages that are build by default and for the testsuite
    defaultPackages, testsuitePackages,

    -- * Default build ways
    defaultLibraryWays, defaultRtsWays,

    -- * Default command line arguments for various builders
    SourceArgs (..), sourceArgs, defaultBuilderArgs, defaultPackageArgs,
    defaultArgs,

    -- * Default build flavour
    defaultFlavour
    ) where

import qualified Hadrian.Builder.Ar
import qualified Hadrian.Builder.Sphinx
import qualified Hadrian.Builder.Tar
import Hadrian.Haskell.Cabal.Type

import CommandLine
import Expression
import Flavour
import Oracles.Flag
import Packages
import Settings
import Settings.Builders.Alex
import Settings.Builders.DeriveConstants
import Settings.Builders.Cabal
import Settings.Builders.Cc
import Settings.Builders.Configure
import Settings.Builders.GenPrimopCode
import Settings.Builders.Ghc
import Settings.Builders.GhcPkg
import Settings.Builders.Haddock
import Settings.Builders.Happy
import Settings.Builders.Hsc2Hs
import Settings.Builders.HsCpp
import Settings.Builders.Ld
import Settings.Builders.Make
import Settings.Builders.MergeObjects
import Settings.Builders.RunTest
import Settings.Builders.Xelatex
import Settings.Packages
import Settings.Warnings

-- | Packages that are built by default. You can change this in "UserSettings".
defaultPackages :: Stage -> Action [Package]
defaultPackages Stage0 = stage0Packages
defaultPackages Stage1 = stage1Packages
defaultPackages Stage2 = stage2Packages
defaultPackages Stage3 = return []

-- | Packages built in 'Stage0' by default. You can change this in "UserSettings".
stage0Packages :: Action [Package]
stage0Packages = do
    cross <- flag CrossCompiling
    return $ [ binary
             , cabal
             , compareSizes
             , compiler
             , deriveConstants
             , genapply
             , genprimopcode
             , ghc
             , ghcBoot
             , ghcBootTh
             , ghcHeap
             , ghci
             , ghcPkg
             , hsc2hs
             , hpc
             , mtl
             , parsec
             , templateHaskell
             , text
             , transformers
             , unlit                         ]
          ++ [ terminfo | not windowsHost, not cross ]
          ++ [ timeout  | windowsHost                ]
          ++ [ touchy   | windowsHost                ]
          ++ [ hp2ps    | cross                      ]

-- | Packages built in 'Stage1' by default. You can change this in "UserSettings".
stage1Packages :: Action [Package]
stage1Packages = do
    intLib     <- integerLibrary =<< flavour
    libraries0 <- filter isLibrary <$> stage0Packages
    cross      <- flag CrossCompiling
    return $ libraries0 -- Build all Stage0 libraries in Stage1
          ++ [ array
             , base
             , bytestring
             , containers
             , deepseq
             , directory
             , exceptions
             , filepath
             , ghc
             , ghcCompact
             , ghcPkg
             , ghcPrim
             , haskeline
             , hp2ps
             , hsc2hs
             , intLib
             , pretty
             , process
             , rts
             , stm
             , time
             , unlit
             , xhtml
             ]
          ++ [ haddock  | not cross                  ]
          ++ [ hpcBin   | not cross                  ]
          ++ [ iserv    | not cross ]
          ++ [ libiserv | not cross ]
          ++ [ runGhc   | not cross                  ]
          ++ [ touchy   | windowsHost                ]
          ++ [ unix     | not windowsHost            ]
          ++ [ win32    | windowsHost                ]

-- | Packages built in 'Stage2' by default. You can change this in "UserSettings".
stage2Packages :: Action [Package]
stage2Packages = stage1Packages

-- | Packages that are built only for the testsuite.
testsuitePackages :: Action [Package]
testsuitePackages = do
    return $ [ checkApiAnnotations
             , checkPpr
             , ghci
             , ghcCompact
             , ghcPkg
             , hpcBin
             , hsc2hs
             , iserv
             , runGhc
             , unlit                 ] ++
             [ timeout | windowsHost ]

-- | Default build ways for library packages:
-- * We always build 'vanilla' way.
-- * We build 'profiling' way when stage > Stage0.
-- * We build 'dynamic' way when stage > Stage0 and the platform supports it.
defaultLibraryWays :: Ways
defaultLibraryWays = mconcat
    [ pure [vanilla]
    , notStage0 ? pure [profiling]
    , notStage0 ? platformSupportsSharedLibs ? pure [dynamic]
    ]

-- | Default build ways for the RTS.
defaultRtsWays :: Ways
defaultRtsWays = mconcat
  [ pure [vanilla, threaded]
  , notStage0 ? pure
      [ profiling, threadedProfiling, debugProfiling, threadedDebugProfiling
      , logging, threadedLogging
      , debug, threadedDebug
      ]
  , notStage0 ? platformSupportsSharedLibs ? pure
      [ dynamic, threadedDynamic, debugDynamic, loggingDynamic
      , threadedDebugDynamic, threadedLoggingDynamic
      ]
  ]

-- TODO: Move C source arguments here
-- | Default and package-specific source arguments.
data SourceArgs = SourceArgs
    { hsDefault  :: Args
    , hsLibrary  :: Args
    , hsCompiler :: Args
    , hsGhc      :: Args }

-- | Concatenate source arguments in appropriate order.
sourceArgs :: SourceArgs -> Args
sourceArgs SourceArgs {..} = builder Ghc ? mconcat
    [ hsDefault
    , getContextData hcOpts
    -- `compiler` is also a library but the specific arguments that we want
    -- to apply to that are given by the hsCompiler option. `ghc` is an
    -- executable so we don't have to exclude that.
    , libraryPackage   ? notM (packageOneOf [compiler]) ? hsLibrary
    , package compiler ? hsCompiler
    , package ghc      ? hsGhc ]

-- | All default command line arguments.
defaultArgs :: Args
defaultArgs = mconcat
    [ defaultBuilderArgs
    , sourceArgs defaultSourceArgs
    , defaultPackageArgs ]

-- | Default source arguments, e.g. optimisation settings.
defaultSourceArgs :: SourceArgs
defaultSourceArgs = SourceArgs
    { hsDefault  = mconcat [ stage0    ? arg "-O"
                           , notStage0 ? arg "-O2"
                           , arg "-H32m" ]
    , hsLibrary  = notStage0 ? arg "-haddock"
    , hsCompiler = mempty
    , hsGhc      = mempty }

-- Please update doc/flavours.md when changing the default build flavour.
-- | Default build flavour. Other build flavours are defined in modules
-- @Settings.Flavours.*@. Users can add new build flavours in "UserSettings".
defaultFlavour :: Flavour
defaultFlavour = Flavour
    { name               = "default"
    , args               = defaultArgs
    , packages           = defaultPackages
    , integerLibrary     = (\x -> if x then integerSimple else integerGmp) <$> cmdIntegerSimple
    , libraryWays        = defaultLibraryWays
    , rtsWays            = defaultRtsWays
    , dynamicGhcPrograms = defaultDynamicGhcPrograms
    , ghciWithDebugger   = False
    , ghcProfiled        = False
    , ghcDebugged        = False
    , ghcThreaded        = True
    , ghcDocs            = cmdDocsArgs }

-- | Default logic for determining whether to build
--   dynamic GHC programs.
--
--   It corresponds to the DYNAMIC_GHC_PROGRAMS logic implemented
--   in @mk/config.mk.in@.
defaultDynamicGhcPrograms :: Action Bool
defaultDynamicGhcPrograms = do
  supportsShared <- platformSupportsSharedLibs
  return (not windowsHost && supportsShared)

-- | All 'Builder'-dependent command line arguments.
defaultBuilderArgs :: Args
defaultBuilderArgs = mconcat
    -- GHC-specific builders:
    [ alexBuilderArgs
    , cabalBuilderArgs
    , ccBuilderArgs
    , configureBuilderArgs
    , deriveConstantsBuilderArgs
    , genPrimopCodeBuilderArgs
    , ghcBuilderArgs
    , ghcPkgBuilderArgs
    , haddockBuilderArgs
    , happyBuilderArgs
    , hsc2hsBuilderArgs
    , hsCppBuilderArgs
    , ldBuilderArgs
    , makeBuilderArgs
    , mergeObjectsBuilderArgs
    , runTestBuilderArgs
    , validateBuilderArgs
    , xelatexBuilderArgs
    -- Generic builders from the Hadrian library:
    , builder (Ar Pack     ) ? Hadrian.Builder.Ar.args Pack
    , builder (Ar Unpack   ) ? Hadrian.Builder.Ar.args Unpack
    , builder (Sphinx Html ) ? Hadrian.Builder.Sphinx.args Html
    , builder (Sphinx Latex) ? Hadrian.Builder.Sphinx.args Latex
    , builder (Sphinx Man  ) ? Hadrian.Builder.Sphinx.args Man
    , builder (Sphinx Info ) ? Hadrian.Builder.Sphinx.args Info
    , builder (Tar Create  ) ? Hadrian.Builder.Tar.args Create
    , builder (Tar Extract ) ? Hadrian.Builder.Tar.args Extract ]

-- | All 'Package'-dependent command line arguments.
defaultPackageArgs :: Args
defaultPackageArgs = mconcat [ packageArgs
                             , builder Ghc ? ghcWarningsArgs ]
