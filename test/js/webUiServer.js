const Lang = imports.lang;

const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Soup = imports.gi.Soup;

/**/

const WebUIServer = new Lang.Class({

    Name: 'WebUIServer',

    _init: function(args) {
        this.directories = [];
        for (let i in args.directories)
            this.addDirectory(args.directories[i]);
        this.server = new Soup.Server({ port: args.port });
        this.server.add_handler(null, Lang.bind(this, this.mainHandler));
    },

    addDirectory: function(localPath) {
        this.directories.push(localPath);
    },

    findFileFromPath: function(path) {
        for (let i in this.directories) {
            let lpath = this.directories[i] + path;
            if (GLib.file_test(lpath, GLib.FileTest.IS_REGULAR))
                return lpath;
        }
        return null;
    },

    /* Handling updates payload */

    payloadHandler: function(server, msg, path, query, client) {
        let localPath = this.findFileFromPath(path);
        if (!localPath) {
            log(path + ' missing?? ');
            msg.status_code = 404;
            return;
        }

        let mime = Gio.content_type_guess(localPath, null)[0];
        let file = Gio.File.new_for_path(localPath);
        let io = file.read(null);

        log('sending ' + localPath + ' mime=' + mime);

        let reader = function(msg) {
            let buffer = io.read_bytes(1024, null);

            if (buffer.get_size() > 0)
                msg.response_body.append(buffer.get_data(), buffer.get_size());
            else
                msg.response_body.complete();
        };

        if (io) {
            msg.status_code = 200;
            msg.response_body.set_accumulate(true);
            msg.response_headers.set_content_type(mime, {});
            msg.response_headers.set_encoding(Soup.Encoding.EOF);

            msg.connect('wrote-headers', Lang.bind(this, reader));
            msg.connect('wrote-chunk', Lang.bind(this, reader));
        } else {
            log(path + ' -> ' + localPath + ' missing???');
            msg.status_code = 404;
            msg.response_body.complete();
        }
    },

    /* Libsoup handler */

    mainHandler: function(server, msg, path, query, client) {
        if (path == '/')
            path = '/index.html';
        this.payloadHandler(server, msg, path, query, client);
    },

    /**/

    start: function() {
        this.server.run_async();
    },

    stop: function() {
        this.server.disconnect();
    },
});


let server = null;
let getDefault = function() {
    if (server == null) {
        server = new WebUIServer({ port: 1080,
                                   directories: [ '../node_modules/noflo-ui', ], });
    }

    return server;
};
