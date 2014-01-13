const Clutter = imports.gi.Clutter;
const St = imports.gi.St;

const Lang = imports.lang;
const Signals = imports.signals;
const Util = imports.util;
const Window = imports.ui.window;

const Tweener = imports.ui.tweener;

const ONE_THIRD = 1.0 / 3.0;
const TWO_THIRD = 2.0 / 3.0;

let normalizeRatios = function(ratX, ratY) {
    return [ (ratX < ONE_THIRD ? -1 : (ratX > TWO_THIRD ? 1 : 0)),
             (ratY < ONE_THIRD ? -1 : (ratY > TWO_THIRD ? 1 : 0)) ];
};

const RESIZE_CORNER_SIZE = 40;
let positionsToNormalizedRatios = function(x, y, width, height) {
    let ret = [];

    if (x < RESIZE_CORNER_SIZE)
        ret.push(-1);
    else if ((width - x) < RESIZE_CORNER_SIZE)
        ret.push(1);
    else
        ret.push(0);
    if (y < RESIZE_CORNER_SIZE)
        ret.push(-1);
    else if ((height - y) < RESIZE_CORNER_SIZE)
        ret.push(1);
    else
        ret.push(0);

    return ret;
};

const WindowManager = new Lang.Class({
    Name: 'WindowManager',

    _init: function(args) {
        this.windows = [];          /* Windows stored in reverse stacking order */
        this.visibleWindows = [];   /* Windows stored in reverse stacking order */
        this.minimizedWindows = []; /* Windows stored in reverse stacking order */

        this._shellwm = args.shellwm;

        this.windowsArea = new St.Widget({
            name: 'windowsArea',
            style_class: 'windowsArea',
        });

        this.windowsArea.connect('allocation-changed', Lang.bind(this, function(actor, box, flags) {
            this.emit('windows-area-update', box.get_width(), box.get_height());
        }));


        if (this._shellwm) {
            this._shellwm.connect('map', Lang.bind(this, this._shellMapWindow));
            this._shellwm.connect('destroy', Lang.bind(this, this._shellDestroyWindow));
        }

        this._id = 0;
    },

    /**/

    _shellMapWindow: function(shellwm, actor) {
        log('map window ! ' + actor);
        if (actor.get_parent() != null)
            actor.get_parent().remove_child(actor);
        actor.show();

        let meta = actor.get_meta_window();

        let applicationId = meta.get_gtk_application_id();
        let win = this.createWindow(meta.get_title(), applicationId == null ? 'unknown' : applicationId, actor);

        actor.windowChrome = win;

        shellwm.completed_map(actor);
    },

    _shellDestroyWindow: function(shellwm, actor) {
        this.destroyWindow(actor.windowChrome);
        shellwm.completed_destroy(actor);
    },

    /**/

    reinit: function() {
        this.emit('windows-area-update', this.windowsArea.width, this.windowsArea.height);
        this.emit('windows-list-update');
        this.emit('visible-windows-list-update');
        this.emit('minimized-windows-list-update');
    },

    _getId: function() {
        return 'window-' + this._id++;
    },

    _addWindow: function(win) {
        this.windows.push(win);
        this.visibleWindows.push(win);
    },

    createWindow: function(title, applicationId, content) {
        let win = new Window.Window({ id: this._getId() + '-' + applicationId,
                                      title: title,
                                      applicationId: applicationId,
                                      content: content });
        this._addWindow(win);

        /**/
        win.moveBeginId = win.moveAction.connect('drag-begin', Lang.bind(this, function() {
            this.emit('move-begin', win);
        }));
        win.moveEndId = win.moveAction.connect('drag-end', Lang.bind(this, function() {
            this.emit('move-end', win);
        }));
        win.moveUpdateId = win.moveAction.connect('drag-progress', Lang.bind(this, function(action) {
            let [pressX, pressY] = action.get_press_coords();
            let [motionX, motionY] = action.get_motion_coords();

            this.emit('move-update', win, motionX - pressX, motionY - pressY);
        }));

        /**/
        win.resizeBeginId = win.resizeAction.connect('drag-begin', Lang.bind(this, function(action, actor, eventX, eventY, modifiers) {
            let [transX, transY] = win.get_transformed_position();
            let normalizedRatios = positionsToNormalizedRatios(eventX - transX, eventY - transY,
                                                               actor.width, actor.height);

            win.setResizeRatios(normalizedRatios[0], normalizedRatios[1]);
            this.emit('pre-resize-end', win);
            this.emit('resize-begin', win, normalizedRatios[0], normalizedRatios[1]);
        }));
        win.resizeEndId = win.resizeAction.connect('drag-end', Lang.bind(this, function() {
            win.setResizeRatios(0, 0);
            this.emit('resize-end', win);
        }));
        win.resizeUpdateId = win.resizeAction.connect('drag-progress', Lang.bind(this, function(action) {
            let [pressX, pressY] = action.get_press_coords();
            let [motionX, motionY] = action.get_motion_coords();

            this.emit('resize-update', win, motionX - pressX, motionY - pressY);
        }));

        /**/
        win.enterId = win.connect('enter-event', Lang.bind(this, function(actor, event) {
            let [eventX, eventY] = event.get_coords();
            let [transX, transY] = win.get_transformed_position();
            let normalizedRatios = positionsToNormalizedRatios(eventX - transX,
                                                               eventY - transY,
                                                               actor.width,
                                                               actor.height);

            this.emit('pre-resize-begin', win, normalizedRatios[0], normalizedRatios[1]);
            return true;
        }));
        win.motionId = win.connect('motion-event', Lang.bind(this, function(actor, event) {
            let [eventX, eventY] = event.get_coords();
            let [transX, transY] = win.get_transformed_position();
            let normalizedRatios = positionsToNormalizedRatios(eventX - transX,
                                                               eventY - transY,
                                                               actor.width,
                                                               actor.height);

            this.emit('pre-resize-begin', win, normalizedRatios[0], normalizedRatios[1]);
            return true;
        }));
        win.leaveId = win.connect('leave-event', Lang.bind(this, function(actor, event) {
            this.emit('pre-resize-end', win);
            return false;
        }));
        win.enterInnerId = win.inner.connect('enter-event', Lang.bind(this, function(actor, event) {
            this.emit('pre-resize-end', win);
            return true;
        }));

        /**/
        let clickedWindow = function() {
            this.emit('clicked-window', win);
        };

        win.touchTitleBarActionId = win.touchTitleBarAction.connect('touched', Lang.bind(this, clickedWindow));
        win.touchContentActionId = win.touchContentAction.connect('touched', Lang.bind(this, clickedWindow));
        win.touchWindowActionId = win.touchWindowAction.connect('touched', Lang.bind(this, clickedWindow));

        /**/
        let toggleMaximize = function() {
            if (win.maximized)
                this.emit('unmaximize-window', win);
            else
                this.emit('maximize-window', win);
        };

        win.maximizeId = win.getMaximizeButton().connect('clicked', Lang.bind(this, toggleMaximize));
        win.maximizeTitlebarId = win.doubleTapTitleBarAction.connect('double-tap', Lang.bind(this, toggleMaximize));


        win.minimizeId = win.getMinimizeButton().connect('clicked', Lang.bind(this, function() {
            this.emit('minimize-window', win);
        }));

        win.closeId = win.getCloseButton().connect('clicked', Lang.bind(this, function() {
            this.emit('close-window', win);
        }));

        this.windowsArea.add_child(win);
        this.emit('windows-list-update');
        this.emit('visible-windows-list-update');
        this.emit('add-window', win);

        return win;
    },

    destroyWindow: function(win) {
        if (win.inner.windowContent.windowChrome == win) {
            let actor = win.inner.windowContent;
            let metaWin = actor.get_meta_window();
            actor.get_parent().remove_child(actor);
            metaWin.delete(global.get_current_time());
        }

        win.moveAction.disconnect(win.moveBeginId);
        win.moveAction.disconnect(win.moveEndId);
        win.moveAction.disconnect(win.moveUpdateId);

        win.resizeAction.disconnect(win.resizeBeginId);
        win.resizeAction.disconnect(win.resizeEndId);
        win.resizeAction.disconnect(win.resizeUpdateId);

        win.inner.disconnect(win.enterInnerId);
        win.disconnect(win.enterId);
        win.disconnect(win.leaveId);
        win.disconnect(win.motionId);

        win.touchTitleBarAction.disconnect(win.touchTitleBarActionId);
        win.touchContentAction.disconnect(win.touchContentActionId);
        win.touchWindowAction.disconnect(win.touchWindowActionId);

        win.doubleTapTitleBarAction.disconnect(win.maximizeTitlebarId);
        win.getMaximizeButton().disconnect(win.maximizeId);
        win.getMinimizeButton().disconnect(win.minimizeId);
        win.getCloseButton().disconnect(win.closeId);

        let winIndex = this.windows.indexOf(win);
        if (winIndex >= 0) {
            this.windows.splice(winIndex, 1);
            this.emit('windows-list-update');

            winIndex = this.visibleWindows.indexOf(win);
            if (winIndex >= 0) {
                this.visibleWindows.splice(winIndex, 1);
                this.emit('visible-windows-list-update');
            }

            winIndex = this.minimizedWindows.indexOf(win);
            if (winIndex >= 0) {
                this.minimizedWindows.splice(winIndex, 1);
                this.emit('minimized-windows-list-update');
            }
        }

        win.destroy();
    },

    raiseWindow: function(win) {
        let winIndex = this.windows.indexOf(win);
        if (winIndex >= 0 && winIndex != (this.windows.length - 1)) {
            win.get_parent().set_child_above_sibling(win, null);
            this.windows.splice(winIndex, 1);
            this.windows.push(win);
            this.emit('windows-list-update');

            winIndex = this.visibleWindows.indexOf(win);
            if (winIndex >= 0 && winIndex != (this.visibleWindows.length - 1)) {
                this.visibleWindows.splice(winIndex, 1);
                this.visibleWindows.push(win);
                this.emit('visible-windows-list-update');
            }

            winIndex = this.minimizedWindows.indexOf(win);
            if (winIndex >= 0 && winIndex != (this.minimizedWindows.length - 1)) {
                this.minimizedWindows.splice(winIndex, 1);
                this.minimizedWindows.push(win);
                this.emit('minimized-windows-list-update');
            }
        }
    },

    maximized: function(win) {
    },

    unmaximized: function(win) {
    },


    minimized: function(win) {
        let winIndex = this.visibleWindows.indexOf(win);
        if (winIndex < 0)
            return;

        this.visibleWindows.splice(winIndex, 1);
        this.minimizedWindows.push(win);
        this.emit('visible-windows-list-update');
        this.emit('minimized-windows-list-update');
    },

    unminimized: function(win) {
        let winIndex = this.minimizedWindows.indexOf(win);
        if (winIndex < 0)
            return;

        // Also update the global window list to reflect the
        // implicit raise.
        this.windows.splice(this.windows.indexOf(win), 1);
        this.windows.push(win);
        this.emit('windows-list-update');

        this.minimizedWindows.splice(winIndex, 1);
        this.visibleWindows.push(win);
        this.emit('visible-windows-list-update');
        this.emit('minimized-windows-list-update');
    },
});
Signals.addSignalMethods(WindowManager.prototype);

let _windowManager = null;
let getDefault = function() {
    if (_windowManager == null) {
        _windowManager = new WindowManager({ shellwm: global.window_manager, });
    }
    return _windowManager;
};
