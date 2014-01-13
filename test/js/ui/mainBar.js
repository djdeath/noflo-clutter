const Clutter = imports.gi.Clutter;
const St = imports.gi.St;

const Lang = imports.lang;
const Signals = imports.signals;

const MainBar = new Lang.Class({
    Name: 'MainBar',
    Extends: St.Bin,

    _init: function() {
	this.parent({ y_fill: true,
                      x_fill: false,
                      x_align: St.Align.MIDDLE,
                    });
	this.style_class = 'mainBar';

        this._box = new St.BoxLayout();
        this.set_child(this._box);

        let back = new St.Button({ style_class: 'mainBarBackButton', });
        let home = new St.Button({ style_class: 'mainBarHomeButton', });
        let wins = new St.Button({ style_class: 'mainBarWindowsButton', });
        this._addButton(back);
	this._addButton(home);
        this._addButton(wins);

        back.connect('clicked', Lang.bind(this, function() {
            this.emit('back-clicked');
        }));

    },

    _addButton: function(button) {
        this._box.add(button, { x_fill: true, y_align: St.Align.MIDDLE });
    },

});
Signals.addSignalMethods(MainBar.prototype);
