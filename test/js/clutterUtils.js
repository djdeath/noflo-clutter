const Clutter = imports.gi.Clutter;
const GObject = imports.gi.GObject;
const Lang = imports.lang;

const PipelineContent = new Lang.Class({
    Name: 'PipelineContent',
    Extends: GObject.Object,
    Implements: [ Clutter.Content, ],

    _init: function() {
        this.parent();
    },

    vfunc_paint_content: function(actor, parent) {
        let box = actor.get_allocation_box();
        let node = new Clutter.PipelineNode(this.pipeline);
        node.add_rectangle(box);
        parent.add_child(node);
    },
});
