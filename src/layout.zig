const std = @import("std");

const int_ptr = usize;

pub const Node = struct {
    renderable: int_ptr = undefined,
    v_table: *const VTable = undefined,

    const VTable = struct {
        render: *const fn (self: *Node) anyerror!void,
    };

    pub fn render(self: *Node) anyerror!void {
        try self.v_table.render(self);
    }

    pub fn make(obj: anytype) Node {
        const obj_ptr_type = @TypeOf(obj);
        return Node{
            .renderable = @intFromPtr(obj),
            .v_table = &.{
                .render = struct {
                    fn render(self: *Node) anyerror!void {
                        const typed_obj: obj_ptr_type = @ptrFromInt(self.renderable);
                        try typed_obj.render();
                    }
                }.render,
            },
        };
    }
};

const Rec = struct {
    rendered_text: []const u8,

    pub fn render(self: *Rec) void {
        std.debug.print("rendered {s}\n", .{self.rendered_text});
    }
};

const NestedRectangle = struct {
    rec_1: *Node = undefined,
    rec_2: *Node = undefined,

    pub fn render(self: *NestedRectangle) void {
        self.rec_1.render();
        self.rec_2.render();
    }
};

test "render nested" {
    var core = Node.make(
        &NestedRectangle{
            .rec_1 = &Node.make(
                &Rec{ .rendered_text = "foo" },
            ),
            .rec_2 = &Node.make(
                &Rec{ .rendered_text = "bar" },
            ),
        },
    );

    core.render();
}
