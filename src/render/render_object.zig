const std = @import("std");
const gl = @import("gl");

const utils = @import("../utils.zig");

const Shader = @import("shader.zig").Shader;
const Texture = @import("texture.zig").Texture;
const Vertex = @import("vertex.zig").Vertex;

const errors = error{
    VBOEmpty,
    EBOEmpty,
};

pub const ObjectBuffers = struct {
    vao: c_uint,
    vbo: c_uint,
    ebo: ?c_uint,

    pub fn init(generate_ebo: bool) ObjectBuffers {
        var vao: c_uint = undefined;
        gl.GenVertexArrays(1, @ptrCast(&vao));

        var vbo: c_uint = undefined;
        gl.GenBuffers(1, @ptrCast(&vbo));

        var ebo: ?c_uint = undefined;
        if (generate_ebo) {
            gl.GenBuffers(1, @ptrCast(&ebo));
        }

        return .{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
        };
    }

    pub fn bindBuffer(self: *const ObjectBuffers) void {
        gl.BindVertexArray(self.vao);
    }

    pub fn bindVBO(self: *const ObjectBuffers) void {
        gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);
    }

    pub fn bindEBO(self: *const ObjectBuffers) !void {
        if (self.ebo == null) {
            return errors.EBOEmpty;
        }
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo.?);
    }

    pub fn unbindBuffer(self: *const ObjectBuffers) void {
        _ = self;
        gl.BindVertexArray(0);
    }

    pub fn deinit(self: *const ObjectBuffers) void {
        var vao = self.vao;
        var vbo = self.vbo;
        defer gl.DeleteVertexArrays(1, @ptrCast(&vao));
        defer gl.DeleteBuffers(1, @ptrCast(&vbo));
        if (self.ebo != null) {
            var ebo = self.ebo.?;
            defer gl.DeleteBuffers(1, @ptrCast(&ebo));
        }
    }
};

pub const RenderObject = struct {
    ptr: *anyopaque,
    bufferFunc: *const fn (ptr: *anyopaque) errors!void,
    drawFunc: *const fn (ptr: *anyopaque) void,
    unbufferFunc: *const fn (ptr: *anyopaque) void,
    attachFunc: *const fn (ptr: *anyopaque) void,

    pub fn buffer(self: *const RenderObject) !void {
        try self.bufferFunc(self.ptr);
    }

    pub fn unbuffer(self: *const RenderObject) void {
        return self.unbufferFunc(self.ptr);
    }

    pub fn draw(self: *const RenderObject) void {
        return self.drawFunc(self.ptr);
    }

    pub fn attach(self: *const RenderObject) void {
        return self.attachFunc(self.ptr);
    }

    pub fn render(self: *const RenderObject) !void {
        self.attach();
        try self.buffer();
        self.draw();
        self.unbuffer();
    }
};

pub fn ObjectEmmiter(comptime T: type) type {
    return struct {
        emmited: std.ArrayList(T),
        allocator: *std.mem.Allocator,
        index: usize = 0,

        pub fn init(allocator: *std.mem.Allocator) ObjectEmmiter(T) {
            return .{
                .allocator = allocator,
                .emmited = std.ArrayList(T).init(allocator),
                .index = 0,
            };
        }

        pub fn deinit(self: *ObjectEmmiter(T)) void {
            for (self.emmited) |obj| {
                obj.deinit();
            }
        }

        pub fn addEmmitable(self: *ObjectEmmiter(T), emit_args: anytype) !void {
            const obj = try T.init(self.allocator, emit_args);
            try self.emmited.append(obj);
        }
    };
}
