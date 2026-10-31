#include "my_application.h"

#include <string.h>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#include <gdk-pixbuf/gdk-pixbuf.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* slu_window_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Reads a boolean key ("key":true / "key":false) from the raw JSON text of
// shared_preferences.json. Returns dflt when the key is absent.
static gboolean slu_pref_bool(const gchar* contents, const gchar* key,
                              gboolean dflt) {
  if (contents == nullptr) return dflt;
  g_autofree gchar* needle_true =
      g_strdup_printf("\"%s\":true", key);
  g_autofree gchar* needle_true_sp =
      g_strdup_printf("\"%s\": true", key);
  g_autofree gchar* needle_false =
      g_strdup_printf("\"%s\":false", key);
  g_autofree gchar* needle_false_sp =
      g_strdup_printf("\"%s\": false", key);
  if (strstr(contents, needle_true) != nullptr ||
      strstr(contents, needle_true_sp) != nullptr)
    return TRUE;
  if (strstr(contents, needle_false) != nullptr ||
      strstr(contents, needle_false_sp) != nullptr)
    return FALSE;
  return dflt;
}

// TRUE quando l'utente ha chiesto di avviare ridotto a icona nel tray e
// l'app NON deve MAI mostrare la finestra principale (nemmeno un frame).
// Lettura diretta delle prefs: a livello C++ è l'unico modo per evitare il
// flash iniziale (la finestra viene mostrata qui al primo frame Flutter,
// prima che Dart possa nasconderla).
static gboolean should_start_hidden() {
  static gboolean checked = FALSE;
  static gboolean hidden = FALSE;
  if (checked) return hidden;
  checked = TRUE;

  // Modalità standalone (task manager / aggiornamenti / appunti): mostra.
  const gchar* mode = g_getenv("SUPER_LINUX_UTILITY_MODE");
  if (mode != nullptr && mode[0] != '\0') return hidden;

  g_autofree gchar* path = nullptr;
  const gchar* xdg = g_getenv("XDG_DATA_HOME");
  if (xdg != nullptr && xdg[0] != '\0') {
    path = g_build_filename(xdg, "com.superlinux.utility",
                            "shared_preferences.json", nullptr);
  } else {
    const gchar* home = g_getenv("HOME");
    if (home == nullptr || home[0] == '\0') return hidden;
    path = g_build_filename(home, ".local", "share", "com.superlinux.utility",
                            "shared_preferences.json", nullptr);
  }

  gchar* contents = nullptr;
  if (!g_file_get_contents(path, &contents, nullptr, nullptr)) return hidden;

  const gboolean start_min =
      slu_pref_bool(contents, "flutter.start_minimized", FALSE);
  const gboolean tray_on =
      slu_pref_bool(contents, "flutter.system_tray_enabled", TRUE);
  // Primo avvio (lingua/avviso/password non completati): deve mostrare.
  const gboolean language_selected =
      slu_pref_bool(contents, "flutter.language_selected", FALSE);
  const gboolean warning_accepted =
      slu_pref_bool(contents, "flutter.warning_accepted", FALSE);
  const gboolean password_configured =
      slu_pref_bool(contents, "flutter.password_configured", FALSE);
  g_free(contents);

  hidden = start_min && tray_on && language_selected && warning_accepted &&
           password_configured;
  return hidden;
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  if (should_start_hidden()) return;  // Avvio in tray: finestra mai mappata.
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
// Stato del trascinamento ibrido: si prova prima il move-grab del WM
// (begin_move_drag, comportamento nativo con snapping e senza lag); se il WM
// non segue la finestra nonostante il puntore si muova (grab ignorato, come
// con alcuni compositor/XWayland o input sintetici), dopo 5 update si passa
// al movimento manuale con gtk_window_move. Un solo window per processo:
// lo stato statico e' sufficiente.
typedef struct {
  gint origin_x, origin_y;   // posizione della finestra a inizio drag
  guint unchanged_updates;   // update consecutive senza movimento della finestra
  gboolean manual;           // attivo il fallback manuale
  gboolean wm_taken;         // il WM sta muovendo la finestra: non toccare
} SluDragState;
static SluDragState slu_drag_state = {0, 0, 0, FALSE, FALSE};

// Handler del channel "com.superlinux.utility/window": trascinamento delle
// finestre standalone non decorate (non hanno titlebar). Il timestamp va
// passato come GDK_CURRENT_TIME: window_manager usava i microsecondi
// monotonic (troncati a 32 bit) che i WM scartano come evento "stale" e la
// finestra non si muoveva.
static void slu_window_method_call_cb(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, "startDragging") == 0) {
    GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
    GdkSeat* seat = gdk_display_get_default_seat(display);
    GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
    gint root_x = 0, root_y = 0;
    if (pointer != nullptr)
      gdk_device_get_position(pointer, nullptr, &root_x, &root_y);
    gint win_x = 0, win_y = 0;
    gtk_window_get_position(window, &win_x, &win_y);
    slu_drag_state.origin_x = win_x;
    slu_drag_state.origin_y = win_y;
    slu_drag_state.unchanged_updates = 0;
    slu_drag_state.manual = FALSE;
    slu_drag_state.wm_taken = FALSE;
    gtk_window_begin_move_drag(window, 1, root_x, root_y, GDK_CURRENT_TIME);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "dragMove") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gdouble dx = fl_value_get_float(fl_value_get_list_value(args, 0));
    const gdouble dy = fl_value_get_float(fl_value_get_list_value(args, 1));
    if (slu_drag_state.manual) {
      gtk_window_move(window, (gint)(slu_drag_state.origin_x + dx),
                      (gint)(slu_drag_state.origin_y + dy));
    } else if (!slu_drag_state.wm_taken) {
      gint cx = 0, cy = 0;
      gtk_window_get_position(window, &cx, &cy);
      if (cx != slu_drag_state.origin_x || cy != slu_drag_state.origin_y) {
        // Il WM ha preso il move-grab: la finestra la muove lui.
        slu_drag_state.wm_taken = TRUE;
      } else if (++slu_drag_state.unchanged_updates >= 5) {
        // Nessun effetto nonostante il puntore si muova: fallback manuale.
        slu_drag_state.manual = TRUE;
      }
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

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
  // Modalità standalone (gestore processi / aggiornamenti / appunti dal tray):
  // la dialog È la finestra. Niente header bar né decorazioni del WM: il
  // "contorno con titlebar" attorno alla card non serve e rende la finestra
  // diversa dalle dialog in-app. Il titolo resta per la window list del WM.
  const gchar* standalone_mode_env = g_getenv("SUPER_LINUX_UTILITY_MODE");
  const gboolean standalone_mode =
      (standalone_mode_env != nullptr && standalone_mode_env[0] != '\0');
  if (standalone_mode) {
    gtk_window_set_decorated(window, FALSE);
    gtk_window_set_title(window, "Super Linux Utility");
  } else if (use_header_bar) {
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
  // Standalone: pre-frame nello stesso colore della card delle dialog (M3
  // dark surfaceContainerHigh) per non far lampeggiare bianco prima del
  // primo frame Flutter; la finestra resta coerente con la card.
  const gchar* bg_hex = standalone_mode ? "#2B2930" : "#FFFFFF";
  gdk_rgba_parse(&background_color, bg_hex);
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Forza lo sfondo (bianco per la finestra principale, colore card per le
  // finestre standalone) per evitare che il tema GTK (es. Mint-Y su Cinnamon)
  // mostri uno sfondo celestino.
  GtkCssProvider* css_provider = gtk_css_provider_new();
  gchar css[256];
  g_snprintf(css, sizeof(css),
      "window { background-color: %s; }"
      "flutter_view { background-color: %s; }",
      bg_hex, bg_hex);
  gtk_css_provider_load_from_data(css_provider, css, -1, NULL);
  gtk_style_context_add_provider_for_screen(
      gtk_widget_get_screen(GTK_WIDGET(window)),
      GTK_STYLE_PROVIDER(css_provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(css_provider);

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Channel per spostare con il mouse le finestre standalone (drag da ogni
  // area non interattiva, gestito in Flutter da main.dart).
  if (self->slu_window_channel == nullptr) {
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    g_autoptr(FlPluginRegistrar) registrar =
        fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view),
                                                    "slu_window");
    self->slu_window_channel = fl_method_channel_new(
        fl_plugin_registrar_get_messenger(registrar),
        "com.superlinux.utility/window", FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(self->slu_window_channel,
                                              slu_window_method_call_cb,
                                              g_object_ref(window),
                                              g_object_unref);
  }

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
  g_clear_object(&self->slu_window_channel);
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
