const std = @import("std");
const sc = @import("./screen.zig");
const p = @import("./particle.zig");
const sav = @import("./save.zig");
const fs = std.fs;
const allocator = std.heap.page_allocator;


pub fn load(fileName: []const u8) anyerror!void
{
    const cwd = fs.cwd();
    var file = cwd.openFile(fileName, .{}) catch
    {
        std.debug.print("File could not be loaded!\n", .{});

        return;
    };
    defer file.close();

    var header: sav.FileStructure = .{};

    try file.seekTo(7);
    var sizeBuff: [4]u8 = undefined;
    _ = try file.read(&sizeBuff);

    header.fileBytes =  ((@as(u32, @intCast(sizeBuff[0])) << 8 | sizeBuff[1]) << 8 | sizeBuff[2]) << 8 | sizeBuff[3];
    std.debug.print("{any}\n", .{header.fileBytes});

    const data = try allocator.alloc(u8, header.fileBytes);
    defer allocator.free(data);

    try file.seekTo(0);

    _ = try file.read(data);

    header.fileType =   data[0];
    header.width =      @as(u16, @intCast(data[1])) << 8 | data[2];
    header.height =     @as(u16, @intCast(data[3])) << 8 | data[4];
    header.bpp =        @as(u16, @intCast(data[5])) << 8 | data[6];

    var tmpParticle: p.Particle = undefined;

    const arrayOffset: u32 = sav.FileStructure.HeaderLengthInBytes;

    var x: u32 = 0;
    var y: u32 = 0;
    var i: u32 = 0;

    while (y < header.height) 
    {
        while (x < header.width) 
        {
            
            switch (header.fileType) 
            {
                0 => // lossless
                {
                    tmpParticle = p.Particle.init(@as(p.Material, @enumFromInt(data[i * header.bpp + arrayOffset + 0])));
                    tmpParticle.properties.isSettled = data[i * header.bpp + arrayOffset + 1] & 0b10 != 0;
                    tmpParticle.properties.isOnFire = data[i * header.bpp + arrayOffset + 1] & 0b01 != 0;
                    tmpParticle.color.r = data[i * header.bpp + arrayOffset + 2];
                    tmpParticle.color.g = data[i * header.bpp + arrayOffset + 3];
                    tmpParticle.color.b = data[i * header.bpp + arrayOffset + 4];
                    var tmpu32: u32 = ((@as(u32, @intCast(data[i * header.bpp + arrayOffset + 5])) << 8 |
                                                                             data[i * header.bpp + arrayOffset + 6]) << 8 | 
                                                                             data[i * header.bpp + arrayOffset + 7]) << 8 | 
                                                                             data[i * header.bpp + arrayOffset + 8];
                    tmpParticle.colorOffset = @as(f32, @bitCast(tmpu32));
                    tmpu32 = ((@as(u32, @intCast(data[i * header.bpp + arrayOffset + 9])) << 8 |
                                                                    data[i * header.bpp + arrayOffset + 10]) << 8 | 
                                                                    data[i * header.bpp + arrayOffset + 11]) << 8 | 
                                                                    data[i * header.bpp + arrayOffset + 12];
                    tmpParticle.properties.framesOnFire = @as(i32, @bitCast(tmpu32));
                    tmpu32 = ((@as(u32, @intCast(data[i * header.bpp + arrayOffset + 13])) << 8 |
                                                                    data[i * header.bpp + arrayOffset + 14]) << 8 | 
                                                                    data[i * header.bpp + arrayOffset + 15]) << 8 | 
                                                                    data[i * header.bpp + arrayOffset + 16];
                    tmpParticle.properties.framesNotMoved = @as(i32, @bitCast(tmpu32));

                    
                },
                1 => // lossy
                {
                    tmpParticle = p.Particle.init(@as(p.Material, @enumFromInt(data[i * header.bpp + arrayOffset + 0])));
                    tmpParticle.properties.isSettled = data[i * header.bpp + arrayOffset + 1] & 0b10 != 0;
                    tmpParticle.properties.isOnFire = data[i * header.bpp + arrayOffset + 1] & 0b01 != 0;

                    if(tmpParticle.properties.state == p.State.Solid)
                        tmpParticle.properties.isSettled = true;
                },
                2 => // extremlyLossy
                {
                    tmpParticle = p.Particle.init(@as(p.Material, @enumFromInt(data[i * header.bpp + arrayOffset + 0])));

                    if(tmpParticle.properties.state == p.State.Solid)
                        tmpParticle.properties.isSettled = true;
                },
                else => return,
            }

            sc.particles[x][y] = tmpParticle;
            sc.buffer[x][y] = tmpParticle;

            x += 1;
            i += 1;
        }
        x = 0;
        y += 1;
    }

    std.debug.print("loaded!\n", .{});

}