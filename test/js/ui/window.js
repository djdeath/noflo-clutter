const Clutter = imports.gi.Clutter;
const St = imports.gi.St;

const Lang = imports.lang;
const TouchAction = imports.touchAction;
const Util = imports.util;


const TitleBar = new Lang.Class({
    Name: 'TitleBar',
    Extends: St.BoxLayout,

    _init: function(args) {
	this.parent(Util.mergeProps(args,
				    {
					reactive: true,
					vertical: false,
					style_class: 'windowTitleBar',
				    }));

        let box = new St.BoxLayout({ style_class: 'windowTitleBox', });
	this.add(box, { x_fill: true,
		        y_fill: true,
		        expand: true,});

        this.icon = new St.Widget({ name: 'chromeIcon', });
        box.add(this.icon, { y_align: St.Align.MIDDLE,
                             x_fill: false,
                             y_fill: false,
                             expand: false, });
        this.title = new St.Label({
            style_class: 'windowTitle',
            text: '',
        });
        box.add(this.title, { y_align: St.Align.MIDDLE,
                              x_fill: true,
                              y_fill: false,
                              expand: true, });
        this.minimizeButton = new St.Button({
	    style_class: 'windowTitleBarMinimizeButton',
	});
	this.add(this.minimizeButton, { x_fill: true,
		                        y_fill: false,
		                        x_align: St.Align.START,
		                      });
        this.maximizeButton = new St.Button({
	    style_class: 'windowTitleBarMaximizeButton',
	});
	this.add(this.maximizeButton, { x_fill: true,
		                        y_fill: false,
		                        x_align: St.Align.START,
		                      });
        this.closeButton = new St.Button({
	    style_class: 'windowTitleBarCloseButton',
	});
	this.add(this.closeButton, { x_fill: true,
		                     y_fill: false,
		                     x_align: St.Align.START,
		                   });
    },

    vfunc_button_press_event: function() {
        return true;
    },

    vfunc_button_release_event: function() {
        return true;
    },

    vfunc_motion_event: function() {
        return true;
    },

    vfunc_touch_event: function() {
        return true;
    },
});

const AppDrawer = new Lang.Class({
    Name: 'AppDrawer',
    Extends: St.Widget,

    _init: function(args) {
    },
});

const Content = new Lang.Class({
    Name: 'Content',
    Extends: St.BoxLayout,

    _init: function(_args) {
        let args = Util.parseProps(_args, { applicationId: 'unknown', });

        this.parent(Util.mergeProps(_args,
				    {
					reactive: true,
					vertical: false,
                                        style_class: args.applicationId + 'Content',
					//style_class: 'windowContent',
                                        clip_to_allocation: true,
				    }));
    },

    vfunc_button_press_event: function() {
        return true;
    },

    vfunc_button_release_event: function() {
        return true;
    },

    vfunc_touch_event: function() {
        return true;
    },
});

const InnerWindow = new Lang.Class({
    Name: 'InnerWindow',
    Extends: St.Table,

    _init: function(_args) {
        let args = Util.parseProps(_args, { applicationId: 'unknown',
                                            content: null, });

	this.parent(Util.mergeProps(_args,
				    { style_class: 'windowInner',
                                      reactive: true,
                                      homogeneous: false, }));

        this.titleBar = new TitleBar({});
	this.add(this.titleBar,
		 { col: 0,
                   row: 0,
                   col_span: 3,
                   row_span: 1,
                   x_expand: false,
                   y_expand: false,
                   x_fill: true,
                   y_fill: false,
		 });

        if (args.content == null)
            this.windowContent = new Content({ applicationId: args.applicationId, });
        else {
            this.windowContent = args.content;
            this.windowContent.connect('allocation-changed', Lang.bind(this, function(actor, box, flags) {
                log('resize meta window to ' + box.get_width() + 'x' + box.get_height());
                if (box.get_width() > 200 && box.get_height() > 200)
                    this.windowContent.get_meta_window().resize(true, box.get_width(), box.get_height());
            }));
        }
	this.add(this.windowContent,
		 { col: 0,
                   row: 1,
                   col_span: 3,
                   row_span: 2,
                   x_expand: false,
                   y_expand: false,
                   x_fill: true,
                   y_fill: true,
		 });


        // Transparent widget to fill up the middle of the window
        // content
	this.add(new St.Widget({}),
		 { col: 1,
                   row: 1,
                   col_span: 1,
                   row_span: 1,
                   x_expand: true,
                   y_expand: true,
                   x_fill: true,
                   y_fill: true,
		 });


        // left
        this.leftSide = new St.Widget({ reactive: true,
                                        track_hover: true,
                                        style_class: 'windowBorderSide', });
	this.add(this.leftSide,
		 { col: 0,
                   row: 1,
                   col_span: 1,
                   row_span: 2,
                   x_expand: false,
                   y_expand: false,
		 });
        // right
        this.rightSide = new St.Widget({ reactive: true,
                                         track_hover: true,
                                         style_class: 'windowBorderSide', });
	this.add(this.rightSide,
		 { col: 2,
                   row: 1,
                   col_span: 1,
                   row_span: 2,
                   x_expand: false,
                   y_expand: false,
		 });
        // bottom
        this.bottomSide = new St.Widget({ reactive: true,
                                          track_hover: true,
                                          style_class: 'windowBorderBottom', });
	this.add(this.bottomSide,
		 { col: 0,
                   row: 2,
                   col_span: 3,
                   row_span: 1,
                   x_expand: false,
                   y_expand: false,
		 });

    },

    setResizeRatios: function(ratioX, ratioY) {
        if (ratioX == 0) {
            this.leftSide.remove_style_pseudo_class('resizing');
            this.rightSide.remove_style_pseudo_class('resizing');
        } else if (ratioX < 0)
            this.leftSide.add_style_pseudo_class('resizing');
        else if (ratioX > 0)
            this.rightSide.add_style_pseudo_class('resizing');

        if (ratioY == 0)
            this.bottomSide.remove_style_pseudo_class('resizing');
        else if (ratioY > 0)
            this.bottomSide.add_style_pseudo_class('resizing');
    },

});



const Window = new Lang.Class({
    Name: 'Window',
    Extends: St.Widget,

    _init: function(_args) {
        log('create new window id : ' + _args.id);
        log('create new app id : ' + _args.applicationId);
        let args = Util.parseProps(_args, { id: 'unknown',
                                            title: 'Unknown',
                                            applicationId: 'unknown',
                                            content: null, })
	this.parent(Util.mergeProps(_args,
                                    { reactive: true,
                                      style_class: 'window', }));

        this._id = args.id;
        this._applicationId = args.applicationId;
        log('create new window id : ' + this._id);

        this.outer = new St.Widget({ style_class: 'windowOuter',
                                     reactive: false, });
        this.add_actor(this.outer);
        this.inner = new InnerWindow({ applicationId: args.applicationId,
                                       content: args.content, });
        this.add_actor(this.inner);

        this.inner.titleBar.title.text = args.title;
        this.inner.titleBar.icon.style_class = args.applicationId + 'WindowIcon';
        //this.inner.windowContent.style_class = args.applicationId + 'Content';

        this.moveAction = new Clutter.DragAction({ x_drag_threshold: 5,
                                                   y_drag_threshold: 5, });
	this.inner.titleBar.add_action(this.moveAction);
        this.resizeAction = new Clutter.DragAction({ x_drag_threshold: 0,
                                                     y_drag_threshold: 0, });
        this.add_action(this.resizeAction);

        this.touchTitleBarAction = new TouchAction.TouchAction({});
	this.inner.titleBar.add_action(this.touchTitleBarAction);
        this.doubleTapTitleBarAction = new TouchAction.DoubleTapAction({});
	this.inner.titleBar.add_action(this.doubleTapTitleBarAction);
        this.touchContentAction = new TouchAction.TouchAction({});
        if (_args.content == null)
	    this.inner.windowContent.add_action(this.touchContentAction);
        this.touchWindowAction = new TouchAction.TouchAction({});
	this.add_action(this.touchWindowAction);

        this._styleChangedId = this.connect('style-changed', Lang.bind(this, function() {
            let themeNode = this.get_theme_node();
            this.minimumWidth = themeNode.get_min_width();
            this.minimumHeight = themeNode.get_min_height();
            this.disconnect(this._styleChangedId);
            delete this._styleChangedId;
        }));
    },

    vfunc_allocate: function(box, flags) {
        this.parent(box, flags);

        let availWidth = box.x2 - box.x1, availHeight = box.y2 - box.y1;
        let themeNode = this.get_theme_node();
        let childBox = new Clutter.ActorBox();
        childBox.x1 = themeNode.get_padding(St.Side.LEFT);
        childBox.x2 = Math.max(availWidth - themeNode.get_padding(St.Side.RIGHT) - childBox.x1, 0);
        childBox.y1 = themeNode.get_padding(St.Side.TOP);
        childBox.y2 = Math.max(availHeight - themeNode.get_padding(St.Side.BOTTOM) - childBox.y1, 0);

        this.outer.allocate(childBox, flags);
        this.inner.allocate(childBox, flags);
    },

    setMoveResize: function(value) {
        this.moveResize = value;
    },

    setResizeRatios: function(ratioX, ratioY) {
        this.inner.setResizeRatios(ratioX, ratioY);
    },

    setMaximized: function(value) {
        this.maximized = value;
        if (value) {
            this.inner.titleBar.maximizeButton.add_style_pseudo_class('maximized');
            this.inner.titleBar.minimizeButton.hide();
        } else {
            this.inner.titleBar.maximizeButton.remove_style_pseudo_class('maximized');
            this.inner.titleBar.minimizeButton.show();
        }
    },

    setApplicationId: function(applicationId) {
        this.inner.titleBar.icon.style_class = applicationId + 'WindowIcon';
        //this.inner.windowContent.style_class = applicationId + 'Content';
    },

    getApplicationId: function() {
        return this._applicationId;
    },

    getId: function() {
        return this._id;
    },

    getTitle: function() {
        return this.inner.titleBar.title.text;
    },

    setTitle: function(title) {
        return this.inner.titleBar.title.text = title;
    },

    getCloseButton: function() {
        return this.inner.titleBar.closeButton;
    },

    getMaximizeButton: function() {
        return this.inner.titleBar.maximizeButton;
    },

    getMinimizeButton: function() {
        return this.inner.titleBar.minimizeButton;
    },
});
