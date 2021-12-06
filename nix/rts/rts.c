#include <Rts.h>
#include <sm/Storage.h>
#include <stdnoreturn.h>

__attribute__((export_name("__ahc_Bdescr"))) bdescr *__ahc_Bdescr(StgPtr p) {
  return Bdescr(p);
}

__attribute__((export_name("__ahc_HEAP_ALLOCED"))) bool
__ahc_HEAP_ALLOCED(void *p) {
  return HEAP_ALLOCED(p);
}

const StgInfoTable __stg_EAGER_BLACKHOLE_info = {0};

noreturn StgFunPtr __stg_gc_enter_1(void) { barf("__stg_gc_enter_1"); }

noreturn StgFunPtr __stg_gc_fun(void) { barf("__stg_gc_fun"); }

extern struct __locale_struct __c_dot_utf8_locale;

bdescr *alloc_mega_group (uint32_t, StgWord);
void free_mega_group(bdescr*);

__attribute__((export_name("wizer.initialize"))) void __wizer_initialize(void) {
  uselocale(&__c_dot_utf8_locale);
  setbuf(stdin, NULL);
  setbuf(stdout, NULL);
  
  initRtsFlagsDefaults();
  initCapabilities();
  initStorage();

  size_t size;
  scanf("%zu", &size);
  uint8_t *p = aligned_alloc(8, size);
  if (p == NULL) {
    barf("__wizer_initialize: aligned_alloc returned NULL");
  }
  memset(p, 0, size);
  printf("%p", p);

  free_mega_group(alloc_mega_group(0, 64));
}

StgClosure stg_END_STM_CHUNK_LIST_closure = {0};
StgClosure stg_END_STM_WATCH_QUEUE_closure = {0};
StgClosure stg_END_TSO_QUEUE_closure = {0};
StgClosure stg_NO_TREC_closure = {0};
