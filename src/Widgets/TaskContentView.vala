/*
* Copyright (C) 2017-2020 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
namespace Notejot {
    public class Widgets.TaskContentView : WebKit.WebView {
        public MainWindow win;
        public string text = "";
        public int uid;

        public TaskContentView (MainWindow win, string text, int uid) {
            this.win = win;
            this.uid = uid;
            this.expand = true;
            this.text = text;
            this.set_can_default (false);
            this.get_style_context ().add_class ("notejot-tview");

            var settings = new WebKit.Settings ();
		    settings.set_enable_accelerated_2d_canvas(true);
		    settings.set_enable_html5_database(false);
		    settings.set_enable_html5_local_storage(false);
		    settings.set_enable_java(false);
		    settings.set_enable_media_stream(false);
		    settings.set_enable_page_cache(false);
		    settings.set_enable_plugins(false);
		    settings.set_enable_smooth_scrolling(true);
		    settings.set_javascript_can_access_clipboard(false);
		    settings.set_javascript_can_open_windows_automatically(false);
		    settings.set_media_playback_requires_user_gesture(true);

            update_html_view ();
            connect_signals ();

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                update_html_view ();
            });
        }

        public void connect_signals () {
            load_changed.connect ((event) => {
                if (event == WebKit.LoadEvent.COMMITTED) {
                    send_text ();
                    win.tm.save_notes.begin ();
                }
                if (event == WebKit.LoadEvent.FINISHED) {
                    send_text ();
                    win.tm.save_notes.begin ();
                }
            });
        }

        public void send_text () {
            run_javascript.begin("""document.body.innerHTML;""", null, (obj, res) => {
                try {
                    var data = run_javascript.end(res);
                    if (data != null && win != null) {
                        var val = data.get_js_value ().to_string ();
                        this.text = val == "" ? " " : val;
                        foreach (Gtk.FlowBoxChild item in win.gridview.get_tasks ()) {
                            if (((Widgets.TaskBox)item.get_child ()).uid == this.uid) {
                                ((Widgets.TaskBox)item.get_child ()).contents = val == "" ? " " : val;
                                this.text = val == "" ? " " : val;
                            }
                        }
                    }
                } catch (Error e) {
                    assert_not_reached ();
                }
            });
        }

        private string set_stylesheet () {
            if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                string dark = Styles.dark.css;
                return dark;
            } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                if (Notejot.Application.gsettings.get_boolean("dark-mode") == true) {
                    string dark = Styles.dark.css;
                    return dark;
                } else {
                    string normal = Styles.light.css;
                    return normal;
                }
            } else {
                string normal = Styles.light.css;
                return normal;
            }
        }

        public void update_html_view () {
            string style = set_stylesheet ();
            var html = """
            <!doctype html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <style>%s</style>
                </head>
                <body>%s</body>
            </html>""".printf(style, this.text);
            this.load_html (html, "file:///");
            win.tm.save_notes.begin ();
        }
    }
}