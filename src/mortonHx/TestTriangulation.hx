package mortonHx;

import mortonHx.pointInTriangle.PointHit;
import mortonHx.pointInTriangle.PointHit.BarycentricHitInt;
import mortonHx.pointInTriangle.PointHit.EdgeFunctionHitInt;
import mortonHx.pointInTriangle.PointHit.SameSideHitInt;
import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import mortonHx.ear.EarCutMorton;
import mortonHx.TestData;
import mortonHx.ds.EdgeData;
import mortonHx.scanLine.Bridger;
class TestTriangulation {
    static var test1 = [ 93., 195., 129., 92., 280., 81., 402., 134., 477., 70., 619., 61., 759., 97., 758., 247., 662., 347., 665., 230., 721., 140., 607., 117., 472., 171., 580., 178., 603., 257., 605., 377., 690., 404., 787., 328., 786., 480., 617., 510., 611., 439., 544., 400., 529., 291., 509., 218., 400., 358., 489., 402., 425., 479., 268., 464., 341., 338., 393., 427., 373., 284., 429., 197., 301., 150., 296., 245., 252., 384., 118., 360., 190., 272., 244., 165., 81., 259., 40., 216.];

    static function main() {
        var canvas: CanvasElement = Browser.document.createCanvasElement();
        canvas.width = 800;
        canvas.height = 600;
        var ctx: CanvasRenderingContext2D = canvas.getContext2d();
        Browser.document.body.appendChild( canvas );
        var points = EdgeData.makePointsInt( test1, 1 );
        //var edges = EarCuttingMorton.makeEdges( points );
        var holes  = [EdgeData.makePointsInt( hole1, 1 )
                    , EdgeData.makePointsInt( hole2, 1, 50 )
                    , EdgeData.makePointsInt( hole5, 1, 0, 0 )
                    , EdgeData.makePointsInt( hole5, 1, -30, 0 )
                    , EdgeData.makePointsInt( hole6, 1 )
                    , EdgeData.makePointsInt( hole7, 1 )
                    , EdgeData.makePointsInt( hole8, 1 )
                    , EdgeData.makePointsInt( hole9, 1, -10, -10 )
                    , EdgeData.makePointsInt( hole10, 1, 0, -40 )
                 ];
        // short cut for testing one hole
        //         holes = [holes[1]]; 
        //
        for( hole in holes ){
            if( hole.isCounterClockwise() ) {
                hole.reverseData();
                trace( 'reversing' );
            } else {
                trace('not reversing');
            }
        }
        trace( holes );
        trace('MERGING HOLES');
        var bridger_: EdgeData<Int> = Bridger.mergeHolesSouth( points, holes );
        //trace( bridger_ );
        //points = holes[0];
        var minX = points.minX;
        var minY = points.minY;
        points.translate( -minX, -minY );
        //points.scaleFloat( 3 );
        // extract points...
        /*
        var newPoints = new Array<{x: Int, y: Int }>();
        for( i in points.iteratorPoints() ){
            newPoints.push( { x: i.x, y: i.y } );
        }
        var first = points.getPoint(0);
        newPoints[newPoints.length] = { x: first.x, y: first.y } ;
        */
        //var i: Int = Std.int(edges.length-1);
        //newPoints[edges.length] = { x: edges[i].bx, y: edges[i].by };
        

        // 1. Run Triangulation
        // scale 1.0 means we use the data as-is (pixels)
        //var earcut = EarCuttingMorton.fromArrayFloat( test1, 1.0, new EdgeFunctionHitInt() );
        //var earcut = EarCuttingMorton.fromArrayFloat( test1, 1.0, new BarycentricHitInt() );
        //var earcut = EarCuttingMorton.fromArrayFloat( test1, 1.0, new SameSideHitInt() );
        //trace(newPoints);
        var earcut = new EarCuttingMorton( points, new EdgeFunctionHitInt() );
        //var earcut = EarCuttingMorton.fromArrayFloat( test1, 1.0, new EdgeFunctionHitInt() );
        var triangles = earcut.triangulate();
        var tri = new EdgeData(triangles);
        tri.translate( minX, minY );
        // 2. Draw    
        drawGrid( ctx, canvas.width, canvas.height, 40 );
       
        //tri.scaleFloat(0.3*0.3);
        drawTriangles( ctx, triangles );
        points.translate( minX, minY );
        //points.scaleFloat(0.3*0.3);
        drawOutline( ctx, ( points: Array<Int> ), 0xFF0000,2 );//hole3,hole4
        //for( hole in [hole1,hole2,hole5,hole6,hole7,hole8,hole9,hole10]) drawOutline( ctx, hole, 0x00ef00, 3 );
    }

    static function drawTriangles( ctx: CanvasRenderingContext2D, data: Array<Int> ) {
        ctx.strokeStyle = "rgba(0, 0, 255, 0.5)"; // Blue triangles
        ctx.lineWidth = 1;
        
        var i = 0;
        while (i < data.length) {
            ctx.beginPath();
            // A triangle is 3 points (6 indices)
            ctx.moveTo( data[ i ], data[ i + 1 ] );
            ctx.lineTo( data[ i + 2 ], data[ i + 3 ] );
            ctx.lineTo( data[ i + 4 ], data[ i + 5 ] );
            ctx.closePath();
            
            // Fill with a light color to see overlaps
            ctx.fillStyle = "rgba(100, 150, 255, 0.2)";
            ctx.fill();
            ctx.stroke();
            
            i += 6;
        }
    }

    static function drawOutline( ctx: CanvasRenderingContext2D, points: Array<Int>, color: Int, thick: Int ) {
        ctx.beginPath();
        ctx.strokeStyle = "#" + StringTools.hex(color, 6);//"#FF0000"; // Red outline
        ctx.lineWidth = thick;
        
        ctx.moveTo( points[ 0 ], points[ 1 ] );
        var i = 2;
        while (i < points.length) {
            ctx.lineTo( points[ i ], points[ i + 1 ] );
            i += 2;
        }
        ctx.closePath();
        ctx.stroke();
    }

    static function drawGrid( ctx: CanvasRenderingContext2D, width: Int, height: Int, step: Int ) {
        ctx.beginPath();
        ctx.strokeStyle = "#EEEEEE";
        for ( x in 0...Std.int(width / step) + 1 ) {
            ctx.moveTo( x * step, 0 );
            ctx.lineTo( x * step, height );
        }
        for ( y in 0...Std.int(height / step) + 1 ) {
            ctx.moveTo( 0, y * step );
            ctx.lineTo( width, y * step );
        }
        ctx.stroke();
    }
}
