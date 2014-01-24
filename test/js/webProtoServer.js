const Lang = imports.lang;

const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Soup = imports.gi.Soup;

/**/

const WebProtoServer = new Lang.Class({
    Name: 'WebProtoServer',

    _init: function(args) {
        this.connection = null;
        this.signals = [];

        this.server = new Soup.Server({ port: args.port, });
        this.server.add_websocket_handler(null, Lang.bind(this, this.mainHandler));
    },

    mainHandler: function(server, path, connection, client) {
        if (this.connection != null) {
            log('A client is already connected, bye-bye.');
            connection.close();
            return;
        }

        this.connection = connection;

        this.signals.push(this.connection.connect('message', Lang.bind(this, this.clientMessage)));
        this.signals.push(this.connection.connect('closed', Lang.bind(this, this.clientDisconnected)));
    },

    clientMessage: function(conn, opcode, message) {
        if (opcode != 1)
            return;


    },

    clientDisconnected: function(conn) {
        if (conn != this.connection)
            return;

        for (let i in this.signals)
            this.connection.disconnect(this.signals[i]);
        this.connection = null;
    },
});


let server = null;
let getDefault = function() {
    if (server == null) {
        server = new WebProtoServer({ port: 1081, });
    }

    return server;
};
