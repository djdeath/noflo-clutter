const GLib = imports.gi.GLib;
const GObject = imports.gi.GObject;
const Gio = imports.gi.Gio;
const Gdk = imports.gi.Gdk;
const Gtk = imports.gi.Gtk;
const Clutter = imports.gi.Clutter;
const Cogl = imports.gi.Cogl;
const Lang = imports.lang;
const Signals = imports.signals;
const Mainloop = imports.mainloop;

const WebUIServer = imports.webUiServer;
const WebProtoServer = imports.webProtoServer;

/**/

WebUIServer.getDefault().start();
WebProtoServer.getDefault().start();

/**/

Clutter.init(null, null);

let stage = new Clutter.Stage({ width: 800,
                                height: 600,
                                background_color: new Clutter.Color({ alpha: 0xff,
                                                                      red: 0,
                                                                      green: 0,
                                                                      blue: 0 }),
                              });
stage.show();


let actor = new Clutter.Actor({ width: 400,
                                height: 400,
                                name: 'test',
                              });
stage.add_child(actor);


Clutter.main();
