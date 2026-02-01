package mortonHx;
import mortonHx.morton.Morton2D;
import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
@:dox(hide)
class Test {
    static function main() {
        trace('testing MortonHx');
        var canvas:CanvasElement =  Browser.document.createCanvasElement();
        canvas.width = 800;
        canvas.height = 600;
        var ctx:CanvasRenderingContext2D = canvas.getContext2d();
        Browser.document.body.appendChild(canvas);
        drawGrid(ctx, canvas.width, canvas.height, 40);
        drawMordon(ctx, canvas.width, canvas.height, 40);
    }
    static function drawMordon(ctx:CanvasRenderingContext2D, width:Int, height:Int, step:Int){
        var wid = Math.ceil( width/40 );
        var hi  = Math.ceil( height/40 );
        ctx.beginPath();
        ctx.strokeStyle = "#FF0000";
        var p = (cast(0,Morton2D)).decode();
        ctx.moveTo( 40*p.x+2, 40*p.y+2 );
        var tot = Std.int( wid*hi*40 );
        for( i in 1...tot ){
            var p = (cast(i,Morton2D)).decode();
            if( p.x < wid && p.y < hi ) ctx.lineTo( 40*p.x+2, 40*p.y+2 );
        }
        ctx.stroke();
    }
    static function drawGrid(ctx:CanvasRenderingContext2D, width:Int, height:Int, step:Int) {
        ctx.beginPath();
        ctx.strokeStyle = "#CCCCCC";
        
        // Draw vertical lines
        var x = 0;
        while (x <= width) {
            ctx.moveTo(x, 0);
            ctx.lineTo(x, height);
            x += step;
        }
        
        // Draw horizontal lines
        var y = 0;
        while (y <= height) {
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            y += step;
        }
        
        ctx.stroke();
    }
}
