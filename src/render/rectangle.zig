const std = @import("std");
const gl = @import("gl");

const utils = @import("../utils.zig");

const Shader = @import("shader.zig").Shader;
const Texture = @import("texture.zig").Texture;
const Vertex = @import("vertex.zig").Vertex;
const render_object = @import("render_object.zig");

const ObjectBuffers = render_object.ObjectBuffers;
const RenderObject = render_object.RenderObject;

pub const Rectangle = struct {
    shader: Shader,
    texture: Texture,
    buffers: ObjectBuffers,
    vertices: [4]Vertex,
    indecies: [6]u32,

    pub fn init(
        alloc: *std.mem.Allocator,
        args: anytype,
    ) !Rectangle {
        const vertex_code = try utils.readFile(args.vertex_path, alloc);
        const fragment_code = try utils.readFile(args.fragment_path, alloc);
        const shader = try Shader.init(
            vertex_code,
            fragment_code,
            alloc,
        );
        shader.getAttrubutes();
        shader.getUniforms();
        const texture = try Texture.init(args.texture_path);
        const buffers = ObjectBuffers.init(true);
        return .{
            .vertices = args.model_vertices,
            .indecies = args.indecies,
            .shader = shader,
            .texture = texture,
            .buffers = buffers,
        };
    }

    pub fn deinit(self: *const Rectangle) void {
        _ = self.shader.deinit();
        self.buffers.deinit();
    }

    pub fn attach(ptr: *anyopaque) void {
        const self: *Rectangle = @ptrCast(@alignCast(ptr));
        self.shader.attach();
    }

    pub fn buffer(ptr: *anyopaque) !void {
        const self: *Rectangle = @ptrCast(@alignCast(ptr));
        self.buffers.bindBuffer();

        self.buffers.bindVBO();
        defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

        gl.BufferData(
            gl.ARRAY_BUFFER,
            @sizeOf(@TypeOf(self.vertices)),
            &self.vertices,
            gl.STATIC_DRAW,
        );
        self.shader.setInVecFloat(
            "position",
            @typeInfo(@TypeOf(@as(Vertex, undefined).position)).Array.len,
            @offsetOf(Vertex, "position"),
        );
        self.shader.setInVecFloat(
            "color",
            @typeInfo(@TypeOf(@as(Vertex, undefined).color)).Array.len,
            @offsetOf(Vertex, "color"),
        );
        self.shader.setInVecFloat(
            "tex_coord",
            @typeInfo(@TypeOf(@as(Vertex, undefined).texture)).Array.len,
            @offsetOf(Vertex, "texture"),
        );

        try self.buffers.bindEBO();

        gl.BufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @sizeOf(@TypeOf(self.indecies)),
            &self.indecies,
            gl.STATIC_DRAW,
        );
    }

    pub fn unbuffer(ptr: *anyopaque) void {
        const self: *Rectangle = @ptrCast(@alignCast(ptr));
        self.buffers.unbindBuffer();
    }

    pub fn draw(ptr: *anyopaque) void {
        const self: *Rectangle = @ptrCast(@alignCast(ptr));
        self.texture.bind();
        gl.DrawElements(gl.TRIANGLES, @intCast(self.indecies.len), gl.UNSIGNED_INT, 0);
    }

    pub fn toObject(self: *Rectangle) RenderObject {
        return .{
            .ptr = self,
            .bufferFunc = buffer,
            .drawFunc = draw,
            .attachFunc = attach,
            .unbufferFunc = unbuffer,
        };
    }
};
