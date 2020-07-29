/*
* Copyright (c) 2018-2020 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
    public class Services.TaskManager {
        public MainWindow win;
        public Json.Builder builder;
        private string file_name = Environment.get_user_data_dir () +
                                 "/com.github.lainsce.notejot" +
                                 "/saved_notes.json";
        private string app_directory = Environment.get_user_data_dir () +
                                       "/com.github.lainsce.notejot";

        public TaskManager (MainWindow win) {
            this.win = win;
        }

        public void save_notes () {
            string json_string = prepare_json_from_notes();
            var file = File.new_for_path (file_name);
            var dir = File.new_for_path (app_directory);
            try {
                if (!dir.query_exists()) {
                    dir.make_directory();
                }
                if (file.query_exists ()) {
                    file.delete ();
                }
                var file_stream = file.create (
                                        FileCreateFlags.REPLACE_DESTINATION
                                        );
                var data_stream = new DataOutputStream (file_stream);
                data_stream.put_string(json_string);
            } catch (Error e) {
                warning ("Failed to save timetable: %s\n", e.message);
            }

        }

        private string prepare_json_from_notes () {
            builder = new Json.Builder ();

            builder.begin_array ();
            save_note (builder, win);
            builder.end_array ();

            Json.Generator generator = new Json.Generator ();
            Json.Node root = builder.get_root ();
            generator.set_root (root);
            string str = generator.to_data (null);
            return str;
        }

        private static void save_note (Json.Builder builder, MainWindow win) {
            if (win.main_list != null) {
                foreach (var note in win.main_list) {
                    builder.begin_array ();
                    builder.add_string_value (note.title);
                    builder.add_string_value (note.contents);
                    builder.add_string_value (note.color);
                    builder.end_array ();
                }
            }
            
        }

        public void load_from_file () {
            try {
                var file = File.new_for_path(file_name);
                var json_string = "";
                if (file.query_exists() && win.listview != null) {
                    string line;
                    var dis = new DataInputStream (file.read ());
                    while ((line = dis.read_line (null)) != null) {
                        json_string += line;
                    }
                    var parser = new Json.Parser();
                    parser.load_from_data(json_string);
                    var root = parser.get_root();
                    var array = root.get_array();
                    foreach (var tasks in array.get_elements()) {
                        var task = tasks.get_array ();
                        string title = task.get_string_element(0);
                        string contents = task.get_string_element(1);
                        string color = task.get_string_element(2);

                        win.add_task (title, contents, color);
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }
    }
}

