const std = @import("std");
const p = @import("./particle.zig");
const rl = @import("raylib");
const man = @import("./main.zig");
const r = @import("./random.zig");

pub const worldWidth: u32 = 400;
pub const worldHeight: u32 = 200;

pub var screenDim: rl.Vector2 = undefined;

const source: rl.Rectangle = rl.Rectangle.init(0, 0, @as(f32, @floatFromInt(worldWidth)), @as(f32, @floatFromInt(worldHeight)));//rl.Rectangle.init(0, @as(f32, @floatFromInt(worldHeight)), @as(f32, @floatFromInt(worldWidth)), -@as(f32, @floatFromInt(worldHeight)));
var dest: rl.Rectangle = undefined;

pub var particles: [worldWidth][worldHeight]p.Particle = undefined;
pub var buffer: [worldWidth][worldHeight]p.Particle = undefined;
pub var screenTex: rl.RenderTexture2D = undefined;

var tmp: p.Particle = undefined;

pub fn init() anyerror!void
{
    tmp = p.Particle.init(p.Material.Indestrucable);

    var i: u32 = 0;
    var j: u32 = 0;

    while (i < worldWidth) 
    {
        while (j < worldHeight) 
        {
            particles[i][j] = .{};
            buffer[i][j] = .{};
            j += 1;
        }
        j = 0;
        i += 1;
    }

    screenDim.x = @as(f32, @floatFromInt(rl.getScreenWidth()));
    screenDim.y = @as(f32, @floatFromInt(rl.getScreenHeight()));

    screenTex = try rl.RenderTexture2D.init(worldWidth, worldHeight);

    const worldx: f32 = @as(f32, @floatFromInt(worldWidth));
    const worldy: f32 = @as(f32, @floatFromInt(worldHeight));

    man.camera.zoom = @min(screenDim.x / worldx, screenDim.y / worldy);

    dest = rl.Rectangle.init(-worldx / 2, -worldy / 2,worldx, worldy);
}

pub const Surrounding = struct 
{
    tl: p.Particle,
    t: p.Particle,
    tr: p.Particle,
    r: p.Particle,
    br: p.Particle,
    b: p.Particle,
    bl: p.Particle,
    l: p.Particle,

    pub fn getFromPos(x: i32, y: i32) Surrounding
    {
        var su: Surrounding = undefined;

        su.tl = getParticleAt(x - 1, y - 1);
        su.t =  getParticleAt(x    , y - 1);
        su.tr = getParticleAt(x + 1, y - 1);
        su.r =  getParticleAt(x + 1, y    );
        su.br = getParticleAt(x - 1, y + 1);
        su.b =  getParticleAt(x    , y + 1);
        su.bl = getParticleAt(x - 1, y + 1);
        su.l =  getParticleAt(x - 1, y    );

        return su;
    }
};

pub fn getParticleAt(x: i32, y: i32) p.Particle
{

    if(x >= 0 and x < worldWidth and y >= 0 and y < worldHeight)
    {
        return particles[@as(u32, @intCast(x))][@as(u32, @intCast(y))];
    }
    else
    {
        
        return tmp;
    }
}

pub fn getBufferAt(x: i32, y: i32) p.Particle
{

    if(x >= 0 and x < worldWidth and y >= 0 and y < worldHeight)
    {
        return buffer[@as(u32, @intCast(x))][@as(u32, @intCast(y))];
    }
    else
    {
        
        return tmp;
    }
}

pub fn setParticleAt(x: i32, y: i32, par: p.Particle) void
{
    if(x >= 0 and x < worldWidth and y >= 0 and y < worldHeight)
    {
        buffer[@as(u32, @intCast(x))][@as(u32, @intCast(y))] = par;
    }
}

pub fn proccesAll() void
{
    var x: u32 = 0;
    var y: u32 = 0;

    while (y < worldHeight) 
    {
        while (x < worldWidth) 
        {
            particles[x][y].procces(@as(i32, @intCast(x)), @as(i32, @intCast(y)));
            x += 1;
        }
        x = 0;

        y += 1;
    }
}

pub fn updateTexture() void
{
    var par: p.Particle = undefined;
    var x: u32 = 0;
    var y: u32 = 0;

    rl.beginTextureMode(screenTex);
    defer rl.endTextureMode();
    rl.clearBackground(rl.Color.black);


    while (y < worldHeight) 
    {
        while (x < worldWidth) 
        {
            par = buffer[x][(worldHeight - 1) - y];
            particles[x][(worldHeight - 1) - y] = par;
            
            rl.drawPixel(@as(i32, @intCast(x)), @as(i32, @intCast(y)), par.color.brightness(par.colorOffset));
            x += 1;
        }
        x = 0;
        y += 1;
    }
}

pub fn checkForScreenResize() void
{
    if(rl.isWindowResized())
    {
        screenDim.x = @as(f32, @floatFromInt(rl.getScreenWidth()));
        screenDim.y = @as(f32, @floatFromInt(rl.getScreenHeight()));

        const worldx: f32 = @as(f32, @floatFromInt(worldWidth));
        const worldy: f32 = @as(f32, @floatFromInt(worldHeight));

        dest = rl.Rectangle.init(-worldx / 2, -worldy / 2,worldx, worldy);

        man.camera.zoom = @min(screenDim.x / worldx, screenDim.y / worldy);
        man.camera.offset = rl.Vector2.init(screenDim.x / 2, screenDim.y / 2);

    }
}

pub fn updateMousePos() void
{
    const po: rl.Vector2 = rl.getScreenToWorld2D(rl.getMousePosition(), man.camera);

    man.mousex = @as(i32, @intFromFloat(po.x)) + @divFloor(worldWidth, 2);
    man.mousey = @as(i32, @intFromFloat(po.y)) + @divFloor(worldHeight, 2);

    if(rl.getMouseX() < @divFloor(rl.getScreenWidth(), 2)) man.mousex -= 1;
    if(rl.getMouseY() < @divFloor(rl.getScreenHeight(), 2)) man.mousey -= 1;
}

pub fn updateInput() void
{

    if(rl.isKeyReleased(rl.KeyboardKey.one))
    {
        radius = 1;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.two))
    {
        radius = 2;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.three))
    {
        radius = 3;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.four))
    {
        radius = 4;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.five))
    {
        radius = 5;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.six))
    {
        radius = 6;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.seven))
    {
        radius = 7;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.eight))
    {
        radius = 8;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.nine))
    {
        radius = 9;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.zero))
    {
        radius = 0;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.equal))
    {
        radius += 1;
    }
    if(rl.isKeyReleased(rl.KeyboardKey.minus))
    {
        radius -= 1;
    }

    if(rl.isMouseButtonDown(rl.MouseButton.left))
    {
        setParticleAt(man.mousex, man.mousey, p.Particle.init(@as(p.Material, @enumFromInt(man.enumI))));
    }   
}

    var radius: f32 = 5;
pub fn circleBrush() void
{
    var angle: f32 = 0;
    var xnorm: f32 = 0;
    var ynorm: f32 = 0;
    var xval: i32 = 0;
    var yval: i32 = 0;
    var dist: f32 = 0;
    // var part: p.Particle = p.Particle.init(p.Material.None);
    // part.color.r = @as(u8, @intCast(r.randomNumberu32() % 256));
    // part.color.g = @as(u8, @intCast(r.randomNumberu32() % 256));
    // part.color.b = @as(u8, @intCast(r.randomNumberu32() % 256));
    
    

    while (angle < 361) 
    {
        xnorm = std.math.cos(angle);
        ynorm = std.math.sin(angle);

        // part.colorOffset = -r.randomNumberf32() / 2;
        while (dist < radius) 
        {
            xval = @as(i32, @intFromFloat(xnorm * dist)) + man.mousex;
            yval = @as(i32, @intFromFloat(ynorm * dist)) + man.mousey;

            setParticleAt(xval, yval, p.Particle.init(@as(p.Material, @enumFromInt(man.enumI))));
            dist += 1;
        }
        dist = 0;
        angle += 1;
    }
    angle = 0;
}

pub fn explosion(strength: f32) void
{
    var angle: f32 = 0;
    var xnorm: f32 = 0;
    var ynorm: f32 = 0;
    var xval: i32 = 0;
    var yval: i32 = 0;
    var dist: f32 = 0;
    var offset: f32 = 0;
    var par: p.Particle = undefined;
    var remainingStr: f32 = 0;
    while (angle < 361) 
    {
        xnorm = std.math.cos(angle);
        ynorm = std.math.sin(angle);

        offset = r.randomNumberf32() / 3;
        remainingStr = strength;
        while (dist < strength) 
        {
            xval = @as(i32, @intFromFloat(xnorm * dist)) + man.mousex;
            yval = @as(i32, @intFromFloat(ynorm * dist)) + man.mousey;

            par = getParticleAt(xval, yval);
            if(par.material  != p.Material.None)
            {
                par.colorOffset = -(strength / dist * offset) / 2 - (r.randomNumberf32() / 2);

                par.colorOffset = @max(-0.75, par.colorOffset);
            }

            // TODO: give particles velocity    

            remainingStr -= @max(1, par.properties.strength / 3);
            // if(remainingStr < 0)
            // {
            //     break;
            // }

            if(par.properties.strength < remainingStr / 2)
            {
                par = p.Particle.init(p.Material.None);
            }

            setParticleAt(xval, yval, par);
            dist += 1;
        }
        dist = 0;
        angle += 1;
    }
    angle = 0;
}

pub fn drawTexture() void
{
    rl.drawTexturePro(screenTex.texture,source, dest, rl.Vector2.init(0, 0), 0, rl.Color.white);
}
