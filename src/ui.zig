const std = @import("std");
const rl: type = @import("raylib");
const p = @import("particle.zig");
const m = @import("main.zig");

var windowStartTime: u16 = 100;
var timeLeft: u16 = 0;

pub fn draw() void
{
    const CurEnum = @as(p.Material, @enumFromInt(m.enumI));
    if(timeLeft != 0)
    {
        var col: rl.Color = CurEnum.getMatColor();

        col.r = 255 - col.r;
        col.g = 255 - col.g;
        col.b = 255 - col.b;

        rl.drawRectangle(10, 10, rl.measureText(@tagName(CurEnum), 20) + 10, 30, col.alpha(@as(f32, @floatFromInt(timeLeft)) / 20));
    }

    rl.drawText(@tagName(CurEnum), 15, 15, 20, CurEnum.getMatColor());

    const wheel = rl.getMouseWheelMove();

    timeLeft = @max(@as(i17, @intCast(timeLeft)) - 1, 0);
    if(wheel > 0)
    {
        m.enumI = (m.enumI + @as(@TypeOf(m.enumI), @intFromFloat(wheel))) % 17;
        timeLeft = windowStartTime;
    }
    else if(wheel < 0)
    {
        m.enumI = @min(@subWithOverflow(m.enumI, @as(@TypeOf(m.enumI), @intFromFloat(@abs(wheel))))[0], 16);
        timeLeft = windowStartTime;

    }
}