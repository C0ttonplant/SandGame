const std = @import("std");

pub var seed: u32 = 1;

const M: u32 = 0x7fffffff;
const A: u32 = 48271;
const Q: u32 = M / A;
const R: u32 = M % A;


pub fn randomNumberu32() u32
{
   
    const div: u32 = @divFloor(seed, Q);
    const rem: u32 = seed % Q;

    const s: i32 = @as(i32, @intCast(rem * A));
    const t: i32 = @as(i32, @intCast(div * R));
    var result: i32 = s - t;

    if(result < 0) result += M;

    seed = @as(u32, @intCast(result));
    return seed;
}

pub fn randomNumberi32() i32
{
   
    const div: u32 = @divFloor(seed, Q);
    const rem: u32 = seed % Q;

    const s: i32 = @as(i32, @intCast(rem * A));
    const t: i32 = @as(i32, @intCast(div * R));
    var result: i32 = s - t;

    if(result < 0) result += M;

    seed = @as(u32, @intCast(result));
    return result;
}

pub fn randomNumberf32() f32
{

    const div: u32 = @divFloor(seed, Q);
    const rem: u32 = seed % Q;

    const s: i32 = @as(i32, @intCast(rem * A));
    const t: i32 = @as(i32, @intCast(div * R));
    var result: i32 = s - t;

    if(result < 0) result += M;

    seed = @as(u32, @intCast(result));

    return @as(f32, @floatFromInt(seed % 10000)) / 10000;
}
