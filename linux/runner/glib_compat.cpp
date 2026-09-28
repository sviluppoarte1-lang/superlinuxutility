#include <cstddef>

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned long gsize;
typedef void *gpointer;
typedef int gboolean;

gboolean g_once_init_enter(volatile gsize *location);
void g_once_init_leave(gsize *location, gsize result);

__attribute__((weak)) gpointer
g_once_init_enter_pointer(volatile gpointer *location) {
  if (__atomic_load_n(location, __ATOMIC_SEQ_CST) != NULL) return NULL;
  if (g_once_init_enter((volatile gsize *)location)) return (gpointer)location;
  return (gpointer)(gsize)-1;
}

__attribute__((weak)) void
g_once_init_leave_pointer(gpointer *location, gpointer result) {
  g_once_init_leave((gsize *)location, (gsize)result);
}

#ifdef __cplusplus
}
#endif
