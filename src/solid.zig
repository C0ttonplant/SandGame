const std = @import("std");
const r = @import("./random.zig");
const p = @import("./particle.zig");
const sc = @import("./screen.zig");
const rl = @import("raylib");
const man = @import("./main.zig");


pub fn evaluateSolid(self: *p.Particle, x: i32, y: i32) void
{
    if(self.properties.isOnFire) burn(self, x, y);

    if(checkDirt(self, x, y))
    {
        return;
    }

    if(self.properties.isStructural)
    {
        sc.setParticleAt(x, y, self.*);
        return;
    }

    if(checkMud(self, x, y))
    {
        return;
    }

    const dir: i32 = @mod(r.randomNumberi32(), 3) - 1;

    const par: p.Particle = sc.getParticleAt(x, y+1);
    const par1: p.Particle = sc.getParticleAt(x + dir, y+1);
    const par2: p.Particle = sc.getParticleAt(x - dir, y+1);
    

    const fall: bool = checkIfCouldFall(self, x, y, par);

    if(par.properties.state != p.State.Solid and fall)
    {
        self.properties.framesNotMoved = 0;
        sc.setParticleAt(x, y + 1, self.*);
        sc.setParticleAt(x, y, par);
    }
    else if(par1.properties.state != p.State.Solid and fall)
    {
        self.properties.framesNotMoved = 0;
        sc.setParticleAt(x + dir, y + 1, self.*);
        sc.setParticleAt(x, y, par1);
    }
    else if(par2.properties.state != p.State.Solid and fall)
    {
        self.properties.framesNotMoved = 0;
        sc.setParticleAt(x - dir, y + 1, self.*);
        sc.setParticleAt(x, y, par2);
    }
    else
    {
        self.properties.framesNotMoved += 1;
        sc.setParticleAt(x, y, self.*);
    }

}


fn checkIfCouldFall(self: *p.Particle, x: i32, y: i32, particleBelow: p.Particle) bool
{
    const parU1: p.Particle = sc.getParticleAt(x - 1, y);
    const parU2: p.Particle = sc.getParticleAt(x + 1, y);
    const parU3: p.Particle = sc.getParticleAt(x - 1, y + 1);
    const parU4: p.Particle = sc.getParticleAt(x + 1, y + 1);

    if(parU1.properties.state == p.State.Solid and @mod(r.randomNumberi32(), self.properties.viscosityIntegrity) < 1
    and parU3.material == p.Material.None)
    {
        self.properties.isSettled = false;
        self.properties.framesNotMoved = 0;
    }
    if(parU2.properties.state == p.State.Solid and @mod(r.randomNumberi32(), self.properties.viscosityIntegrity) < 1
    and parU4.material == p.Material.None)
    {
        self.properties.isSettled = false;
        self.properties.framesNotMoved = 0;
    }

    if( particleBelow.material == p.Material.None or particleBelow.properties.state != p.State.Solid)
    {
        self.properties.isSettled = false;
        return true;
    }

    if(self.properties.isSettled) return false;

    if(@mod(r.randomNumberi32(), self.properties.viscosityIntegrity) < 1
        and self.properties.framesNotMoved < 4)
    {
        return true;
    }
    else 
    {
        if(self.properties.framesNotMoved > 3)
        {
            self.properties.isSettled = true;
        }
        return false;
    }
}

fn burn(self: *p.Particle, x: i32, y: i32) void
{

    self.color = rl.Color.red;
    self.colorOffset = -r.randomNumberf32() / 2;
    self.properties.framesOnFire += 1;

    if(self.properties.framesOnFire > @mod(r.randomNumberi32(), 100))
    {
        self.* = p.Particle.init(p.Material.Coal);
        return;
    }
    
    var s = sc.Surrounding.getFromPos(x, y);

    const ra: u32 = r.randomNumberu32() % 256;

    if(ra & 0b10000000 != 0 and s.t.properties.canBurn and !s.t.properties.isOnFire)
    {
        s.t.properties.isOnFire = true;
        sc.setParticleAt(x, y - 1, s.t);
    }
    if(ra & 0b01000000 != 0 and s.tl.properties.canBurn and !s.tl.properties.isOnFire)
    {
        s.tl.properties.isOnFire = true;
        sc.setParticleAt(x - 1, y - 1, s.tl);
        
    }
    if(ra & 0b00100000 != 0 and s.tr.properties.canBurn and !s.tr.properties.isOnFire)
    {
        s.tr.properties.isOnFire = true;
        sc.setParticleAt(x + 1, y - 1, s.tr);
        
    }
    if(ra & 0b00010000 != 0 and s.r.properties.canBurn and !s.r.properties.isOnFire)
    {
        s.r.properties.isOnFire = true;
        sc.setParticleAt(x + 1, y, s.r);
        
    }
    if(ra & 0b00001000 != 0 and s.l.properties.canBurn and !s.l.properties.isOnFire)
    {
        s.l.properties.isOnFire = true;
        sc.setParticleAt(x - 1, y, s.l);
        
    }
    if(ra & 0b00000100 != 0 and s.br.properties.canBurn and !s.br.properties.isOnFire)
    {
        s.br.properties.isOnFire = true;
        sc.setParticleAt(x + 1, y + 1, s.br);
        
    }
    if(ra & 0b00000010 != 0 and s.bl.properties.canBurn and !s.bl.properties.isOnFire)
    {
        s.bl.properties.isOnFire = true;
        sc.setParticleAt(x - 1, y + 1, s.bl);
        
    }
    if(ra & 0b00000001 != 0 and s.b.properties.canBurn and !s.b.properties.isOnFire)
    {
        s.b.properties.isOnFire = true;
        sc.setParticleAt(x, y + 1, s.b);
        
    }
}

fn checkDirt(self: *p.Particle, x: i32, y: i32) bool
{

    if(self.material != p.Material.Dirt)
    {
        return false;
    }

    const su: sc.Surrounding = sc.Surrounding.getFromPos(x, y);

    if(su.t.material == p.Material.Mud and r.randomNumberu32() % 100 == 0)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }
    if(su.tr.material == p.Material.Mud and r.randomNumberu32() % 100 == 0)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }
    if(su.tl.material == p.Material.Mud and r.randomNumberu32() % 100 == 0)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }

    if(su.b.material == p.Material.Water)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }
    if(su.l.material == p.Material.Water)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }
    if(su.t.material == p.Material.Water)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }
    if(su.r.material == p.Material.Water)
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Mud));
        return true;
    }
    return false;
}

fn checkMud(self: *p.Particle, x: i32, y: i32) bool
{
    if(self.material != p.Material.Mud)
    {
        return false;
    }

    const su = sc.Surrounding.getFromPos(x, y);

    if(su.b.properties.state != p.State.Gas and su.t.properties.state != p.State.Gas and su.l.properties.state != p.State.Gas and su.r.properties.state != p.State.Gas
    and su.t.material != p.Material.Dirt)
    {
        return false;
    }

    if(self.properties.framesNotMoved > (@mod(r.randomNumberi32(), 5000) + 1000))
    {
        sc.setParticleAt(x, y, p.Particle.init(p.Material.Dirt));
        return true;
    }
    return false;

}