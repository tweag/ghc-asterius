/* -----------------------------------------------------------------------------
 *
 * (c) The GHC Team, 1998-2009
 *
 * Stable Pointers
 *
 * Do not #include this file directly: #include "Rts.h" instead.
 *
 * To understand the structure of the RTS headers, see the wiki:
 *   https://gitlab.haskell.org/ghc/ghc/wikis/commentary/source-tree/includes
 *
 * ---------------------------------------------------------------------------*/

#pragma once

EXTERN_INLINE StgPtr deRefStablePtr (StgStablePtr stable_ptr);
StgStablePtr getStablePtr  (StgPtr p);

/* -----------------------------------------------------------------------------
   PRIVATE from here.
   -------------------------------------------------------------------------- */

typedef struct {
    StgPtr addr;         // Haskell object when entry is in use, next free
                         // entry (NULL when this is the last free entry)
                         // otherwise.
} spEntry;

extern DLL_IMPORT_RTS spEntry *stable_ptr_table;

EXTERN_INLINE
StgPtr deRefStablePtr(StgStablePtr sp)
{
    // acquire load to ensure that we see the new SPT if it has been recently
    // enlarged.
    const spEntry *spt = ACQUIRE_LOAD(&stable_ptr_table);
    // acquire load to ensure that the referenced object is visible.
    return ACQUIRE_LOAD(&spt[(StgWord)sp].addr);
}
