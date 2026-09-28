#include "my_application.h"
#include <cstdlib>

int main(int argc, char** argv) {
  // Fix crash "epoxy_get_proc_address" su Wayland (LMDE/Debian).
  // Se GDK_BACKEND non è impostato, forza X11 per evitare
  // "Couldn't find current GLX or EGL context".
  if (!getenv("GDK_BACKEND")) {
    setenv("GDK_BACKEND", "x11", 1);
  }

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
