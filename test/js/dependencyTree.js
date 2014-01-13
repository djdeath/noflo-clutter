const Lang = imports.lang;
const Util = imports.util;

const Clutter = imports.gi.Clutter;

const DependencyTree = new Lang.Class({
    Name: 'DependencyTree',

    _init: function(args) {
        this.window = args.window;
        this.initialState = {
            x: this.window.x,
            y: this.window.y,
            width: this.window.width,
            height: this.window.height,
        };
        this.currentState = Util.copy(this.initialState);
        this.id = this.window.getId();
        this.xImpacts = [];
        this.yImpacts = [];
        this.impacts = {};
        this.cachedMinimumSize = { };
        this.visited = false;
        this.moveLevel = -1;
        this.resizeLevel = -1;
    },

    toString: function() {
        return 'dependencyTree-' + this.id;
    },

    print: function(level, xImpact, yImpact) {
        if (level === undefined)
            level = 0

        log(Util.levelToSpaces(level) + this.id);

        if (xImpact === undefined || xImpact === true) {
            log(Util.levelToSpaces(level) + ' x-impacts : ');
            for (let i in this.xImpacts)
                this.xImpacts[i].print(level + 1, true, false);
        }
        if (yImpact === undefined || yImpact === true) {
            log(Util.levelToSpaces(level) + ' y-impacts : ');
            for (let i in this.yImpacts)
                this.yImpacts[i].print(level + 1, false, true);
        }
    },

    fillTable: function(table) {
        this._toTable(table);
    },

    _toTable: function(table) {
        table[this.id] = this;
        for (let i in this.xImpacts)
            this.xImpacts[i]._toTable(table);
        for (let i in this.yImpacts)
            this.yImpacts[i]._toTable(table);
    },

    toList: function() {
        let table = {};
        let ret = [];
        this._toTable(table);
        for (let i in table)
            ret.push(table[i]);
        return ret;
    },

    cleanCached: function() {
        this.cachedMinimumSize = {};
        delete this.cachedBounds;
        delete this.cachedSubBounds;
        this.resizeLevel = -1;
        this.moveLevel = -1;
    },

    addXImpact: function(subTree) {
        //log('added ' + subTree.id + ' to ' + this.id)
        this.impacts[subTree.id] = subTree;
        this.xImpacts.push(subTree);
    },

    addYImpact: function(subTree) {
        //log('added ' + subTree.id + ' to ' + this.id)
        this.impacts[subTree.id] = subTree;
        this.yImpacts.push(subTree);
    },

    cleanImpacts: function() {
        this.cleanCached();
        this.visited = false;
        this.impacts = {};
        this.xImpacts = [];
        this.yImpacts = [];
    },

    hasImpactOn: function(subTree) {
        return this.impacts[subTree.id] !== undefined
    },

    saveCurrentState: function() {
        this.currentState.x = this.window.x;
        this.currentState.y = this.window.y;
        this.currentState.width = this.window.width;
        this.currentState.height = this.window.height;
    },

    isVisited: function() {
        return this.visited;
    },

    setVisited: function(value) {
        this.visited = value;
    },

    getSubTreeMinimumWidth: function() {
        if (this.cachedMinimumSize.width)
            return this.cachedMinimumSize.width - this.window.minimumWidth;

        let min = 0;
        for (let i in this.xImpacts) {
            min = Math.max(min, this.xImpacts[i].getMinimumWidth());
        }
        return min;
    },

    getMinimumWidth: function() {
        if (this.cachedMinimumSize.width)
            return this.cachedMinimumSize.width;

        this.cachedMinimumSize.width = this.window.minimumWidth +
            this.getSubTreeMinimumWidth();
        return this.cachedMinimumSize.width;
    },

    getSubTreeMinimumHeight: function() {
        if (this.cachedMinimumSize.height)
            return this.cachedMinimumSize.height - this.window.minimumHeight;

        let min = 0;
        for (let i in this.yImpacts) {
            min = Math.max(min, this.yImpacts[i].getMinimumHeight());
        }
        return min;
    },

    getMinimumHeight: function() {
        if (this.cachedMinimumSize.height)
            return this.cachedMinimumSize.height;

        this.cachedMinimumSize.height = this.window.minimumHeight +
            this.getSubTreeMinimumHeight();
        return this.cachedMinimumSize.height;
    },

    getBounds: function() {
        if (this.cachedBounds)
            return this.cachedBounds;

        if (!this.hasSubBounds()) {
            this.cachedBounds = { x1: this.initialState.x,
                                  x2: this.initialState.x + this.initialState.width,
                                  y1: this.initialState.y,
                                  y2: this.initialState.y + this.initialState.height,
                                };
            return this.cachedBounds;
        }

        let subBounds = Util.copy(this.getSubTreeBounds());
        subBounds.x1 = Math.min(this.initialState.x, subBounds.x1);
        subBounds.x2 = Math.max(this.initialState.x + this.initialState.width,
                                subBounds.x2);
        subBounds.y1 = Math.min(this.initialState.y, subBounds.y1);
        subBounds.y2 = Math.max(this.initialState.y + this.initialState.height,
                                subBounds.y2);
        this.cachedBounds = subBounds;
        return this.cachedBounds;
    },

    hasSubBounds: function () {
        return this.xImpacts.length > 0 || this.yImpacts.length > 0
    },

    getSubTreeBounds: function() {
        if (this.cachedSubBounds)
            return this.cachedSubBounds;

        if (!this.hasSubBounds())
            throw new Error("Shouldn't reach this code path");

        let bounds = { x1: this.initialState.x + this.initialState.width,
                       y1: this.initialState.y + this.initialState.height,
                       x2: 0,
                       y2: 0, };

        for (let i in this.xImpacts) {
            let subBounds = this.xImpacts[i].getBounds();
            bounds.x1 = Math.min(bounds.x1, subBounds.x1);
            bounds.y1 = Math.min(bounds.y1, subBounds.y1);
            bounds.x2 = Math.max(bounds.x2, subBounds.x2);
            bounds.y2 = Math.max(bounds.y2, subBounds.y2);
        }
        for (let i in this.yImpacts) {
            let subBounds = this.yImpacts[i].getBounds();
            bounds.x1 = Math.min(bounds.x1, subBounds.x1);
            bounds.y1 = Math.min(bounds.y1, subBounds.y1);
            bounds.x2 = Math.max(bounds.x2, subBounds.x2);
            bounds.y2 = Math.max(bounds.y2, subBounds.y2);
        }

        this.cachedSubBounds = bounds;
        return this.cachedSubBounds;
    },

    resizeTo: function(box, ratioX, ratioY, level) {
        let winbox = Util.copy(this.initialState);
        let subbox = Util.copy(box);

        //log(Util.levelToSpaces(level) + this.id + ' resize box=' + Util.allocationBoxToString(box));

        if (ratioX != 0) {
            if (ratioX < 0) {
                let offset = this.hasSubBounds() ? this.getSubTreeBounds().x2 : box.x;

                winbox.width = Math.min(Math.max(this.window.minimumWidth,
                                                 (box.width - box.x) - offset),
                                        winbox.width);
                winbox.x = Math.min(winbox.x, box.x + box.width - winbox.width);

                subbox.width = winbox.x;

                if (this.resizeLevel < level) {
                    this.resizeLevel = level;
                    //log(Util.levelToSpaces(level) + ' -> ' + this.id + ' resizing to ' + Util.allocationBoxToString(winbox));
                    this.window.set_position(winbox.x, winbox.y);
                    this.window.set_size(winbox.width, winbox.height);
                }
            } else if (ratioX > 0) {
                let subBox = 0;

                if (this.hasSubBounds()) {
                    let bounds = this.getSubTreeBounds();
                    subBox = bounds.x2 - bounds.x1;
                }

                winbox.x = Math.max(winbox.x, box.x);
                winbox.width = Math.min(Math.max(this.window.minimumWidth,
                                                 box.width - subBox),
                                        winbox.width);

                subbox.x = winbox.x + winbox.width;
                subbox.width = box.width - winbox.width;

                if (this.resizeLevel < level) {
                    this.resizeLevel = level;
                    //log(Util.levelToSpaces(level) + ' -> ' + this.id + ' resizing to ' + Util.allocationBoxToString(winbox));
                    this.window.set_position(winbox.x, winbox.y);
                    this.window.set_size(winbox.width, winbox.height);
                }
            }

            //log(Util.levelToSpaces(level) + ' -> ' + this.id + ' x-move subbox=' + Util.allocationBoxToString(subbox));
            this.resizeSubTreeTo(subbox, ratioX, ratioY, level);
        }

        if (ratioY != 0) {
            if (ratioY < 0) {
                let offset = this.hasSubBounds() ? this.getSubTreeBounds().y2 : box.y;

                //if (this.hasSubBounds())
                    //log(Util.levelToSpaces(level) + ' -> ' + this.id + ' subBounds=' + Util.boxToString(this.getSubTreeBounds()));
                winbox.height = Math.min(Math.max(this.window.minimumHeight,
                                                  (box.height - box.y) - offset),
                                         winbox.height);
                winbox.y = Math.min(winbox.y, box.y + box.height - winbox.height);

                subbox.height = winbox.y;

                if (this.resizeLevel < level) {
                    this.resizeLevel = level;
                    //log(Util.levelToSpaces(level) + ' -> ' + this.id + ' resizing to ' + Util.allocationBoxToString(winbox));
                    this.window.set_position(winbox.x, winbox.y);
                    this.window.set_size(winbox.width, winbox.height);
                }
            } else if (ratioY > 0) {
                let subBox = 0;

                if (this.hasSubBounds()) {
                    let bounds = this.getSubTreeBounds();
                    subBox = bounds.y2 - bounds.y1;
                }

                winbox.y = Math.max(winbox.y, box.y);
                winbox.height = Math.min(Math.max(this.window.minimumHeight,
                                                 box.height - subBox),
                                        winbox.height);

                subbox.y = winbox.y + winbox.height;
                subbox.height = box.height - winbox.height;

                if (this.resizeLevel < level) {
                    this.resizeLevel = level;
                    //log(Util.levelToSpaces(level) + ' -> ' + this.id  + ' resizing to ' + Util.allocationBoxToString(winbox));
                    this.window.set_position(winbox.x, winbox.y);
                    this.window.set_size(winbox.width, winbox.height);
                }
            }

            //log(Util.levelToSpaces(level) + ' -> ' + this.id + ' y-move subbox=' + Util.allocationBoxToString(subbox));
            this.resizeSubTreeTo(subbox, ratioX, ratioY, level);
        }
    },

    resizeSubTreeTo: function(box, ratioX, ratioY, level) {

        //log(Util.levelToSpaces(level) + this.id + ' resize sub tree box=' + Util.allocationBoxToString(box));

        if (ratioX != 0) {
            for (let i in this.xImpacts) {
                this.xImpacts[i].resizeTo(box, ratioX, 0, level + 1);
            }
        }
        if (ratioY != 0) {
            for (let i in this.yImpacts) {
                this.yImpacts[i].resizeTo(box, 0, ratioY, level + 1);
            }
        }
    },

    //

    canMoveIn: function(box) {
        if (box.width >= 0) {
            if (this.initialState.width > box.width)
                return false;
            let cbox = Util.copy(box);
            cbox.width -= this.initialState.width;
            for (let i in this.xImpacts) {
                if (!this.xImpacts[i].canMoveIn(cbox))
                    return false;
            }
            return true;
        }
        if (box.height >= 0) {
            if (this.initialState.height > box.height)
                return false;
            let cbox = Util.copy(box);
            cbox.height -= this.initialState.height;
            for (let i in this.yImpacts) {
                if (!this.yImpacts[i].canMoveIn(cbox))
                    return false;
            }
            return true;
        }
        return false;
    },

    moveTo: function(results, box, level) {
        if (box.width >= 0) {
            // log('putting ' + this.window.getId() + ' into ' + Util.allocationBoxToString(box));
            let cbox = Util.copy(box);
            if (level > this.moveLevel) {
                // log('              accepted level=' + level);
                this.moveLevel = level;
                let ret = results[this.id] = {
                    window: this.window,
                    params: {
                        y: this.initialState.y,
                    },
                };
                if (box.x > 0) {
                    ret.params.x = Math.max(box.x, this.initialState.x);
                    // log('    -> ret1=' + Math.max(box.x, this.initialState.x));
                } else {
                    ret.params.x = Math.min(this.initialState.x,
                                            box.x + box.width - this.initialState.width);
                    // log('    -> ret2=' + Math.min(this.initialState.x,
                    //                               box.x + box.width - this.initialState.width));
                }

                if (box.x > 0)
                    cbox.x = ret.params.x + this.initialState.width;
                cbox.width -= this.initialState.width;
                for (let i in this.xImpacts)
                    this.xImpacts[i].moveTo(results, cbox, level + 1);
            }
        }
        if (box.height >= 0) {
            let cbox = Util.copy(box);
            if (level > this.moveLevel) {
                this.moveLevel = level;
                let ret = results[this.id] = {
                    window: this.window,
                    params: {
                        x: this.initialState.x,
                    },
                };
                if (box.y > 0)
                    ret.params.y = Math.max(box.y, this.initialState.y);
                else
                    ret.params.y = Math.min(this.initialState.y,
                                            box.y + box.height - this.initialState.height);

                if (box.y > 0)
                    cbox.y += this.initialState.height;
                cbox.height -= this.initialState.height;
                for (let i in this.yImpacts)
                    this.yImpacts[i].moveTo(results, cbox, level + 1);
            }
        }
    },
});
