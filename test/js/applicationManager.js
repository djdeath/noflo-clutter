const Config = imports.config;
const Lang = imports.lang;
const Signals = imports.signals;
const Util = imports.util;
const WindowManager = imports.windowManager;

const ApplicationManager = new Lang.Class({
    Name: 'ApplicationManager',

    _APPS: [
        { title: 'Chrome',
          id: 'chrome', },
        { title: 'Dropbox',
          id: 'dropbox', },
        { title: 'Evernote',
          id: 'evernote', },
        { title: 'Facebook',
          id: 'facebook', },
        { title: 'Google+',
          id: 'gplus', },
        { title: 'Maps',
          id: 'maps', },
        { title: 'Pinterest',
          id: 'pinterest', },
        { title: 'Skype',
          id: 'skype', },
        { title: 'Spotify',
          id: 'spotify', },
        { title: 'Twitter',
          id: 'twitter', },
    ],

    _GNOME_APPS: [
        { title: 'Calculator',
          id: 'calculator', },
        { title: 'Camera',
          id: 'camera', },
        { title: 'Files',
          id: 'files', },
        { title: 'Rhythmbox',
          id: 'rhythmbox', },
        { title: 'Terminal',
          id: 'terminal', },
        { title: 'Weather',
          id: 'weather', },
        { title: 'Web',
          id: 'web', },
    ],

    _init: function(args) {
        this.orderedApplications = [];
        this._applications = {}

        let apps = Config.GNOME ? this._GNOME_APPS : this._APPS;

        for (let i in apps) {
            this.orderedApplications.push(apps[i]);
            this._applications[apps[i].id] = apps[i];
        }
    },

    startApplication: function(applicationId) {
        log('starting : ' + applicationId);
        let app = this._applications[applicationId];
        if (app) {
            let windowManager = WindowManager.getDefault();
            windowManager.createWindow(app.title, app.id, null);
            this.emit('application-started', app.id);
        } else {
            log('Cannot find application : ' + applicationId);
        }
    },
});
Signals.addSignalMethods(ApplicationManager.prototype);

let _manager = null;
let getDefault = function() {
    if (_manager == null) {
        _manager = new ApplicationManager();
    }
    return _manager;
};
