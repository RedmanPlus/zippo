const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const render_object = @import("render/render_object.zig");

const Vertex = @import("render/vertex.zig").Vertex;
const Rectangle = @import("render/rectangle.zig").Rectangle;
const ObjectEmmiter = render_object.ObjectEmmiter;

var gl_procs: gl.ProcTable = undefined;

pub const App = struct {
    window: glfw.Window,

    pub fn init(
        width: u32,
        height: u32,
        window_name: []const u8,
    ) !App {
        if (!glfw.init(.{})) return error.InitFailed;

        const window = glfw.Window.create(width, height, @ptrCast(@alignCast(window_name)), null, null, .{
            .context_version_major = gl.info.version_major,
            .context_version_minor = gl.info.version_minor,
            .opengl_profile = switch (gl.info.api) {
                .gl => .opengl_core_profile,
                .gles => .opengl_any_profile,
                else => comptime unreachable,
            },
            .opengl_forward_compat = gl.info.api == .gl,
        }) orelse return error.InitFailed;

        glfw.makeContextCurrent(window);
        if (!gl_procs.init(glfw.getProcAddress)) return error.InitFailed;

        gl.makeProcTableCurrent(&gl_procs);
        return .{
            .window = window,
        };
    }

    pub fn deinit(self: *App) void {
        glfw.terminate();
        self.window.destroy();
        gl.makeProcTableCurrent(null);
    }

    pub fn run(self: *App, objects: []const render_object.RenderObject) !void {
        while (true) {
            glfw.waitEvents();
            if (self.window.shouldClose()) break;

            const fb_size = self.window.getFramebufferSize();
            gl.Viewport(0, 0, @intCast(fb_size.width), @intCast(fb_size.height));

            gl.ClearBufferfv(gl.COLOR, 0, &[4]f32{ 1, 1, 1, 1 });

            for (objects) |obj| {
                try obj.render();
            }

            self.window.swapBuffers();
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var alloc = arena.allocator();

    var app = try App.init(620, 480, "App!");
    defer app.deinit();

    var rec1 = try Rectangle.init(&alloc, .{
        .vertex_path = "src/glsl/triangle_vert.glsl",
        .fragment_path = "src/glsl/triangle_frag.glsl",
        .texture_path = "src/textures/wall.jpg",
        .model_vertices = [4]Vertex{
            .{ .position = .{ 0.5, 0.5, 0 }, .color = .{ 1, 1, 1 }, .texture = .{ 1, 1 } },
            .{ .position = .{ 0.5, -0.5, 0 }, .color = .{ 1, 1, 1 }, .texture = .{ 1, 0 } },
            .{ .position = .{ -0.5, -0.5, 0 }, .color = .{ 1, 1, 1 }, .texture = .{ 0, 0 } },
            .{ .position = .{ -0.5, 0.5, 0 }, .color = .{ 1, 1, 1 }, .texture = .{ 0, 1 } },
        },
        .indecies = [6]u32{ 0, 1, 3, 1, 2, 3 },
    });
    defer rec1.deinit();
    const obj = rec1.toObject();
    try app.run(&[_]render_object.RenderObject{obj});
}
