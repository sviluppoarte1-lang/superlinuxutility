#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#include <gdk-pixbuf/gdk-pixbuf.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Super Linux Utility");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Super Linux Utility");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

static GdkPixbuf* load_icon_from_path(const gchar* icon_path) {
  GError* error = nullptr;
  GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(icon_path, &error);
  if (error) {
    g_warning("Failed to load icon from %s: %s", icon_path, error->message);
    g_error_free(error);
    return nullptr;
  }
  return pixbuf;
}

// Path to icon.png inside the Flutter bundle (same as assets/icons/icon.png).
#define BUNDLE_ICON_REL_PATH "data/flutter_assets/assets/icons/icon.png"

static void set_application_icon(GApplication* application) {
  // 1) Icon from bundle (when running from build/.../bundle or from /usr/share/super-linux-utility)
  gchar* bundle_icon = nullptr;
  gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  if (exe) {
    gchar* dir = g_path_get_dirname(exe);
    if (dir) {
      bundle_icon = g_build_filename(dir, BUNDLE_ICON_REL_PATH, nullptr);
      g_free(dir);
    }
    g_free(exe);
  }

  const gchar* icon_paths[] = {
    bundle_icon,
    "/usr/share/pixmaps/super-linux-utility.png",
    "/usr/share/icons/hicolor/512x512/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/256x256/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/128x128/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/64x64/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/48x48/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/32x32/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/24x24/apps/super-linux-utility.png",
    "/usr/share/icons/hicolor/16x16/apps/super-linux-utility.png",
    nullptr
  };

  for (int i = 0; icon_paths[i] != nullptr; i++) {
    GdkPixbuf* pixbuf = load_icon_from_path(icon_paths[i]);
    if (pixbuf) {
      gtk_window_set_default_icon(pixbuf);
      g_object_unref(pixbuf);
      if (bundle_icon) g_free(bundle_icon);
      return;
    }
  }
  if (bundle_icon) g_free(bundle_icon);
}

static void my_application_startup(GApplication* application) {
  set_application_icon(application);
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
