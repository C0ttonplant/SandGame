const std = @import("std");
const r = @import("./random.zig");
const p = @import("./particle.zig");
const sc = @import("./screen.zig");
const rl = @import("raylib");
const man = @import("./main.zig");


pub fn evaluateLiquid(self: *p.Particle, x: i32, y: i32) void
{
    const par: p.Particle = sc.getParticleAt(x, y+1);
    const par1: p.Particle = sc.getParticleAt(x + 1, y+1);
    const par2: p.Particle = sc.getParticleAt(x - 1, y+1);
    const parU: p.Particle = sc.getParticleAt(x, y - 1);
    _ = parU;

    self.colorOffset = r.randomNumberf32() / 2;

    if(par.material == p.Material.None)
    {
        sc.setParticleAt(x, y + 1, self.*);
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
    }
    else if(par1.material == p.Material.None)
    {
        sc.setParticleAt(x + 1, y + 1, self.*);
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
    }
    else if(par2.material == p.Material.None)
    {
        sc.setParticleAt(x - 1, y + 1, self.*);
        sc.setParticleAt(x, y, p.Particle.init(p.Material.None));
    }
    else 
    {
        const rn: i32 = @mod(r.randomNumberi32(), 3) - 1;

        const parp: p.Particle = sc.getParticleAt(x - rn, y);
        const parb: p.Particle = sc.getBufferAt(x - rn, y);

        if(parp.material == p.Material.None and parb.material == p.Material.None)
        {
            sc.setParticleAt(x - rn, y, self.*);
            sc.setParticleAt(x, y, parb);
        }
        else 
        {
            sc.setParticleAt(x, y, self.*);
        }
    }

    // if(parU.properties.state != p.State.Liquid and parU.material != p.Material.None and !parU.properties.isStructural)
    // {
    //     sc.setParticleAt(x, y - 1, self.*);
    //     sc.setParticleAt(x, y, parU);
    // }
    
}