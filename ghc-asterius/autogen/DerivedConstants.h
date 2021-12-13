/* This file is created automatically.  Do not edit by hand.*/

#define CONTROL_GROUP_CONST_291 291
#define STD_HDR_SIZE 1
#define PROF_HDR_SIZE 2
#define STACK_DIRTY 1
#define BLOCK_SIZE 4096
#define MBLOCK_SIZE 1048576
#define BLOCKS_PER_MBLOCK 254
#define TICKY_BIN_COUNT 9
#define OFFSET_StgRegTable_rR1 0
#define OFFSET_StgRegTable_rR2 4
#define OFFSET_StgRegTable_rR3 8
#define OFFSET_StgRegTable_rR4 12
#define OFFSET_StgRegTable_rR5 16
#define OFFSET_StgRegTable_rR6 20
#define OFFSET_StgRegTable_rR7 24
#define OFFSET_StgRegTable_rR8 28
#define OFFSET_StgRegTable_rR9 32
#define OFFSET_StgRegTable_rR10 36
#define OFFSET_StgRegTable_rF1 40
#define OFFSET_StgRegTable_rF2 44
#define OFFSET_StgRegTable_rF3 48
#define OFFSET_StgRegTable_rF4 52
#define OFFSET_StgRegTable_rF5 56
#define OFFSET_StgRegTable_rF6 60
#define OFFSET_StgRegTable_rD1 64
#define OFFSET_StgRegTable_rD2 72
#define OFFSET_StgRegTable_rD3 80
#define OFFSET_StgRegTable_rD4 88
#define OFFSET_StgRegTable_rD5 96
#define OFFSET_StgRegTable_rD6 104
#define OFFSET_StgRegTable_rXMM1 112
#define OFFSET_StgRegTable_rXMM2 128
#define OFFSET_StgRegTable_rXMM3 144
#define OFFSET_StgRegTable_rXMM4 160
#define OFFSET_StgRegTable_rXMM5 176
#define OFFSET_StgRegTable_rXMM6 192
#define OFFSET_StgRegTable_rYMM1 208
#define OFFSET_StgRegTable_rYMM2 240
#define OFFSET_StgRegTable_rYMM3 272
#define OFFSET_StgRegTable_rYMM4 304
#define OFFSET_StgRegTable_rYMM5 336
#define OFFSET_StgRegTable_rYMM6 368
#define OFFSET_StgRegTable_rZMM1 400
#define OFFSET_StgRegTable_rZMM2 464
#define OFFSET_StgRegTable_rZMM3 528
#define OFFSET_StgRegTable_rZMM4 592
#define OFFSET_StgRegTable_rZMM5 656
#define OFFSET_StgRegTable_rZMM6 720
#define OFFSET_StgRegTable_rL1 784
#define OFFSET_StgRegTable_rSp 792
#define OFFSET_StgRegTable_rSpLim 796
#define OFFSET_StgRegTable_rHp 800
#define OFFSET_StgRegTable_rHpLim 804
#define OFFSET_StgRegTable_rCCCS 808
#define OFFSET_StgRegTable_rCurrentTSO 812
#define OFFSET_StgRegTable_rCurrentNursery 820
#define OFFSET_StgRegTable_rHpAlloc 828
#define OFFSET_StgRegTable_rRet 832
#define REP_StgRegTable_rRet b32
#define StgRegTable_rRet(__ptr__) REP_StgRegTable_rRet[__ptr__+OFFSET_StgRegTable_rRet]
#define OFFSET_StgRegTable_rNursery 816
#define REP_StgRegTable_rNursery b32
#define StgRegTable_rNursery(__ptr__) REP_StgRegTable_rNursery[__ptr__+OFFSET_StgRegTable_rNursery]
#define OFFSET_stgEagerBlackholeInfo -16
#define OFFSET_stgGCEnter1 -12
#define OFFSET_stgGCFun -8
#define OFFSET_Capability_r 16
#define OFFSET_Capability_lock 1004
#define OFFSET_Capability_no 856
#define REP_Capability_no b32
#define Capability_no(__ptr__) REP_Capability_no[__ptr__+OFFSET_Capability_no]
#define OFFSET_Capability_mut_lists 900
#define REP_Capability_mut_lists b32
#define Capability_mut_lists(__ptr__) REP_Capability_mut_lists[__ptr__+OFFSET_Capability_mut_lists]
#define OFFSET_Capability_context_switch 984
#define REP_Capability_context_switch b32
#define Capability_context_switch(__ptr__) REP_Capability_context_switch[__ptr__+OFFSET_Capability_context_switch]
#define OFFSET_Capability_interrupt 988
#define REP_Capability_interrupt b32
#define Capability_interrupt(__ptr__) REP_Capability_interrupt[__ptr__+OFFSET_Capability_interrupt]
#define OFFSET_Capability_sparks 1048
#define REP_Capability_sparks b32
#define Capability_sparks(__ptr__) REP_Capability_sparks[__ptr__+OFFSET_Capability_sparks]
#define OFFSET_Capability_total_allocated 992
#define REP_Capability_total_allocated b32
#define Capability_total_allocated(__ptr__) REP_Capability_total_allocated[__ptr__+OFFSET_Capability_total_allocated]
#define OFFSET_Capability_weak_ptr_list_hd 976
#define REP_Capability_weak_ptr_list_hd b32
#define Capability_weak_ptr_list_hd(__ptr__) REP_Capability_weak_ptr_list_hd[__ptr__+OFFSET_Capability_weak_ptr_list_hd]
#define OFFSET_Capability_weak_ptr_list_tl 980
#define REP_Capability_weak_ptr_list_tl b32
#define Capability_weak_ptr_list_tl(__ptr__) REP_Capability_weak_ptr_list_tl[__ptr__+OFFSET_Capability_weak_ptr_list_tl]
#define OFFSET_bdescr_start 0
#define REP_bdescr_start b32
#define bdescr_start(__ptr__) REP_bdescr_start[__ptr__+OFFSET_bdescr_start]
#define OFFSET_bdescr_free 4
#define REP_bdescr_free b32
#define bdescr_free(__ptr__) REP_bdescr_free[__ptr__+OFFSET_bdescr_free]
#define OFFSET_bdescr_blocks 28
#define REP_bdescr_blocks b32
#define bdescr_blocks(__ptr__) REP_bdescr_blocks[__ptr__+OFFSET_bdescr_blocks]
#define OFFSET_bdescr_gen_no 20
#define REP_bdescr_gen_no b16
#define bdescr_gen_no(__ptr__) REP_bdescr_gen_no[__ptr__+OFFSET_bdescr_gen_no]
#define OFFSET_bdescr_link 8
#define REP_bdescr_link b32
#define bdescr_link(__ptr__) REP_bdescr_link[__ptr__+OFFSET_bdescr_link]
#define OFFSET_bdescr_flags 26
#define REP_bdescr_flags b16
#define bdescr_flags(__ptr__) REP_bdescr_flags[__ptr__+OFFSET_bdescr_flags]
#define SIZEOF_generation 280
#define OFFSET_generation_n_new_large_words 28
#define REP_generation_n_new_large_words b32
#define generation_n_new_large_words(__ptr__) REP_generation_n_new_large_words[__ptr__+OFFSET_generation_n_new_large_words]
#define OFFSET_generation_weak_ptr_list 56
#define REP_generation_weak_ptr_list b32
#define generation_weak_ptr_list(__ptr__) REP_generation_weak_ptr_list[__ptr__+OFFSET_generation_weak_ptr_list]
#define SIZEOF_CostCentreStack 64
#define OFFSET_CostCentreStack_ccsID 0
#define REP_CostCentreStack_ccsID b32
#define CostCentreStack_ccsID(__ptr__) REP_CostCentreStack_ccsID[__ptr__+OFFSET_CostCentreStack_ccsID]
#define OFFSET_CostCentreStack_mem_alloc 40
#define REP_CostCentreStack_mem_alloc b64
#define CostCentreStack_mem_alloc(__ptr__) REP_CostCentreStack_mem_alloc[__ptr__+OFFSET_CostCentreStack_mem_alloc]
#define OFFSET_CostCentreStack_scc_count 24
#define REP_CostCentreStack_scc_count b64
#define CostCentreStack_scc_count(__ptr__) REP_CostCentreStack_scc_count[__ptr__+OFFSET_CostCentreStack_scc_count]
#define OFFSET_CostCentreStack_prevStack 8
#define REP_CostCentreStack_prevStack b32
#define CostCentreStack_prevStack(__ptr__) REP_CostCentreStack_prevStack[__ptr__+OFFSET_CostCentreStack_prevStack]
#define OFFSET_CostCentre_ccID 0
#define REP_CostCentre_ccID b32
#define CostCentre_ccID(__ptr__) REP_CostCentre_ccID[__ptr__+OFFSET_CostCentre_ccID]
#define OFFSET_CostCentre_link 32
#define REP_CostCentre_link b32
#define CostCentre_link(__ptr__) REP_CostCentre_link[__ptr__+OFFSET_CostCentre_link]
#define OFFSET_StgHeader_info 0
#define REP_StgHeader_info b32
#define StgHeader_info(__ptr__) REP_StgHeader_info[__ptr__+OFFSET_StgHeader_info]
#define OFFSET_StgHeader_ccs 4
#define REP_StgHeader_ccs b32
#define StgHeader_ccs(__ptr__) REP_StgHeader_ccs[__ptr__+OFFSET_StgHeader_ccs]
#define OFFSET_StgHeader_ldvw 8
#define REP_StgHeader_ldvw b32
#define StgHeader_ldvw(__ptr__) REP_StgHeader_ldvw[__ptr__+OFFSET_StgHeader_ldvw]
#define SIZEOF_StgSMPThunkHeader 4
#define OFFSET_StgClosure_payload 0
#define StgClosure_payload(__ptr__,__ix__) W_[__ptr__+SIZEOF_StgHeader+OFFSET_StgClosure_payload + WDS(__ix__)]
#define OFFSET_StgEntCounter_allocs 24
#define REP_StgEntCounter_allocs b32
#define StgEntCounter_allocs(__ptr__) REP_StgEntCounter_allocs[__ptr__+OFFSET_StgEntCounter_allocs]
#define OFFSET_StgEntCounter_allocd 8
#define REP_StgEntCounter_allocd b32
#define StgEntCounter_allocd(__ptr__) REP_StgEntCounter_allocd[__ptr__+OFFSET_StgEntCounter_allocd]
#define OFFSET_StgEntCounter_registeredp 0
#define REP_StgEntCounter_registeredp b32
#define StgEntCounter_registeredp(__ptr__) REP_StgEntCounter_registeredp[__ptr__+OFFSET_StgEntCounter_registeredp]
#define OFFSET_StgEntCounter_link 28
#define REP_StgEntCounter_link b32
#define StgEntCounter_link(__ptr__) REP_StgEntCounter_link[__ptr__+OFFSET_StgEntCounter_link]
#define OFFSET_StgEntCounter_entry_count 20
#define REP_StgEntCounter_entry_count b32
#define StgEntCounter_entry_count(__ptr__) REP_StgEntCounter_entry_count[__ptr__+OFFSET_StgEntCounter_entry_count]
#define SIZEOF_StgUpdateFrame_NoHdr 4
#define SIZEOF_StgUpdateFrame (SIZEOF_StgHeader+4)
#define SIZEOF_StgCatchFrame_NoHdr 8
#define SIZEOF_StgCatchFrame (SIZEOF_StgHeader+8)
#define SIZEOF_StgStopFrame_NoHdr 0
#define SIZEOF_StgStopFrame (SIZEOF_StgHeader+0)
#define SIZEOF_StgMutArrPtrs_NoHdr 8
#define SIZEOF_StgMutArrPtrs (SIZEOF_StgHeader+8)
#define OFFSET_StgMutArrPtrs_ptrs 0
#define REP_StgMutArrPtrs_ptrs b32
#define StgMutArrPtrs_ptrs(__ptr__) REP_StgMutArrPtrs_ptrs[__ptr__+SIZEOF_StgHeader+OFFSET_StgMutArrPtrs_ptrs]
#define OFFSET_StgMutArrPtrs_size 4
#define REP_StgMutArrPtrs_size b32
#define StgMutArrPtrs_size(__ptr__) REP_StgMutArrPtrs_size[__ptr__+SIZEOF_StgHeader+OFFSET_StgMutArrPtrs_size]
#define SIZEOF_StgSmallMutArrPtrs_NoHdr 4
#define SIZEOF_StgSmallMutArrPtrs (SIZEOF_StgHeader+4)
#define OFFSET_StgSmallMutArrPtrs_ptrs 0
#define REP_StgSmallMutArrPtrs_ptrs b32
#define StgSmallMutArrPtrs_ptrs(__ptr__) REP_StgSmallMutArrPtrs_ptrs[__ptr__+SIZEOF_StgHeader+OFFSET_StgSmallMutArrPtrs_ptrs]
#define SIZEOF_StgArrBytes_NoHdr 4
#define SIZEOF_StgArrBytes (SIZEOF_StgHeader+4)
#define OFFSET_StgArrBytes_bytes 0
#define REP_StgArrBytes_bytes b32
#define StgArrBytes_bytes(__ptr__) REP_StgArrBytes_bytes[__ptr__+SIZEOF_StgHeader+OFFSET_StgArrBytes_bytes]
#define OFFSET_StgArrBytes_payload 4
#define StgArrBytes_payload(__ptr__,__ix__) W_[__ptr__+SIZEOF_StgHeader+OFFSET_StgArrBytes_payload + WDS(__ix__)]
#define OFFSET_StgTSO__link 0
#define REP_StgTSO__link b32
#define StgTSO__link(__ptr__) REP_StgTSO__link[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO__link]
#define OFFSET_StgTSO_global_link 4
#define REP_StgTSO_global_link b32
#define StgTSO_global_link(__ptr__) REP_StgTSO_global_link[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_global_link]
#define OFFSET_StgTSO_what_next 12
#define REP_StgTSO_what_next b16
#define StgTSO_what_next(__ptr__) REP_StgTSO_what_next[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_what_next]
#define OFFSET_StgTSO_why_blocked 14
#define REP_StgTSO_why_blocked b16
#define StgTSO_why_blocked(__ptr__) REP_StgTSO_why_blocked[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_why_blocked]
#define OFFSET_StgTSO_block_info 20
#define REP_StgTSO_block_info b32
#define StgTSO_block_info(__ptr__) REP_StgTSO_block_info[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_block_info]
#define OFFSET_StgTSO_blocked_exceptions 48
#define REP_StgTSO_blocked_exceptions b32
#define StgTSO_blocked_exceptions(__ptr__) REP_StgTSO_blocked_exceptions[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_blocked_exceptions]
#define OFFSET_StgTSO_id 24
#define REP_StgTSO_id b32
#define StgTSO_id(__ptr__) REP_StgTSO_id[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_id]
#define OFFSET_StgTSO_cap 40
#define REP_StgTSO_cap b32
#define StgTSO_cap(__ptr__) REP_StgTSO_cap[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_cap]
#define OFFSET_StgTSO_saved_errno 28
#define REP_StgTSO_saved_errno b32
#define StgTSO_saved_errno(__ptr__) REP_StgTSO_saved_errno[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_saved_errno]
#define OFFSET_StgTSO_trec 44
#define REP_StgTSO_trec b32
#define StgTSO_trec(__ptr__) REP_StgTSO_trec[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_trec]
#define OFFSET_StgTSO_flags 16
#define REP_StgTSO_flags b32
#define StgTSO_flags(__ptr__) REP_StgTSO_flags[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_flags]
#define OFFSET_StgTSO_dirty 32
#define REP_StgTSO_dirty b32
#define StgTSO_dirty(__ptr__) REP_StgTSO_dirty[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_dirty]
#define OFFSET_StgTSO_bq 52
#define REP_StgTSO_bq b32
#define StgTSO_bq(__ptr__) REP_StgTSO_bq[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_bq]
#define OFFSET_StgTSO_alloc_limit 60
#define REP_StgTSO_alloc_limit b64
#define StgTSO_alloc_limit(__ptr__) REP_StgTSO_alloc_limit[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_alloc_limit]
#define OFFSET_StgTSO_cccs 72
#define REP_StgTSO_cccs b32
#define StgTSO_cccs(__ptr__) REP_StgTSO_cccs[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_cccs]
#define OFFSET_StgTSO_stackobj 8
#define REP_StgTSO_stackobj b32
#define StgTSO_stackobj(__ptr__) REP_StgTSO_stackobj[__ptr__+SIZEOF_StgHeader+OFFSET_StgTSO_stackobj]
#define OFFSET_StgStack_sp 8
#define REP_StgStack_sp b32
#define StgStack_sp(__ptr__) REP_StgStack_sp[__ptr__+SIZEOF_StgHeader+OFFSET_StgStack_sp]
#define OFFSET_StgStack_stack 12
#define OFFSET_StgStack_stack_size 0
#define REP_StgStack_stack_size b32
#define StgStack_stack_size(__ptr__) REP_StgStack_stack_size[__ptr__+SIZEOF_StgHeader+OFFSET_StgStack_stack_size]
#define OFFSET_StgStack_dirty 4
#define REP_StgStack_dirty b8
#define StgStack_dirty(__ptr__) REP_StgStack_dirty[__ptr__+SIZEOF_StgHeader+OFFSET_StgStack_dirty]
#define SIZEOF_StgTSOProfInfo 4
#define OFFSET_StgUpdateFrame_updatee 0
#define REP_StgUpdateFrame_updatee b32
#define StgUpdateFrame_updatee(__ptr__) REP_StgUpdateFrame_updatee[__ptr__+SIZEOF_StgHeader+OFFSET_StgUpdateFrame_updatee]
#define OFFSET_StgCatchFrame_handler 4
#define REP_StgCatchFrame_handler b32
#define StgCatchFrame_handler(__ptr__) REP_StgCatchFrame_handler[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchFrame_handler]
#define OFFSET_StgCatchFrame_exceptions_blocked 0
#define REP_StgCatchFrame_exceptions_blocked b32
#define StgCatchFrame_exceptions_blocked(__ptr__) REP_StgCatchFrame_exceptions_blocked[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchFrame_exceptions_blocked]
#define SIZEOF_StgPAP_NoHdr 8
#define SIZEOF_StgPAP (SIZEOF_StgHeader+8)
#define OFFSET_StgPAP_n_args 2
#define REP_StgPAP_n_args b16
#define StgPAP_n_args(__ptr__) REP_StgPAP_n_args[__ptr__+SIZEOF_StgHeader+OFFSET_StgPAP_n_args]
#define OFFSET_StgPAP_fun 4
#define REP_StgPAP_fun gcptr
#define StgPAP_fun(__ptr__) REP_StgPAP_fun[__ptr__+SIZEOF_StgHeader+OFFSET_StgPAP_fun]
#define OFFSET_StgPAP_arity 0
#define REP_StgPAP_arity b16
#define StgPAP_arity(__ptr__) REP_StgPAP_arity[__ptr__+SIZEOF_StgHeader+OFFSET_StgPAP_arity]
#define OFFSET_StgPAP_payload 8
#define StgPAP_payload(__ptr__,__ix__) W_[__ptr__+SIZEOF_StgHeader+OFFSET_StgPAP_payload + WDS(__ix__)]
#define SIZEOF_StgAP_NoThunkHdr 8
#define SIZEOF_StgAP_NoHdr 12
#define SIZEOF_StgAP (SIZEOF_StgHeader+12)
#define OFFSET_StgAP_n_args 6
#define REP_StgAP_n_args b16
#define StgAP_n_args(__ptr__) REP_StgAP_n_args[__ptr__+SIZEOF_StgHeader+OFFSET_StgAP_n_args]
#define OFFSET_StgAP_fun 8
#define REP_StgAP_fun gcptr
#define StgAP_fun(__ptr__) REP_StgAP_fun[__ptr__+SIZEOF_StgHeader+OFFSET_StgAP_fun]
#define OFFSET_StgAP_payload 12
#define StgAP_payload(__ptr__,__ix__) W_[__ptr__+SIZEOF_StgHeader+OFFSET_StgAP_payload + WDS(__ix__)]
#define SIZEOF_StgAP_STACK_NoThunkHdr 8
#define SIZEOF_StgAP_STACK_NoHdr 12
#define SIZEOF_StgAP_STACK (SIZEOF_StgHeader+12)
#define OFFSET_StgAP_STACK_size 4
#define REP_StgAP_STACK_size b32
#define StgAP_STACK_size(__ptr__) REP_StgAP_STACK_size[__ptr__+SIZEOF_StgHeader+OFFSET_StgAP_STACK_size]
#define OFFSET_StgAP_STACK_fun 8
#define REP_StgAP_STACK_fun gcptr
#define StgAP_STACK_fun(__ptr__) REP_StgAP_STACK_fun[__ptr__+SIZEOF_StgHeader+OFFSET_StgAP_STACK_fun]
#define OFFSET_StgAP_STACK_payload 12
#define StgAP_STACK_payload(__ptr__,__ix__) W_[__ptr__+SIZEOF_StgHeader+OFFSET_StgAP_STACK_payload + WDS(__ix__)]
#define SIZEOF_StgSelector_NoThunkHdr 4
#define SIZEOF_StgSelector_NoHdr 8
#define SIZEOF_StgSelector (SIZEOF_StgHeader+8)
#define OFFSET_StgInd_indirectee 0
#define REP_StgInd_indirectee gcptr
#define StgInd_indirectee(__ptr__) REP_StgInd_indirectee[__ptr__+SIZEOF_StgHeader+OFFSET_StgInd_indirectee]
#define SIZEOF_StgMutVar_NoHdr 4
#define SIZEOF_StgMutVar (SIZEOF_StgHeader+4)
#define OFFSET_StgMutVar_var 0
#define REP_StgMutVar_var b32
#define StgMutVar_var(__ptr__) REP_StgMutVar_var[__ptr__+SIZEOF_StgHeader+OFFSET_StgMutVar_var]
#define SIZEOF_StgAtomicallyFrame_NoHdr 8
#define SIZEOF_StgAtomicallyFrame (SIZEOF_StgHeader+8)
#define OFFSET_StgAtomicallyFrame_code 0
#define REP_StgAtomicallyFrame_code b32
#define StgAtomicallyFrame_code(__ptr__) REP_StgAtomicallyFrame_code[__ptr__+SIZEOF_StgHeader+OFFSET_StgAtomicallyFrame_code]
#define OFFSET_StgAtomicallyFrame_result 4
#define REP_StgAtomicallyFrame_result b32
#define StgAtomicallyFrame_result(__ptr__) REP_StgAtomicallyFrame_result[__ptr__+SIZEOF_StgHeader+OFFSET_StgAtomicallyFrame_result]
#define OFFSET_StgTRecHeader_enclosing_trec 0
#define REP_StgTRecHeader_enclosing_trec b32
#define StgTRecHeader_enclosing_trec(__ptr__) REP_StgTRecHeader_enclosing_trec[__ptr__+SIZEOF_StgHeader+OFFSET_StgTRecHeader_enclosing_trec]
#define SIZEOF_StgCatchSTMFrame_NoHdr 8
#define SIZEOF_StgCatchSTMFrame (SIZEOF_StgHeader+8)
#define OFFSET_StgCatchSTMFrame_handler 4
#define REP_StgCatchSTMFrame_handler b32
#define StgCatchSTMFrame_handler(__ptr__) REP_StgCatchSTMFrame_handler[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchSTMFrame_handler]
#define OFFSET_StgCatchSTMFrame_code 0
#define REP_StgCatchSTMFrame_code b32
#define StgCatchSTMFrame_code(__ptr__) REP_StgCatchSTMFrame_code[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchSTMFrame_code]
#define SIZEOF_StgCatchRetryFrame_NoHdr 12
#define SIZEOF_StgCatchRetryFrame (SIZEOF_StgHeader+12)
#define OFFSET_StgCatchRetryFrame_running_alt_code 0
#define REP_StgCatchRetryFrame_running_alt_code b32
#define StgCatchRetryFrame_running_alt_code(__ptr__) REP_StgCatchRetryFrame_running_alt_code[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchRetryFrame_running_alt_code]
#define OFFSET_StgCatchRetryFrame_first_code 4
#define REP_StgCatchRetryFrame_first_code b32
#define StgCatchRetryFrame_first_code(__ptr__) REP_StgCatchRetryFrame_first_code[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchRetryFrame_first_code]
#define OFFSET_StgCatchRetryFrame_alt_code 8
#define REP_StgCatchRetryFrame_alt_code b32
#define StgCatchRetryFrame_alt_code(__ptr__) REP_StgCatchRetryFrame_alt_code[__ptr__+SIZEOF_StgHeader+OFFSET_StgCatchRetryFrame_alt_code]
#define OFFSET_StgTVarWatchQueue_closure 0
#define REP_StgTVarWatchQueue_closure b32
#define StgTVarWatchQueue_closure(__ptr__) REP_StgTVarWatchQueue_closure[__ptr__+SIZEOF_StgHeader+OFFSET_StgTVarWatchQueue_closure]
#define OFFSET_StgTVarWatchQueue_next_queue_entry 4
#define REP_StgTVarWatchQueue_next_queue_entry b32
#define StgTVarWatchQueue_next_queue_entry(__ptr__) REP_StgTVarWatchQueue_next_queue_entry[__ptr__+SIZEOF_StgHeader+OFFSET_StgTVarWatchQueue_next_queue_entry]
#define OFFSET_StgTVarWatchQueue_prev_queue_entry 8
#define REP_StgTVarWatchQueue_prev_queue_entry b32
#define StgTVarWatchQueue_prev_queue_entry(__ptr__) REP_StgTVarWatchQueue_prev_queue_entry[__ptr__+SIZEOF_StgHeader+OFFSET_StgTVarWatchQueue_prev_queue_entry]
#define SIZEOF_StgTVar_NoHdr 12
#define SIZEOF_StgTVar (SIZEOF_StgHeader+12)
#define OFFSET_StgTVar_current_value 0
#define REP_StgTVar_current_value b32
#define StgTVar_current_value(__ptr__) REP_StgTVar_current_value[__ptr__+SIZEOF_StgHeader+OFFSET_StgTVar_current_value]
#define OFFSET_StgTVar_first_watch_queue_entry 4
#define REP_StgTVar_first_watch_queue_entry b32
#define StgTVar_first_watch_queue_entry(__ptr__) REP_StgTVar_first_watch_queue_entry[__ptr__+SIZEOF_StgHeader+OFFSET_StgTVar_first_watch_queue_entry]
#define OFFSET_StgTVar_num_updates 8
#define REP_StgTVar_num_updates b32
#define StgTVar_num_updates(__ptr__) REP_StgTVar_num_updates[__ptr__+SIZEOF_StgHeader+OFFSET_StgTVar_num_updates]
#define SIZEOF_StgWeak_NoHdr 20
#define SIZEOF_StgWeak (SIZEOF_StgHeader+20)
#define OFFSET_StgWeak_link 16
#define REP_StgWeak_link b32
#define StgWeak_link(__ptr__) REP_StgWeak_link[__ptr__+SIZEOF_StgHeader+OFFSET_StgWeak_link]
#define OFFSET_StgWeak_key 4
#define REP_StgWeak_key b32
#define StgWeak_key(__ptr__) REP_StgWeak_key[__ptr__+SIZEOF_StgHeader+OFFSET_StgWeak_key]
#define OFFSET_StgWeak_value 8
#define REP_StgWeak_value b32
#define StgWeak_value(__ptr__) REP_StgWeak_value[__ptr__+SIZEOF_StgHeader+OFFSET_StgWeak_value]
#define OFFSET_StgWeak_finalizer 12
#define REP_StgWeak_finalizer b32
#define StgWeak_finalizer(__ptr__) REP_StgWeak_finalizer[__ptr__+SIZEOF_StgHeader+OFFSET_StgWeak_finalizer]
#define OFFSET_StgWeak_cfinalizers 0
#define REP_StgWeak_cfinalizers b32
#define StgWeak_cfinalizers(__ptr__) REP_StgWeak_cfinalizers[__ptr__+SIZEOF_StgHeader+OFFSET_StgWeak_cfinalizers]
#define SIZEOF_StgCFinalizerList_NoHdr 20
#define SIZEOF_StgCFinalizerList (SIZEOF_StgHeader+20)
#define OFFSET_StgCFinalizerList_link 0
#define REP_StgCFinalizerList_link b32
#define StgCFinalizerList_link(__ptr__) REP_StgCFinalizerList_link[__ptr__+SIZEOF_StgHeader+OFFSET_StgCFinalizerList_link]
#define OFFSET_StgCFinalizerList_fptr 4
#define REP_StgCFinalizerList_fptr b32
#define StgCFinalizerList_fptr(__ptr__) REP_StgCFinalizerList_fptr[__ptr__+SIZEOF_StgHeader+OFFSET_StgCFinalizerList_fptr]
#define OFFSET_StgCFinalizerList_ptr 8
#define REP_StgCFinalizerList_ptr b32
#define StgCFinalizerList_ptr(__ptr__) REP_StgCFinalizerList_ptr[__ptr__+SIZEOF_StgHeader+OFFSET_StgCFinalizerList_ptr]
#define OFFSET_StgCFinalizerList_eptr 12
#define REP_StgCFinalizerList_eptr b32
#define StgCFinalizerList_eptr(__ptr__) REP_StgCFinalizerList_eptr[__ptr__+SIZEOF_StgHeader+OFFSET_StgCFinalizerList_eptr]
#define OFFSET_StgCFinalizerList_flag 16
#define REP_StgCFinalizerList_flag b32
#define StgCFinalizerList_flag(__ptr__) REP_StgCFinalizerList_flag[__ptr__+SIZEOF_StgHeader+OFFSET_StgCFinalizerList_flag]
#define SIZEOF_StgMVar_NoHdr 12
#define SIZEOF_StgMVar (SIZEOF_StgHeader+12)
#define OFFSET_StgMVar_head 0
#define REP_StgMVar_head b32
#define StgMVar_head(__ptr__) REP_StgMVar_head[__ptr__+SIZEOF_StgHeader+OFFSET_StgMVar_head]
#define OFFSET_StgMVar_tail 4
#define REP_StgMVar_tail b32
#define StgMVar_tail(__ptr__) REP_StgMVar_tail[__ptr__+SIZEOF_StgHeader+OFFSET_StgMVar_tail]
#define OFFSET_StgMVar_value 8
#define REP_StgMVar_value b32
#define StgMVar_value(__ptr__) REP_StgMVar_value[__ptr__+SIZEOF_StgHeader+OFFSET_StgMVar_value]
#define SIZEOF_StgMVarTSOQueue_NoHdr 8
#define SIZEOF_StgMVarTSOQueue (SIZEOF_StgHeader+8)
#define OFFSET_StgMVarTSOQueue_link 0
#define REP_StgMVarTSOQueue_link b32
#define StgMVarTSOQueue_link(__ptr__) REP_StgMVarTSOQueue_link[__ptr__+SIZEOF_StgHeader+OFFSET_StgMVarTSOQueue_link]
#define OFFSET_StgMVarTSOQueue_tso 4
#define REP_StgMVarTSOQueue_tso b32
#define StgMVarTSOQueue_tso(__ptr__) REP_StgMVarTSOQueue_tso[__ptr__+SIZEOF_StgHeader+OFFSET_StgMVarTSOQueue_tso]
#define SIZEOF_StgBCO_NoHdr 16
#define SIZEOF_StgBCO (SIZEOF_StgHeader+16)
#define OFFSET_StgBCO_instrs 0
#define REP_StgBCO_instrs b32
#define StgBCO_instrs(__ptr__) REP_StgBCO_instrs[__ptr__+SIZEOF_StgHeader+OFFSET_StgBCO_instrs]
#define OFFSET_StgBCO_literals 4
#define REP_StgBCO_literals b32
#define StgBCO_literals(__ptr__) REP_StgBCO_literals[__ptr__+SIZEOF_StgHeader+OFFSET_StgBCO_literals]
#define OFFSET_StgBCO_ptrs 8
#define REP_StgBCO_ptrs b32
#define StgBCO_ptrs(__ptr__) REP_StgBCO_ptrs[__ptr__+SIZEOF_StgHeader+OFFSET_StgBCO_ptrs]
#define OFFSET_StgBCO_arity 12
#define REP_StgBCO_arity b16
#define StgBCO_arity(__ptr__) REP_StgBCO_arity[__ptr__+SIZEOF_StgHeader+OFFSET_StgBCO_arity]
#define OFFSET_StgBCO_size 14
#define REP_StgBCO_size b16
#define StgBCO_size(__ptr__) REP_StgBCO_size[__ptr__+SIZEOF_StgHeader+OFFSET_StgBCO_size]
#define OFFSET_StgBCO_bitmap 16
#define StgBCO_bitmap(__ptr__,__ix__) W_[__ptr__+SIZEOF_StgHeader+OFFSET_StgBCO_bitmap + WDS(__ix__)]
#define SIZEOF_StgStableName_NoHdr 4
#define SIZEOF_StgStableName (SIZEOF_StgHeader+4)
#define OFFSET_StgStableName_sn 0
#define REP_StgStableName_sn b32
#define StgStableName_sn(__ptr__) REP_StgStableName_sn[__ptr__+SIZEOF_StgHeader+OFFSET_StgStableName_sn]
#define SIZEOF_StgBlockingQueue_NoHdr 16
#define SIZEOF_StgBlockingQueue (SIZEOF_StgHeader+16)
#define OFFSET_StgBlockingQueue_bh 4
#define REP_StgBlockingQueue_bh b32
#define StgBlockingQueue_bh(__ptr__) REP_StgBlockingQueue_bh[__ptr__+SIZEOF_StgHeader+OFFSET_StgBlockingQueue_bh]
#define OFFSET_StgBlockingQueue_owner 8
#define REP_StgBlockingQueue_owner b32
#define StgBlockingQueue_owner(__ptr__) REP_StgBlockingQueue_owner[__ptr__+SIZEOF_StgHeader+OFFSET_StgBlockingQueue_owner]
#define OFFSET_StgBlockingQueue_queue 12
#define REP_StgBlockingQueue_queue b32
#define StgBlockingQueue_queue(__ptr__) REP_StgBlockingQueue_queue[__ptr__+SIZEOF_StgHeader+OFFSET_StgBlockingQueue_queue]
#define OFFSET_StgBlockingQueue_link 0
#define REP_StgBlockingQueue_link b32
#define StgBlockingQueue_link(__ptr__) REP_StgBlockingQueue_link[__ptr__+SIZEOF_StgHeader+OFFSET_StgBlockingQueue_link]
#define SIZEOF_MessageBlackHole_NoHdr 12
#define SIZEOF_MessageBlackHole (SIZEOF_StgHeader+12)
#define OFFSET_MessageBlackHole_link 0
#define REP_MessageBlackHole_link b32
#define MessageBlackHole_link(__ptr__) REP_MessageBlackHole_link[__ptr__+SIZEOF_StgHeader+OFFSET_MessageBlackHole_link]
#define OFFSET_MessageBlackHole_tso 4
#define REP_MessageBlackHole_tso b32
#define MessageBlackHole_tso(__ptr__) REP_MessageBlackHole_tso[__ptr__+SIZEOF_StgHeader+OFFSET_MessageBlackHole_tso]
#define OFFSET_MessageBlackHole_bh 8
#define REP_MessageBlackHole_bh b32
#define MessageBlackHole_bh(__ptr__) REP_MessageBlackHole_bh[__ptr__+SIZEOF_StgHeader+OFFSET_MessageBlackHole_bh]
#define SIZEOF_StgCompactNFData_NoHdr 32
#define SIZEOF_StgCompactNFData (SIZEOF_StgHeader+32)
#define OFFSET_StgCompactNFData_totalW 0
#define REP_StgCompactNFData_totalW b32
#define StgCompactNFData_totalW(__ptr__) REP_StgCompactNFData_totalW[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_totalW]
#define OFFSET_StgCompactNFData_autoBlockW 4
#define REP_StgCompactNFData_autoBlockW b32
#define StgCompactNFData_autoBlockW(__ptr__) REP_StgCompactNFData_autoBlockW[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_autoBlockW]
#define OFFSET_StgCompactNFData_nursery 16
#define REP_StgCompactNFData_nursery b32
#define StgCompactNFData_nursery(__ptr__) REP_StgCompactNFData_nursery[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_nursery]
#define OFFSET_StgCompactNFData_last 20
#define REP_StgCompactNFData_last b32
#define StgCompactNFData_last(__ptr__) REP_StgCompactNFData_last[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_last]
#define OFFSET_StgCompactNFData_hp 8
#define REP_StgCompactNFData_hp b32
#define StgCompactNFData_hp(__ptr__) REP_StgCompactNFData_hp[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_hp]
#define OFFSET_StgCompactNFData_hpLim 12
#define REP_StgCompactNFData_hpLim b32
#define StgCompactNFData_hpLim(__ptr__) REP_StgCompactNFData_hpLim[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_hpLim]
#define OFFSET_StgCompactNFData_hash 24
#define REP_StgCompactNFData_hash b32
#define StgCompactNFData_hash(__ptr__) REP_StgCompactNFData_hash[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_hash]
#define OFFSET_StgCompactNFData_result 28
#define REP_StgCompactNFData_result b32
#define StgCompactNFData_result(__ptr__) REP_StgCompactNFData_result[__ptr__+SIZEOF_StgHeader+OFFSET_StgCompactNFData_result]
#define SIZEOF_StgCompactNFDataBlock 12
#define OFFSET_StgCompactNFDataBlock_self 0
#define REP_StgCompactNFDataBlock_self b32
#define StgCompactNFDataBlock_self(__ptr__) REP_StgCompactNFDataBlock_self[__ptr__+OFFSET_StgCompactNFDataBlock_self]
#define OFFSET_StgCompactNFDataBlock_owner 4
#define REP_StgCompactNFDataBlock_owner b32
#define StgCompactNFDataBlock_owner(__ptr__) REP_StgCompactNFDataBlock_owner[__ptr__+OFFSET_StgCompactNFDataBlock_owner]
#define OFFSET_StgCompactNFDataBlock_next 8
#define REP_StgCompactNFDataBlock_next b32
#define StgCompactNFDataBlock_next(__ptr__) REP_StgCompactNFDataBlock_next[__ptr__+OFFSET_StgCompactNFDataBlock_next]
#define OFFSET_RtsFlags_ProfFlags_showCCSOnException 269
#define REP_RtsFlags_ProfFlags_showCCSOnException b8
#define RtsFlags_ProfFlags_showCCSOnException(__ptr__) REP_RtsFlags_ProfFlags_showCCSOnException[__ptr__+OFFSET_RtsFlags_ProfFlags_showCCSOnException]
#define OFFSET_RtsFlags_DebugFlags_apply 220
#define REP_RtsFlags_DebugFlags_apply b8
#define RtsFlags_DebugFlags_apply(__ptr__) REP_RtsFlags_DebugFlags_apply[__ptr__+OFFSET_RtsFlags_DebugFlags_apply]
#define OFFSET_RtsFlags_DebugFlags_sanity 215
#define REP_RtsFlags_DebugFlags_sanity b8
#define RtsFlags_DebugFlags_sanity(__ptr__) REP_RtsFlags_DebugFlags_sanity[__ptr__+OFFSET_RtsFlags_DebugFlags_sanity]
#define OFFSET_RtsFlags_DebugFlags_weak 210
#define REP_RtsFlags_DebugFlags_weak b8
#define RtsFlags_DebugFlags_weak(__ptr__) REP_RtsFlags_DebugFlags_weak[__ptr__+OFFSET_RtsFlags_DebugFlags_weak]
#define OFFSET_RtsFlags_GcFlags_initialStkSize 12
#define REP_RtsFlags_GcFlags_initialStkSize b32
#define RtsFlags_GcFlags_initialStkSize(__ptr__) REP_RtsFlags_GcFlags_initialStkSize[__ptr__+OFFSET_RtsFlags_GcFlags_initialStkSize]
#define OFFSET_RtsFlags_MiscFlags_tickInterval 184
#define REP_RtsFlags_MiscFlags_tickInterval b64
#define RtsFlags_MiscFlags_tickInterval(__ptr__) REP_RtsFlags_MiscFlags_tickInterval[__ptr__+OFFSET_RtsFlags_MiscFlags_tickInterval]
#define SIZEOF_StgFunInfoExtraFwd 16
#define OFFSET_StgFunInfoExtraFwd_slow_apply 12
#define REP_StgFunInfoExtraFwd_slow_apply b32
#define StgFunInfoExtraFwd_slow_apply(__ptr__) REP_StgFunInfoExtraFwd_slow_apply[__ptr__+OFFSET_StgFunInfoExtraFwd_slow_apply]
#define OFFSET_StgFunInfoExtraFwd_fun_type 0
#define REP_StgFunInfoExtraFwd_fun_type b16
#define StgFunInfoExtraFwd_fun_type(__ptr__) REP_StgFunInfoExtraFwd_fun_type[__ptr__+OFFSET_StgFunInfoExtraFwd_fun_type]
#define OFFSET_StgFunInfoExtraFwd_arity 2
#define REP_StgFunInfoExtraFwd_arity b16
#define StgFunInfoExtraFwd_arity(__ptr__) REP_StgFunInfoExtraFwd_arity[__ptr__+OFFSET_StgFunInfoExtraFwd_arity]
#define OFFSET_StgFunInfoExtraFwd_bitmap 8
#define REP_StgFunInfoExtraFwd_bitmap b32
#define StgFunInfoExtraFwd_bitmap(__ptr__) REP_StgFunInfoExtraFwd_bitmap[__ptr__+OFFSET_StgFunInfoExtraFwd_bitmap]
#define SIZEOF_StgFunInfoExtraRev 16
#define OFFSET_StgFunInfoExtraRev_slow_apply_offset 0
#define REP_StgFunInfoExtraRev_slow_apply_offset b16
#define StgFunInfoExtraRev_slow_apply_offset(__ptr__) REP_StgFunInfoExtraRev_slow_apply_offset[__ptr__+OFFSET_StgFunInfoExtraRev_slow_apply_offset]
#define OFFSET_StgFunInfoExtraRev_fun_type 12
#define REP_StgFunInfoExtraRev_fun_type b16
#define StgFunInfoExtraRev_fun_type(__ptr__) REP_StgFunInfoExtraRev_fun_type[__ptr__+OFFSET_StgFunInfoExtraRev_fun_type]
#define OFFSET_StgFunInfoExtraRev_arity 14
#define REP_StgFunInfoExtraRev_arity b16
#define StgFunInfoExtraRev_arity(__ptr__) REP_StgFunInfoExtraRev_arity[__ptr__+OFFSET_StgFunInfoExtraRev_arity]
#define OFFSET_StgFunInfoExtraRev_bitmap 4
#define REP_StgFunInfoExtraRev_bitmap b32
#define StgFunInfoExtraRev_bitmap(__ptr__) REP_StgFunInfoExtraRev_bitmap[__ptr__+OFFSET_StgFunInfoExtraRev_bitmap]
#define OFFSET_StgFunInfoExtraRev_bitmap_offset 4
#define REP_StgFunInfoExtraRev_bitmap_offset b16
#define StgFunInfoExtraRev_bitmap_offset(__ptr__) REP_StgFunInfoExtraRev_bitmap_offset[__ptr__+OFFSET_StgFunInfoExtraRev_bitmap_offset]
#define OFFSET_StgLargeBitmap_size 0
#define REP_StgLargeBitmap_size b32
#define StgLargeBitmap_size(__ptr__) REP_StgLargeBitmap_size[__ptr__+OFFSET_StgLargeBitmap_size]
#define OFFSET_StgLargeBitmap_bitmap 4
#define SIZEOF_snEntry 12
#define OFFSET_snEntry_sn_obj 8
#define REP_snEntry_sn_obj b32
#define snEntry_sn_obj(__ptr__) REP_snEntry_sn_obj[__ptr__+OFFSET_snEntry_sn_obj]
#define OFFSET_snEntry_addr 0
#define REP_snEntry_addr b32
#define snEntry_addr(__ptr__) REP_snEntry_addr[__ptr__+OFFSET_snEntry_addr]
#define SIZEOF_spEntry 4
#define OFFSET_spEntry_addr 0
#define REP_spEntry_addr b32
#define spEntry_addr(__ptr__) REP_spEntry_addr[__ptr__+OFFSET_spEntry_addr]