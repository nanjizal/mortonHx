package mortonHx;


import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import mortonHx.morton.Morton3D; // Ensure this matches your file structure
@:dox(hide)
class Test3Danimate {
    static inline var STEP:Int = 10; // Size of the grid cells
    static inline var CUBE_SIZE:Int = 16; // Render an 8x8x8 Morton Curve

    /**
     * Projects 3D coordinates to 2D using simple Isometric Projection
     */
    static function project(x:Float, y:Float, z:Float):{x:Float, y:Float} {
        // Isometric math: 
        // x_2d = (x - z) * cos(30°)
        // y_2d = (x + z) * sin(30°) - y
        var posX = (x - z) * (STEP * 0.866); 
        var posY = (x + z) * (STEP * 0.5) - (y * STEP);
        return { x: posX, y: posY };
    }

    static var currentIdx:Int = 0; // Current animation progress
    static var totalPoints:Int = CUBE_SIZE * CUBE_SIZE * CUBE_SIZE;
    static var ctx:CanvasRenderingContext2D;
    static var canvas:CanvasElement;

    static function main() {
        canvas = Browser.document.createCanvasElement();
        canvas.width = 1000;
        canvas.height = 800;
        ctx = canvas.getContext2d();
        Browser.document.body.appendChild(canvas);

        // Start the animation loop
        Browser.window.requestAnimationFrame(update);
    }

    static function update(time:Float) {
        // 1. Clear the canvas for the new frame
        ctx.setTransform(1, 0, 0, 1, 0, 0); // Reset transform for clearing
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // 2. Setup the 3D view
        ctx.translate(canvas.width / 2, canvas.height / 4);
        drawFloorGrid(ctx, CUBE_SIZE);

        // 3. Draw the Morton curve up to currentIdx
        drawAnimatedMorton();

        // 4. Increment progress and loop
        if (currentIdx < totalPoints) {
            currentIdx += 10; // Adjust speed by changing the increment
            Browser.window.requestAnimationFrame(update);
        } else {
            // Optional: loop animation
            currentIdx = 0;
            Browser.window.requestAnimationFrame(update);
        }
    }

    static function drawAnimatedMorton() {
        ctx.beginPath();
        ctx.lineWidth = 2;
        ctx.strokeStyle = "#FF0000";

        var p0 = (cast(0, Morton3D)).decode();
        var screenP0 = project(p0.x, p0.y, p0.z);
        ctx.moveTo(screenP0.x, screenP0.y);
        var old = screenP0;
        for (i in 1...currentIdx) {
            var p = (cast(i, Morton3D)).decode();
            if (p.x < CUBE_SIZE && p.y < CUBE_SIZE && p.z < CUBE_SIZE) {
                var screenP = project(p.x, p.y, p.z);
                // Optional: Change color based on "depth" (Z) to help 3D effect
                ctx.stroke(); // Finalize current line
                ctx.beginPath();
                ctx.strokeStyle = 'rgb(${(p.z/CUBE_SIZE)*255}, ${(p.x/CUBE_SIZE)*255}, ${(p.y/CUBE_SIZE)*255})';
                ctx.moveTo(old.x, old.y);
               
                ctx.lineTo(screenP.x, screenP.y);
                old = screenP;
                ctx.lineTo(screenP.x, screenP.y);
            }
        }
        ctx.stroke();
    }

    static function drawFloorGrid(ctx:CanvasRenderingContext2D, size:Int) {
        ctx.beginPath();
        ctx.strokeStyle = "#CCCCCC";
        ctx.lineWidth = 1;
        for (i in 0...size + 1) {
            // Lines along X axis
            var pStart = project(0, 0, i);
            var pEnd = project(size, 0, i);
            ctx.moveTo(pStart.x, pStart.y);
            ctx.lineTo(pEnd.x, pEnd.y);

            // Lines along Z axis
            pStart = project(i, 0, 0);
            pEnd = project(i, 0, size);
            ctx.moveTo(pStart.x, pStart.y);
            ctx.lineTo(pEnd.x, pEnd.y);
        }
        ctx.stroke();
    }
}
