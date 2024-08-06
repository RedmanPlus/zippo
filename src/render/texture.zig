const gl = @import("gl");

const c = @import("../c.zig");

const TextureError = error{
    ImageLoadFailed,
};

pub const Texture = struct {
    id: c_uint,

    pub fn init(filename: []const u8) !Texture {
        var texture_id: c_uint = undefined;
        gl.GenTextures(1, @ptrCast(@alignCast(&texture_id)));
        gl.BindTexture(gl.TEXTURE_2D, texture_id);

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        var width: c_int = undefined;
        var height: c_int = undefined;
        var n_channels: c_int = undefined;

        const data = c.stbi_load(@ptrCast(@alignCast(filename)), &width, &height, &n_channels, 0);
        defer c.stbi_image_free(data);

        if (data != null) {
            gl.TexImage2D(
                gl.TEXTURE_2D,
                0,
                gl.RGB,
                width,
                height,
                0,
                gl.RGB,
                gl.UNSIGNED_BYTE,
                data.?,
            );
            gl.GenerateMipmap(gl.TEXTURE_2D);
        } else {
            return TextureError.ImageLoadFailed;
        }

        return .{ .id = texture_id };
    }

    pub fn deinit(self: *Texture) void {
        gl.DeleteTextures(1, self.id);
    }

    pub fn bind(self: *Texture) void {
        gl.BindTexture(gl.TEXTURE_2D, self.id);
    }
};
