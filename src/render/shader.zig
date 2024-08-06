const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const Vertex = @import("vertex.zig").Vertex;

pub const Shader = struct {
    id: u32 = 0,

    pub fn init(vert: []u8, frag: []u8, alloc: *std.mem.Allocator) !Shader {
        const vx = try compile(vert, gl.VERTEX_SHADER, alloc);
        const fg = try compile(frag, gl.FRAGMENT_SHADER, alloc);
        defer gl.DeleteShader(vx);
        defer gl.DeleteShader(fg);

        var result = Shader{};
        result.id = gl.CreateProgram();
        gl.AttachShader(result.id, vx);
        gl.AttachShader(result.id, fg);
        gl.LinkProgram(result.id);

        var ok: i32 = 0;
        gl.GetProgramiv(result.id, gl.LINK_STATUS, &ok);
        if (ok == 0) {
            defer gl.DeleteProgram(result.id);

            var error_size: i32 = undefined;
            gl.GetProgramiv(result.id, gl.INFO_LOG_LENGTH, &error_size);

            const message = try alloc.alloc(u8, @intCast(error_size));
            defer alloc.free(message);

            gl.GetProgramInfoLog(result.id, error_size, &error_size, @ptrCast(message));
            std.log.warn("Error occured while linking shader program:\n\t{s}\n", .{message});
        }
        gl.ValidateProgram(result.id);

        return result;
    }

    pub fn getAttrubutes(self: *const Shader) void {
        var count: i32 = 0;
        var size: c_int = 0;
        var arg_type: u32 = 0;
        var name: [100]u8 = undefined;
        var length: c_int = undefined;

        const buf_size: usize = 16;

        gl.GetProgramiv(self.id, gl.ACTIVE_ATTRIBUTES, &count);

        std.debug.print("Attribute count: {d}\n", .{count});
        for (0..@intCast(count)) |i| {
            gl.GetActiveAttrib(
                self.id,
                @intCast(i),
                buf_size,
                &length,
                &size,
                &arg_type,
                @ptrCast(@alignCast(&name)),
            );
            std.debug.print(
                "\tAttribute #{d}:\n\t\tName: {s}\n\t\tType: {d}\n\n",
                .{ i, name, arg_type },
            );
        }
    }

    pub fn getUniforms(self: *const Shader) void {
        var count: i32 = 0;
        var size: c_int = 0;
        var arg_type: u32 = 0;
        var name: [100]u8 = undefined;
        var length: c_int = undefined;

        const buf_size: usize = 16;

        gl.GetProgramiv(self.id, gl.ACTIVE_UNIFORMS, &count);

        std.debug.print("Uniform count: {d}\n", .{count});
        for (0..@intCast(count)) |i| {
            gl.GetActiveAttrib(
                self.id,
                @intCast(i),
                buf_size,
                &length,
                &size,
                &arg_type,
                @ptrCast(@alignCast(&name)),
            );
            std.debug.print(
                "\tUniform #{d}:\n\t\tName: {s}\n\t\tType: {d}\n\n",
                .{ i, name, arg_type },
            );
        }
    }

    pub fn setInVecFloat(
        self: *const Shader,
        attrib_name: []const u8,
        field_array_len: usize,
        field_offset: usize,
    ) void {
        const position_attrib_location = gl.GetAttribLocation(self.id, @ptrCast(attrib_name));
        const position_attrib: c_uint = @intCast(position_attrib_location);
        gl.EnableVertexAttribArray(position_attrib);
        gl.VertexAttribPointer(
            position_attrib,
            @intCast(field_array_len),
            gl.FLOAT,
            gl.FALSE,
            @sizeOf(Vertex),
            field_offset,
        );
    }

    pub fn deinit(self: *const Shader) Shader {
        gl.DeleteProgram(self.id);
        return Shader{};
    }

    pub fn attach(self: *const Shader) void {
        gl.UseProgram(self.id);
    }
};

fn compile(source: []u8, shaderType: c_uint, alloc: *std.mem.Allocator) !u32 {
    const result = gl.CreateShader(shaderType);
    gl.ShaderSource(
        result,
        1,
        @ptrCast(@alignCast(&source)),
        &[1]c_int{@intCast(source.len)},
    );
    gl.CompileShader(result);

    var whu: i32 = undefined;
    gl.GetShaderiv(result, gl.COMPILE_STATUS, &whu);
    if (whu == 0) {
        defer gl.DeleteShader(result);

        var length: i32 = undefined;
        gl.GetShaderiv(result, gl.INFO_LOG_LENGTH, &length);

        const message = try alloc.alloc(u8, @intCast(length));
        defer alloc.free(message);

        gl.GetShaderInfoLog(result, length, &length, @ptrCast(message));

        const mtype: *const [4:0]u8 = if (shaderType == gl.VERTEX_SHADER) "VERT" else "FRAG";

        std.log.warn("Failed to compile shader(Type: {s})!\nError: {s}\n", .{
            mtype,
            message,
        });
    }
    return result;
}
