const std = @import("std");
const sc = @import("./screen.zig");
const p = @import("./particle.zig");
const nfd = @import("nfd");
const fs = std.fs;
const allocator = std.heap.page_allocator;

pub const SaveModes = enum 
{
    Lossless,
    Lossy,
    ExtremlyLossy,
};

//                                          lossyist:   lossy:  lossles:
//     material: Material = Material.None,  need        need    need        1by
//     color: rl.Color = rl.Color.black,    dont        dont    need        3by ignoring alpha
//     colorOffset: f32 = 0,                dont        dont    need        4by
//     properties: Properties = .{},        \/\/        \/\/    \/\/
// pub const Properties = struct            
// {                                        
//     state: State = State.Gas,            dont        dont    dont        1by
//     canBurn: bool = false,               dont        dont    dont        | 1by
//     canCorode: bool = false,             dont        dont    dont        |
//     canExplode: bool = false,            dont        dont    dont        |
//     isSettled: bool = false,             dont        need    need        |
//     isOnFire: bool = false,              dont        need    need        |
//     isFire: bool = false,                dont        dont    dont        |
//     isStructural: bool = false,          dont        dont    dont        |
//     framesOnFire: i32 = 0,               dont        dont    need        4by
//     framesNotMoved: i32 = 0,             dont        dont    need        4by
//     fireSpread: f32 = 1,                 dont        dont    dont        4by
//     viscosityIntegrity: i32 = 0,         dont        dont    dont        4by
//     strength: f32 = 0,                   dont        dont    dont        4by
//     density: f32 = 4,                    dont        dont    dont        4by
// };

pub const FileStructure = struct 
{
    // BPP = Bytes per pixel
    pub const ExtremlyLossyBPP: u32 = 1;
    pub const LossyBPP: u32 = 2;
    pub const LosslessBPP: u32 = 17;

    pub const HeaderLengthInBytes: u16 = 11;

    fileType:   u8  = 0,
    width:      u16 = 0,
    height:     u16 = 0,
    bpp:        u16 = 0,
    fileBytes:  u32 = 0,

    pub fn init(saveMode: SaveModes) FileStructure
    {
        var fi: FileStructure = .{};

        fi.fileType = @as(u8, @intFromEnum(saveMode));
        fi.width = @as(u16, @intCast(sc.worldWidth));
        fi.height = @as(u16, @intCast(sc.worldHeight));
        
        switch (saveMode) 
        {
            .ExtremlyLossy => fi.bpp = FileStructure.ExtremlyLossyBPP,
            .Lossy => fi.bpp = FileStructure.LossyBPP,
            .Lossless => fi.bpp = FileStructure.LosslessBPP,
        }

        fi.fileBytes = FileStructure.HeaderLengthInBytes + (fi.bpp * @as(u32, @intCast(fi.width)) * fi.height);

        return fi;
    }

    pub fn getHeaderArray(self: FileStructure) [FileStructure.HeaderLengthInBytes]u8
    {
        var arr: [FileStructure.HeaderLengthInBytes]u8 = undefined;

        arr[0] = self.fileType;

        arr[1]  = @as(u8, @intCast(0b11111111 & (self.width >> 8)));
        arr[2]  = @as(u8, @intCast(0b11111111 &  self.width));

        arr[3]  = @as(u8, @intCast(0b11111111 & (self.height >> 8)));
        arr[4]  = @as(u8, @intCast(0b11111111 &  self.height));

        arr[5]  = @as(u8, @intCast(0b11111111 & (self.bpp >> 8)));
        arr[6]  = @as(u8, @intCast(0b11111111 &  self.bpp));

        arr[7]  = @as(u8, @intCast(0b11111111 & (self.fileBytes >> 24)));
        arr[8]  = @as(u8, @intCast(0b11111111 & (self.fileBytes >> 16)));
        arr[9]  = @as(u8, @intCast(0b11111111 & (self.fileBytes >> 8)));
        arr[10] = @as(u8, @intCast(0b11111111 &  self.fileBytes));

        return arr;
    }
};

pub const ParticleStructure = struct 
{
    material: u8 = 0,
    settled: u8 = 0,
    onFire: u8 = 0,
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,
    colorOff: u32 = 0,
    fireFrames: u32 = 0,
    moveFrames: u32 = 0,

    pub fn getLossless(par: p.Particle) []const u8
    {
        var ps: ParticleStructure = .{};
        var arr: [FileStructure.LosslessBPP]u8 = undefined;

        ps.material = @as(u8, @intFromEnum(par.material));

        switch (par.properties.isSettled) 
        {
            true => ps.settled = 1,
            false => ps.settled = 0,
        }
        switch (par.properties.isOnFire) 
        {
            true => ps.onFire = 1,
            false => ps.onFire = 0,
        }

        ps.red = par.color.r;
        ps.green = par.color.g;
        ps.blue = par.color.b;

        // TODO: check that this does what i think it does
        ps.colorOff =  @bitCast(par.colorOffset);
        ps.fireFrames = @bitCast(par.properties.framesOnFire);
        ps.moveFrames = @bitCast(par.properties.framesNotMoved);

        arr[0] = ps.material;

        arr[1] = (ps.settled << 1) | ps.onFire;

        arr[2] = ps.red;
        arr[3] = ps.green;
        arr[4] = ps.blue;

        arr[5]  = @as(u8, @intCast(0b11111111 & (ps.colorOff >> 24)));
        arr[6]  = @as(u8, @intCast(0b11111111 & (ps.colorOff >> 16)));
        arr[7]  = @as(u8, @intCast(0b11111111 & (ps.colorOff >> 8)));
        arr[8]  = @as(u8, @intCast(0b11111111 &  ps.colorOff));

        arr[9]  = @as(u8, @intCast(0b11111111 & (ps.fireFrames >> 24)));
        arr[10] = @as(u8, @intCast(0b11111111 & (ps.fireFrames >> 16)));
        arr[11] = @as(u8, @intCast(0b11111111 & (ps.fireFrames >> 8)));
        arr[12] = @as(u8, @intCast(0b11111111 &  ps.fireFrames));

        arr[13] = @as(u8, @intCast(0b11111111 & (ps.moveFrames >> 24)));
        arr[14] = @as(u8, @intCast(0b11111111 & (ps.moveFrames >> 16)));
        arr[15] = @as(u8, @intCast(0b11111111 & (ps.moveFrames >> 8)));
        arr[16] = @as(u8, @intCast(0b11111111 &  ps.moveFrames));

        return &arr;
    }

    pub fn getLossy(par: p.Particle) []const u8
    {
        var ps: ParticleStructure = .{};
        var arr: [FileStructure.LossyBPP]u8 = undefined;

        ps.material = @as(u8, @intFromEnum(par.material));

        switch (par.properties.isSettled) 
        {
            true => ps.settled = 1,
            false => ps.settled = 0,
        }
        switch (par.properties.isOnFire) 
        {
            true => ps.onFire = 1,
            false => ps.onFire = 0,
        }

        arr[0] = ps.material;

        arr[1] = 0;
        arr[1] = (ps.settled << 1) | ps.onFire;

        return &arr;
    }

    pub fn getExtremlyLossy(par: p.Particle) []const u8
    {
        var ps: ParticleStructure = .{};
        var arr: [FileStructure.ExtremlyLossyBPP]u8 = undefined;

        ps.material = @as(u8, @intFromEnum(par.material));

        arr[0] = ps.material;

        return &arr;
    }

    pub fn getData(par: p.Particle, savemode: SaveModes) []const u8
    {
        var dat: []const u8 = undefined;

        switch (savemode) 
        {
            .Lossless =>        dat = getLossless(par),
            .Lossy =>           dat = getLossy(par),
            .ExtremlyLossy =>   dat = getExtremlyLossy(par),
        }
        return dat;
    }

};

pub fn save(saveMode: SaveModes, fileName: []const u8) !void
{
    const cwd = fs.cwd();

    //TODO: add file dialouge
    // var path: ?[]const u8 = try cwd.realpathAlloc(allocator, fileName);
    // defer allocator.free(&path);


    // try nfd.saveFileDialog(".sand", path[:0]) orelse
    // {
    //     std.debug.print("ERROR: failed to save.\n", .{});
    //     return;
    // };

    var header: FileStructure = FileStructure.init(saveMode);

    const file = try cwd.createFile(fileName, .{ .read = true });
    defer file.close();

    const memory = try allocator.alloc(u8, header.fileBytes);
    defer allocator.free(memory);

    const headD = header.getHeaderArray();

    var i: u32 = 0;
    var x: u32 = 0;
    var y: u32 = 0;

    while (i < FileStructure.HeaderLengthInBytes) 
    {
        memory[i] = headD[i];
        i += 1;
    }
    // i * header.bpp = headerlen
    i = 0;
    var j: u32 = 0;
    while (j < @divFloor(header.fileBytes - FileStructure.HeaderLengthInBytes, header.bpp)) 
    {
        i = FileStructure.HeaderLengthInBytes;
        const dat = ParticleStructure.getData(sc.particles[x][y], saveMode);
        memory[j * header.bpp + i] = dat[0];
        if(saveMode != SaveModes.ExtremlyLossy)
        {
            memory[j * header.bpp + 1 + i] = dat[1];
        }
        if(saveMode == SaveModes.Lossless)
        {
            memory[j * header.bpp + i + 2]  = dat[2];
            memory[j * header.bpp + i + 3]  = dat[3];
            memory[j * header.bpp + i + 4]  = dat[4];
            memory[j * header.bpp + i + 5]  = dat[5];
            memory[j * header.bpp + i + 6]  = dat[6];
            memory[j * header.bpp + i + 7]  = dat[7];
            memory[j * header.bpp + i + 8]  = dat[8];
            memory[j * header.bpp + i + 9]  = dat[9];
            memory[j * header.bpp + i + 10] = dat[10];
            memory[j * header.bpp + i + 11] = dat[11];
            memory[j * header.bpp + i + 12] = dat[12];
            memory[j * header.bpp + i + 13] = dat[13];
            memory[j * header.bpp + i + 14] = dat[14];
            memory[j * header.bpp + i + 15] = dat[15];
            memory[j * header.bpp + i + 16] = dat[16];
        }
        if(x < sc.worldWidth - 1)
        {
            x += 1;
        }
        else if(y < sc.worldHeight - 1)
        {
            x = 0;
            y += 1;
        }
        else 
        {
            x = 0;
            y = 0;
        }
        j += 1;
    }


    _ = try file.writeAll(memory);

    std.debug.print("saved!\n", .{});
}

