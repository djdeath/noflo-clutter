const Clutter = imports.gi.Clutter;
const GObject = imports.gi.GObject;
const St = imports.gi.St;

const Lang = imports.lang;
const Signals = imports.signals;
const ApplicationManager = imports.applicationManager;
const Util = imports.util;
const WindowManager = imports.windowManager;

const PanelButton = new Lang.Class({
    Name: 'PanelButton',
    Extends: St.Button,

    _init: function(_args) {
        let args = Util.parseProps(_args, { applicationId: 'unknown', });
        this.parent(Util.mergeProps(_args, { style_class: 'panelButton', }));

        let box = new St.BoxLayout({ vertical: false, });
        this.child = box;
        this.x_fill = this.y_fill = true;

        this.icon = new St.Widget({ style_class: args.applicationId + 'PanelIcon' });
        box.add(this.icon, { expand: true, });
        this.status = new St.Widget({ style_class: 'appButtonStatus' });
        box.add(this.status, { expand: false, });
    },

    setRunning: function(value) {
        if (value) {
            this.status.add_style_pseudo_class('running');
            this.icon.add_style_pseudo_class('running');
        } else {
            this.icon.remove_style_pseudo_class('running');
            this.icon.remove_style_pseudo_class('minimized');
            this.status.remove_style_pseudo_class('running');
            this.status.remove_style_pseudo_class('minimized');
            this._triggerMinimizedAnimation(false);
        }
    },

    setMinimized: function(value) {
        if (value) {
            this.icon.add_style_pseudo_class('minimized');
            this.status.add_style_pseudo_class('minimized');
        } else {
            this.icon.remove_style_pseudo_class('minimized');
            this.status.remove_style_pseudo_class('minimized');
        }
        this._triggerMinimizedAnimation(value);
    },

    _triggerMinimizedAnimation: function(value) {
        if (value) {
            this.save_easing_state();
            this.set_easing_delay(500);
            this.set_easing_duration(200);
            this.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUINT);
            this.translation_x = 10;
            this.opacity = 128;
            this.restore_easing_state();
        } else {
            this.save_easing_state();
            this.set_easing_delay(300);
            this.set_easing_duration(200);
            this.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUINT);
            this.translation_x = 0;
            this.opacity = 255;
            this.restore_easing_state();
        }
    },
});

/**/

const DrawerButton = new Lang.Class({
    Name: 'DrawerButton',
    Extends: St.BoxLayout,

    _init: function(_args) {
        let args = Util.parseProps(_args, { applicationId: 'unknown',
                                            applicationName: 'Unknown', });
        this.parent(Util.mergeProps(_args, { style_class: 'drawerButton', }));

        this.vertical = true;

        this.button = new PanelButton({ applicationId: args.applicationId, });
        this.add(this.button,
                 { x_fill: false, x_align: St.Align.MIDDLE, });
        this.add(new St.Label({ text: args.applicationName, }),
                 { x_fill: false, x_align: St.Align.MIDDLE, });

    },
});

const DrawerBox = new Lang.Class({
    Name: 'DrawerBox',
    Extends: St.Table,

    Signals: {
        'application-clicked': { flags: GObject.SignalFlags.RUN_LAST,
                                 param_types: [ GObject.TYPE_OBJECT,
                                                GObject.TYPE_STRING, ], },
    },

    _init: function(args) {
        this.parent(Util.mergeProps(args,
                                    {
                                        style_class: 'panelDrawerBox',
                                        reactive: true,
                                    }));

        this.apps = {};

        let appsManager = ApplicationManager.getDefault();
        let row = 0;
        let col = 0;
        for (let i in appsManager.orderedApplications) {
            let app = appsManager.orderedApplications[i];
            let button = new DrawerButton({ applicationId: app.id,
                                            applicationName: app.title, });
            button.app = app;

            this.apps[app.id] = button;

            this.add(button, { row: row, col: col++, });

            button.button.connect('clicked', Lang.bind(this, function(widget) {
                this.emit('application-clicked', widget, button.app.id);
            }));

            if (col > 3) {
                col = 0;
                row++;
            }
        }
    },

    vfunc_event: function(event) {
        return true;
    },

    setRunning: function(applicationId, value) {
        let button = this.apps[applicationId];
        if (!button)
            return;

        button.button.set_reactive(!value);
        if (value)
            button.button.add_style_pseudo_class('unsensitive');
        else
            button.button.remove_style_pseudo_class('unsensitive');
    },
});

const Drawer = new Lang.Class({
    Name: 'Drawer',
    Extends: St.Bin,

    Signals: {
        'application-clicked': { flags: GObject.SignalFlags.RUN_LAST,
                                 param_types: [ GObject.TYPE_OBJECT,
                                                GObject.TYPE_STRING, ], },
    },

    _init: function(args) {
        this.parent(Util.mergeProps(args,
                                    {
                                        style_class: 'panelDrawer',
                                        x_fill: true,
                                        y_fill: true,
                                        x_expand: true,
                                        y_expand: true,

                                    }));

        this._box = new DrawerBox();
        this.child = this._box;

        this._box.connect('application-clicked', Lang.bind(this, function(box, widget, applicationId) {
            this.emit('application-clicked', widget, applicationId);
        }));
    },

    setRunning: function(applicationId, value) {
        this._box.setRunning(applicationId, value);
    },
});

/**/

const Panel = new Lang.Class({
    Name: 'Panel',
    Extends: St.BoxLayout,

    Signals: {
        'drawer-application-clicked': { flags: GObject.SignalFlags.RUN_LAST,
                                        param_types: [ GObject.TYPE_OBJECT,
                                                       GObject.TYPE_STRING, ], },
        'drawer-clicked': { flags: GObject.SignalFlags.RUN_LAST,
                            param_types: [ GObject.TYPE_OBJECT,
                                           GObject.TYPE_OBJECT, ], },
        'application-clicked': { flags: GObject.SignalFlags.RUN_LAST,
                                 param_types: [ GObject.TYPE_STRING, ], },
    },

    _init: function(args) {
        this.parent(Util.mergeProps(args,
                                    {
                                        vertical: true,
                                        style_class: 'panel',
                                    }));

        this.apps = {};

        // let appsManager = ApplicationManager.getDefault();
        // for (let i in appsManager.orderedApplications) {
        //     let app = appsManager.orderedApplications[i];
        //     let button = new PanelButton({ applicationId: app.id, });
        //     button.app = app;

        //     this.apps[app.id] = button;

        //     this.add(button, { x_fill: true, y_fill: true, });

        //     button.connect('clicked', Lang.bind(this, function(widget) {
        //         this.emit('application-clicked', widget.app.id);
        //     }));
        // }

        this.drawer = new Drawer({});
        this.drawer.hide()
        this.drawer.connect('application-clicked', Lang.bind(this, function(widget, button, applicationId) {
            this.emit('drawer-application-clicked', button, applicationId);
        }));

        let button = new PanelButton({ applicationId: 'drawer', });
        this.add(button, { x_fill: true, y_fill: true, });
        button.connect('clicked', Lang.bind(this, function(widget) {
            this.emit('drawer-clicked', button, this.drawer);
        }));
    },

    getApplicationButton: function(applicationId) {
        return this.apps[applicationId];
    },

    setRunning: function(applicationId, value) {
        let button = this.apps[applicationId];

        if (value) {
            if (button)
                return;

            button = new PanelButton({ applicationId: applicationId, });
            this.apps[applicationId] = button;
            button.connect('clicked', Lang.bind(this, function(widget) {
                this.emit('application-clicked', applicationId);
            }));
            this.add(button, { x_fill: true, y_fill: true, });
            this.set_child_below_sibling(button, null);
            button.setRunning(true);
        } else {
            if (!button)
                return;

            button.destroy();
            delete this.apps[applicationId];
        }

        this.drawer.setRunning(applicationId, value);
    },

    setMinimized: function(applicationId, value) {
        let button = this.apps[applicationId];
        if (button)
            button.setMinimized(value);
    },
});

/**/

let _panel = null;
let getDefault = function() {
    if (_panel == null) {
        _panel = new Panel();
    }
    return _panel;
};
