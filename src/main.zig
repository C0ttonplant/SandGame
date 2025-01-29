// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl = @import("raylib");
const p = @import("./particle.zig");
const sc = @import("./screen.zig");
const r = @import("./random.zig");
const sav = @import("./save.zig");
const lod = @import("./load.zig");
const ui = @import("ui.zig");

pub var camera: rl.Camera2D = undefined;
pub var mousex: i32 = 0;
pub var mousey: i32 = 0;

pub var enumI: u43 = 0;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "sand game");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    camera.offset = rl.Vector2.init(@as(f32, @floatFromInt(rl.getScreenWidth())) / 2, @as(f32, @floatFromInt(rl.getScreenHeight())) / 2);
    camera.rotation = 0;
    camera.target = rl.Vector2.init(0, 0);
    camera.zoom = 1;

    sc.init();
    

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        sc.checkForScreenResize();
        sc.updateMousePos();
        rl.hideCursor();
        
        if(rl.isKeyReleased(rl.KeyboardKey.key_s))
        {
            try sav.save(sav.SaveModes.Lossless, "large-testt.sand");
        }
        if(rl.isKeyReleased(rl.KeyboardKey.key_l))
        {
            try lod.load("large-testt.sand");
            
        }
        

        // index = @mod(r.randomNumberi32(), sc.worldWidth);
        // sc.setParticleAt(index, 0, p.Particle.init(p.Material.Water));
            
        

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        sc.proccesAll();
        sc.updateInput();

        if(rl.isKeyDown(rl.KeyboardKey.key_c))
        {
            sc.circleBrush();   
        }
        if(rl.isKeyReleased(rl.KeyboardKey.key_e))
        {
            sc.explosion(40);   
        }

        sc.updateTexture();

        rl.beginMode2D(camera);
        sc.drawTexture();
        rl.drawPixel(mousex - @divFloor(sc.worldWidth, 2),  mousey - @divFloor(sc.worldHeight, 2), @as(p.Material, @enumFromInt(enumI)).getMatColor());
        rl.endMode2D();

        ui.draw();

        rl.drawCircleV(rl.getMousePosition(), 2, rl.Color.white);

        rl.drawFPS(15, 35);
        //----------------------------------------------------------------------------------
    }
}
