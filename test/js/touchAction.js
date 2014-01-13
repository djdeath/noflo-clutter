const Clutter = imports.gi.Clutter;

const Lang = imports.lang;
const Signals = imports.signals;

const TouchAction = new Lang.Class({
    Name: 'TouchAction',
    Extends: Clutter.GestureAction,

    _init: function(args) {
        this.parent(args);
        this.set_n_touch_points(1);
    },

    vfunc_gesture_begin: function(actor) {
        this.emit('touched');
        return Clutter.EVENT_PROPAGATE;
    },
});
Signals.addSignalMethods(TouchAction.prototype);

const DoubleTapAction = new Lang.Class({
    Name: 'DoubleTapAction',
    Extends: Clutter.GestureAction,

    _init: function(args) {
        this.parent(args);
        this.set_n_touch_points(1);
        this.lastTime = null;
    },

    vfunc_gesture_begin: function(actor) {
        let time = this.get_last_event(0).get_time();

        if ((this.lastTime != null) &&
            (time - this.lastTime) < 500)
            this.armed = true;

        this.lastTime = time;
        return true;
    },

    vfunc_gesture_cancel: function(actor) {
        this.lastTime = null;
        this.armed = false;
    },

    vfunc_gesture_end: function(actor) {
        if (this.armed) {
            this.armed = false;
            this.emit('double-tap');
        }
    },
});
Signals.addSignalMethods(DoubleTapAction.prototype);
