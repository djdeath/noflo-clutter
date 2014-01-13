const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Clutter = imports.gi.Clutter;

const Lang = imports.lang;

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

Clutter.init(null, null);

let stage = new Clutter.Stage({
    background_color: Clutter.Color.from_string('#4d4545')[1],
    user_resizable: true,
});
stage.show();

let actor = new Clutter.Actor({
    background_color: Clutter.Color.from_string('red')[1],
    name: 'plop',
    width: 100,
    height: 100,
});
stage.add_child(actor);

let [, content] = Gio.File.new_for_path('./test-clutter.fbp').load_contents(null);
NoFlo.graph.loadFBP('' + content, function (graph) {
    graph.baseDir = '/noflo-clutter';
    log('Graph loaded');

    NoFlo.createNetwork(graph, function (network) {
        log("Network created");
    });
});


Clutter.main();
