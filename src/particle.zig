const std = @import("std");
const rl = @import("raylib");
const r = @import("./random.zig");
const sc = @import("./screen.zig");
const man = @import("./main.zig");

const s = @import("./solid.zig");
const l = @import("./liquid.zig");
const g = @import("./gas.zig");

pub const Particle = struct 
{
    material: Material = Material.None,
    color: rl.Color = rl.Color.black,
    colorOffset: f32 = 0,
    velocity: rl.Vector2 = .{ .x = 0, .y = 0 },
    properties: Properties = .{},

    pub fn init(mat: Material) Particle
    {
        var p: Particle = undefined;

        p.material = mat;
        p.color = mat.getMatColor();
        p.colorOffset = -r.randomNumberf32() / 2;
        p.velocity = rl.Vector2.init(0, 0);
        p.properties = mat.getMatProperties();

        if(mat == Material.Fire) p.colorOffset = r.randomNumberf32() / 2 + 0.5;

        return p;
    }

    pub fn procces(self: Particle, x: i32, y: i32) void
    {
        var se: Particle = self;
        
        if(se.material != Material.None)
        {
            switch (se.properties.state) 
            {
                .Solid => s.evaluateSolid(&se, x, y),
                .Liquid => l.evaluateLiquid(&se, x, y),
                .Gas => g.evaluateGas(&se, x, y),
            }
        }
    }

    pub fn moveToPoint(self: Particle, x: i32, y: i23) void
    {
        _ = self;
        _ = x;
        _ = y;
    }
};

pub const Properties = struct 
{
    state: State = State.Gas,
    canBurn: bool = false,
    canCorode: bool = false,
    canExplode: bool = false,
    isSettled: bool = false,
    isOnFire: bool = false,
    framesOnFire: i32 = 0,
    isFire: bool = false,
    isStructural: bool = false,         // only for solids
    framesNotMoved: i32 = 0,
    fireSpread: f32 = 1,                // 0 is the slowest
    viscosityIntegrity: i32 = 0,        // structural integrity for solids, viscosity for liquids (0-max)
    strength: f32 = 0,                  // (0-max)
    density: f32 = 4,                   // mostly for liquids (0-max)
};

pub const State = enum 
{
    Solid,
    Liquid,
    Gas,
};

pub const Material = enum 
{
    None,
    // solids
    Sand,
    Gravel,
    Dirt,
    Mud,
    Coal,
    Stone,
    Wood,
    Metal,
    Indestrucable,

    // liquids
    Water,
    Oil,
    Nitro,

    // gasses
    Steam,
    Fire,
    Smoke,
    NaturalGas,

    pub fn getMatProperties(self: Material) Properties
    {
        switch (self) 
        {
            .None => return .{},

            .Sand           => return .{ .state = State.Solid, .canBurn = false, .canCorode = false, .isStructural = false, .viscosityIntegrity = 1,  .strength = 0.0, .density = 4},
            .Gravel         => return .{ .state = State.Solid, .canBurn = false, .canCorode = false, .isStructural = false, .viscosityIntegrity = 5,  .strength = 3.0, .density = 10},
            .Dirt           => return .{ .state = State.Solid, .canBurn = false, .canCorode = false, .isStructural = true,  .viscosityIntegrity = 0,  .strength = 1.5, .density = 2},
            .Mud            => return .{ .state = State.Solid, .canBurn = true,  .canCorode = false, .isStructural = false, .viscosityIntegrity = 1,  .strength = 0.6, .density = 3},
            .Coal           => return .{ .state = State.Solid, .canBurn = true,  .canCorode = false, .isStructural = false, .viscosityIntegrity = 3,  .strength = 2.0, .density = 2,   .fireSpread = 0.2},
            .Stone          => return .{ .state = State.Solid, .canBurn = false, .canCorode = false, .isStructural = true,  .viscosityIntegrity = 0,  .strength = 10,  .density = 12},
            .Wood           => return .{ .state = State.Solid, .canBurn = true,  .canCorode = true,  .isStructural = true,  .viscosityIntegrity = 0,  .strength = 6.0, .density = 0.8},
            .Metal          => return .{ .state = State.Solid, .canBurn = false, .canCorode = true,  .isStructural = true,  .viscosityIntegrity = 0,  .strength = 12,  .density = 15},
            .Indestrucable  => return .{ .state = State.Solid, .canBurn = false, .canCorode = false, .isStructural = true,  .viscosityIntegrity = 0,  .strength = 0xFFFFFFFFFFF,   .density = 15},

            .Water          => return .{ .state = State.Liquid, .canBurn = false, .canCorode = false, .isStructural = false, .viscosityIntegrity = 5, .strength = 0.0, .density = 1},
            .Oil            => return .{ .state = State.Liquid, .canBurn = true,  .canCorode = false, .isStructural = false, .viscosityIntegrity = 2, .strength = 0.0, .density = 1,  .fireSpread = 2},
            .Nitro          => return .{ .state = State.Liquid, .canBurn = true,  .canCorode = false, .isStructural = false, .viscosityIntegrity = 3, .strength = 0.0, .density = 1,  .canExplode = true},

            .Steam          => return .{ .state = State.Gas, .canBurn = false, .canCorode = false, .isStructural = false, .viscosityIntegrity = 5, .strength = 0.0, .density = 0.1},
            .Fire           => return .{ .state = State.Gas, .canBurn = false, .canCorode = false, .isStructural = false, .viscosityIntegrity = 1, .strength = 0.0, .density = 0.0,   .isFire = true},
            .Smoke          => return .{ .state = State.Gas, .canBurn = false, .canCorode = false, .isStructural = false, .viscosityIntegrity = 3, .strength = 0.0, .density = 0.2},
            .NaturalGas     => return .{ .state = State.Gas, .canBurn = true,  .canCorode = false, .isStructural = false, .viscosityIntegrity = 2, .strength = 0.0, .density = 0.3,   .fireSpread = 4},

        }
    }

    pub fn getMatColor(self: Material) rl.Color
    {
        switch (self) 
        {
            .None => return rl.Color.black,

            .Sand           => return rl.Color.yellow,
            .Gravel         => return rl.Color.gray,
            .Dirt           => return rl.Color.beige,
            .Mud            => return rl.Color.init(0x70, 0x54, 0x3e, 0xff),
            .Coal           => return rl.Color.init(50, 50, 60, 255),
            .Stone          => return rl.Color.dark_gray,
            .Wood           => return rl.Color.dark_brown,
            .Metal          => return rl.Color.dark_purple,
            .Indestrucable  => return rl.Color.white,

            .Water          => return rl.Color.blue,
            .Oil            => return rl.Color.init(60, 60, 40, 255),
            .Nitro          => return rl.Color.green,

            .Steam          => return rl.Color.sky_blue,
            .Fire           => return rl.Color.red,
            .Smoke          => return rl.Color.init(150, 150, 150, 255),
            .NaturalGas     => return rl.Color.dark_green,
        }
    }
};
