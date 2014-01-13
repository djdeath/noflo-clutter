const Config = imports.config;

const Clutter = imports.gi.Clutter;
const Gdk = imports.gi.Gdk;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Lang = imports.lang;
const Mainloop = imports.mainloop;
const Meta = imports.gi.Meta;
const Shell = imports.gi.Shell;
const St = imports.gi.St;

const MainBar = imports.ui.mainBar;
const Panel = imports.ui.panel;
const Window = imports.ui.window;
const WindowManager = imports.windowManager;

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

let currentTheme = null;
let themeStylesheetMonitor = null;
let themeStylesheetMonitorId = null;

let reloadTheme = function(updateMonitor) {
    let getThemePath = function() {
        return '/home/djdeath/src/noflo/noflo-clutter/test/' + currentTheme + '.css';
    };

    if (updateMonitor && themeStylesheetMonitor) {
        themeStylesheetMonitor.disconnect(themeStylesheetMonitorId);
        themeStylesheetMonitor = null;
        themeStylesheetMonitorId = null;
    }

    try {
        let themePath = getThemePath();
	let context = St.ThemeContext.get_for_stage(global.stage);
	let theme = new St.Theme({});
	theme.load_stylesheet(themePath);
	context.set_theme(theme);
	log('theme successfully loaded');

        if (themeStylesheetMonitor == null) {
            themeStylesheetMonitor = Gio.File.new_for_path(themePath).monitor_file(Gio.FileMonitorFlags.NONE, null);
            themeStylesheetMonitorId = themeStylesheetMonitor.connect('changed', Lang.bind(this, function() {
                reloadTheme(true);
            }));
        }
    } catch (ex) {
	log(ex.message);
    }
};

let switchThemes = function() {
    if (currentTheme == null)
        currentTheme = Config.GNOME ? 'gnome' : 'proto';
    else if (currentTheme == 'gnome')
        currentTheme = 'proto';
    else
        currentTheme = 'gnome';
    reloadTheme();
};

/**/

let setupUI = function(stage) {
    stage.user_resizable = true;

    /**/

    let mainBox = new St.BoxLayout({ vertical: true,
                                     style_class: 'backgroundArea', });
    stage.add_child(mainBox);
    let resizeMainBox = function() {
        log(' stage resize : ' + stage.get_width() + 'x' + stage.get_height());
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

    // windowManager.connect('pre-resize-begin', Lang.bind(this, function(manager, win, ratioX, ratioY) {
    //     let gdkWindow = screen.get_active_window();
    //     let cursorType = Gdk.CursorType.LEFT_PTR;
    //     if (ratioX < 0) {
    //         if (ratioY > 0)
    //             cursorType = Gdk.CursorType.BOTTOM_LEFT_CORNER;
    //         else if (ratioY < 0)
    //             cursorType = Gdk.CursorType.TOP_LEFT_CORNER;
    //         else
    //             cursorType = Gdk.CursorType.LEFT_SIDE;
    //     } else if (ratioX > 0) {
    //         if (ratioY > 0)
    //             cursorType = Gdk.CursorType.BOTTOM_RIGHT_CORNER;
    //         else if (ratioY < 0)
    //             cursorType = Gdk.CursorType.TOP_RIGHT_CORNER;
    //         else
    //             cursorType = Gdk.CursorType.RIGHT_SIDE;
    //     } else if (ratioX == 0) {
    //         if (ratioY < 0)
    //             cursorType = Gdk.CursorType.TOP_SIDE;
    //         else if (ratioY > 0)
    //             cursorType = Gdk.CursorType.BOTTOM_SIDE;
    //     }
    //     gdkWindow.set_cursor(Gdk.Cursor.new_for_display(display, cursorType));
    //     win.setResizeRatios(ratioX, ratioY);
    // }));

    // windowManager.connect('pre-resize-end', Lang.bind(this, function(manager, win, ratioX, ratioY) {
    //     let gdkWindow = screen.get_active_window();
    //     gdkWindow.set_cursor(Gdk.Cursor.new_for_display(display, Gdk.CursorType.LEFT_PTR));
    //     win.setResizeRatios(0, 0);
    // }));

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
};

/**/

/* Graph */

let currentNetwork = null;
let currentGraph = null;

let loadGraph = function(filename) {
    if (currentNetwork) {
        log('stopping previous network');
        currentNetwork.stop();
        currentNetwork = null;
    }

    log('loading graph ' + filename);
    currentGraph = filename;

    let file = Gio.File.new_for_path('/home/djdeath/src/noflo/noflo-clutter/test/' + filename);
    let [, content] = file.load_contents(null);
    NoFlo.graph.loadFBP('' + content, function (graph) {
        graph.baseDir = '/noflo-clutter';
        log('Graph loaded');

        NoFlo.createNetwork(graph, function (network) {
            log("Network created");
            currentNetwork = network;
            currentNetwork.start();
            WindowManager.getDefault().reinit();
        });
    });
};

let switchGraphs = function() {
    loadGraph(currentGraph == './windowmanager-overlay.fbp' ? './windowmanager-unconstrained.fbp' : './windowmanager-overlay.fbp');
};

/**/

function start() {
    // These are here so we don't break compatibility.
    global.logError = window.log;
    global.log = window.log;

    if (!Meta.is_wayland_compositor)
        Meta.is_wayland_compositor = function () { return false; };

    // Chain up async errors reported from C
    global.connect('notify-error', function (global, msg, detail) { notifyError(msg, detail); });

    Gio.DesktopAppInfo.set_desktop_env('GNOME');


    /* Load theme */
    switchThemes();

    /* Setup UI */
    setupUI(global.stage);

    loadGraph(Config.GNOME ? 'windowmanager-overlay.fbp' : 'windowmanager-unconstrained.fbp');
}
