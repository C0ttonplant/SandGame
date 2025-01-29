const std = @import("std");
const r = @import("./random.zig");
const p = @import("./particle.zig");
const sc = @import("./screen.zig");
const rl = @import("raylib");
const man = @import("./main.zig");

pub fn evaluateGas(self: *p.Particle, x: i32, y: i32) void
{
    if(self.material == p.Material.Fire)
    {
        fire(self, x, y);
        return;
    }
    else if(self.material == p.Material.Steam)
    {
        if(steam(self, x, y))
            return;
        
    }


    const par: p.Particle = sc.getParticleAt(x, y-1);
    const par1: p.Particle = sc.getParticleAt(x + 1, y-1);
    const par2: p.Particle = sc.getParticleAt(x - 1, y-1);
    if(par.material == p.Material.None)
    {
        sc.setParticleAt(x, y - 1, self.*);
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
    }
    else if(par1.material == p.Material.None)
    {
        sc.setParticleAt(x + 1, y - 1, self.*);
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
    }
    else if(par2.material == p.Material.None)
    {
        sc.setParticleAt(x - 1, y - 1, self.*);
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
    }
}

fn fire(self: *p.Particle, x: i32, y: i32) void
{
    const offset: f32 = self.colorOffset;

    if(offset < 0)
    {
        const ra: u32 = r.randomNumberu32() % 10;

        if(ra == 0)
        {
            self.* = p.Particle.init(p.Material.Smoke);
        }
        else
        {
            self.* = p.Particle.init(p.Material.None);
        }
    }

    const p1: p.Particle = sc.getParticleAt(x - 1, y);
    const p2: p.Particle = sc.getParticleAt(x - 1, y - 1);
    var p3: p.Particle = sc.getParticleAt(x, y - 1);
    const p4: p.Particle = sc.getParticleAt(x + 1, y - 1);
    const p5: p.Particle = sc.getParticleAt(x + 1, y);

    self.colorOffset -= 0.1;
    if(self.color.r > 1)
        self.color.r -= 1;
    if(self.color.g < 240)
        self.color.g += 20;
    if(self.color.b < 255)
        self.color.b += 1;

    if(p3.properties.canBurn)
    {
        p3.properties.isOnFire = true;
        sc.setParticleAt(x + 1, y, p3);
    }

    // the chance of a particle moving sideways decreases as time goes on
    if(@as(f32, @floatFromInt(r.randomNumberu32() % 10)) < offset and p1.material == p.Material.None)
    {
        // left
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
        sc.setParticleAt(x - 1, y, self.*);
    }
    else if(@as(f32, @floatFromInt(r.randomNumberu32() % 10)) < offset and p5.material == p.Material.None)
    {
        // right
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
        sc.setParticleAt(x + 1, y, self.*);
    }
    else if(r.randomNumberu32() % 4 == 0 and p4.material == p.Material.None)
    {
        // topLeft
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
        sc.setParticleAt(x + 1, y - 1, self.*);
    }
    else if(r.randomNumberu32() % 4 == 0 and p2.material == p.Material.None)
    {
        // topRight
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
        sc.setParticleAt(x - 1, y - 1, self.*);
    }
    else if(p3.material == p.Material.None)
    {
        // top
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
        sc.setParticleAt(x, y - 1, self.*);
    }
    else
    {
        sc.setParticleAt(x, y, self.*);
    }


}

fn steam(self: *p.Particle, x: i32, y: i32) bool
{
    const up: p.Particle = sc.getParticleAt(x, y - 1);

    if(up.properties.state == p.State.Solid)
    {
        self.* = p.Particle.init(p.Material.Water);
        sc.setParticleAt(x, y, self.*);
        return true;
    }
    return false;
}