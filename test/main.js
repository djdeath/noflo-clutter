const Config = imports.config;
const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Clutter = imports.gi.Clutter;
const Gdk = imports.gi.Gdk;
const Gtk = imports.gi.Gtk;
const St = imports.gi.St;

const Lang = imports.lang;
const Mainloop = imports.mainloop;

const UI = imports.testcommon.ui;
const MainBar = imports.ui.mainBar;
const Panel = imports.ui.panel;
const Window = imports.ui.window;
const WindowManager = imports.windowManager;
const WebUIServer = imports.webUiServer;

/* NoFlo glue */
let NoFloContext = imports.browser['noflo-clutter'];
NoFloContext.setTimeout = function(cb, time) {
    return GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
        cb();
        return false;
    }, null, null);
};
NoFloContext.setInterval = function(cb, time) {
    return GLib.timeout_add(GLib.PRIORITY_DEFAULT, time, function() {
        cb();
        return true;
    }, null, null);
};
NoFloContext.clearTimeout = function(id) {
    if (id > 0)
        GLib.source_remove(id);
};
NoFloContext.clearInterval = NoFloContext.clearTimeout;
const NoFlo = NoFloContext.require('noflo-clutter');

/**/

let stage = new Clutter.Stage({
//    background_color: Clutter.Color.from_string('#4d4545')[1],
    user_resizable: true,
});
UI.init(stage);
stage.show();
stage.hide_cursor();
//stage.set_fullscreen(true);

let display = Gdk.Display.get_default();
let screen = display.get_screen(0);

let _hideCursorTimeout = null
let startHideCursorTimeout = function() {
    _hideCursorTimeout = Mainloop.timeout_add_seconds(5, Lang.bind(this, function() {
        stage.hide_cursor();
        _hideCursorTimeout = null;
        return false;
    }));
};
let showCursor = function() {
    if (_hideCursorTimeout) {
        Mainloop.source_remove(_hideCursorTimeout);
        _hideCursorTimeout = null;
    }
    stage.show_cursor();
};

stage.connect('captured-event', Lang.bind(this, function(actor, event) {
    switch (event.type()) {
    case Clutter.EventType.BUTTON_PRESS:
    case Clutter.EventType.BUTTON_RELEASE:
    case Clutter.EventType.MOTION:
        if (event.is_pointer_emulated())
            return true;
        showCursor();
        startHideCursorTimeout();
        return false;

    case Clutter.EventType.KEY_PRESS:
        if (event.get_key_symbol() == Clutter.KEY_s)
            switchGraphs();
        return false;
    }

    return false
}));


/**/

let stylesheetPath = GLib.getenv("PWD") + (Config.GNOME ? '/gnome.css' : '/proto.css');

let reloadTheme = function() {
    try
    {
	let context = St.ThemeContext.get_for_stage(stage);
	let theme = new St.Theme({});
	theme.load_stylesheet(stylesheetPath);
	context.set_theme(theme);
	log('theme successfully loaded');
    } catch (ex) {
	log(ex.message);
    }
};
reloadTheme();

let stylesheetFileMonitor = Gio.File.new_for_path(stylesheetPath).monitor_file(Gio.FileMonitorFlags.NONE, null);
stylesheetFileMonitor.connect('changed', Lang.bind(this, function() {
    reloadTheme();
}));

/**/

let mainBox = new St.BoxLayout({ vertical: true,
                                 style_class: 'backgroundArea', });
stage.add_child(mainBox);
let resizeMainBox = function() {
    mainBox.set_size(stage.get_width(), stage.get_height());
};
stage.connect('allocation-changed', Lang.bind(this, resizeMainBox));
resizeMainBox();

let workBox = new St.BoxLayout({ vertical: false, });
mainBox.add(workBox, { x_fill: true,
                       expand: true, });

/* Window management stuff */

let windowManager = WindowManager.getDefault();
workBox.add(windowManager.windowsArea, { x_fill: true,
                                         y_fill: true,
                                         expand: true, });

let windowMoveGhost = new Window.Window({ name: 'ghostWindow', });
windowMoveGhost.hide();
windowMoveGhost.add_style_pseudo_class('ghost');
windowManager.windowsArea.add_child(windowMoveGhost);

/* Panel */

let panel = Panel.getDefault();

let panelContainer = new St.Bin({ style_class: 'panelContainer', });
workBox.add(panelContainer, { y_fill: true, expand: false, });
panelContainer.child = panel;
panelContainer.x_fill = panelContainer.y_fill = true;

let drawerLayer = new St.Widget({ name: 'drawerLayer', style_class: 'drawerLayer', reactive: false });
stage.add_child(drawerLayer);
drawerLayer.add_constraint(new Clutter.BindConstraint({ source: stage,
                                                        coordinate: Clutter.BindCoordinate.SIZE, }));

drawerLayer.add_child(panel.drawer);

/* Fake Android bar */

let bottomBar = new MainBar.MainBar({});
mainBox.add(bottomBar, { x_fill: true,
                         expand: false, });

/* Graph */

// let currentNetwork = null;
// let currentGraph = null;

// let loadGraph = function(filename) {
//     if (currentNetwork) {
//         log('stopping previous network');
//         currentNetwork.stop();
//         currentNetwork = null;
//     }

//     log('loading graph ' + filename);
//     currentGraph = filename;

//     let file = Gio.File.new_for_path(filename);
//     let [, content] = file.load_contents(null);
//     NoFlo.graph.loadFBP('' + content, function (graph) {
//         graph.baseDir = '/noflo-clutter';
//         log('Graph loaded');

//         NoFlo.createNetwork(graph, function (network) {
//             log("Network created");
//             currentNetwork = network;
//             currentNetwork.start();
//             windowManager.reinit();
//         });
//     });
// };

// let switchGraphs = function() {
//     loadGraph(currentGraph == './windowmanager-overlay.fbp' ? './windowmanager-unconstrained.fbp' : './windowmanager-overlay.fbp');
// };

// loadGraph(Config.GNOME ? './windowmanager-overlay.fbp' : './windowmanager-unconstrained.fbp');

/**/

WebUIServer.getDefault().start();

/**/

UI.main(stage);
