package mortonHx.scanLine;
import mortonHx.ds.EdgeData;
import mortonHx.lineIntersection.IntersectorInt;
import mortonHx.ds.Vertex2i;
import mortonHx.qualityTriangle.GoodTriangle;
@:structInit
@:nativeGen
class BridgeResult {
    public var point: Vertex2i<Int>;
    public var edgeIdx: Int;
    public var distanceSq: Float;
    public inline function new(point: Vertex2i<Int>, edgeIdx: Int, distanceSq: Float ) {
        this.point = point;
        this.edgeIdx = edgeIdx;
        this.distanceSq = distanceSq;
    }
}
@:structInit
@:nativeGen
class BridgeData {
    public var begin:        Int;
    public var originalEdge: Edge<Int>;
    public var holeBridge:   EdgeData<Int>;
    public var distanceSq:   Float;
    public 
    function new( begin:  Int
                , originalEdge: Edge<Int>
                , holeBridge:   EdgeData<Int>
                , distanceSq:   Float
                ){
        this.begin        = begin;
        this.originalEdge = originalEdge;
        this.holeBridge   = holeBridge;
        this.distanceSq   = distanceSq;
    }
    public inline 
    function addBridge( shell: EdgeData<Int> ){
        shell.replaceRange( begin, 4, holeBridge );
    }
    public inline
    function removeBridge( shell: EdgeData<Int> ){
        shell.replaceRange( begin, holeBridge.length, originalEdge.toArray() );
    }
}
@:structInit
@:nativeGen
class TriangleCheck {
    public var visibleA: Bool;
    public var visibleB: Bool;
    public var triangleUnitMerit: Float;
    public var distA: Float;
    public var distB: Float;
    public 
    function new ( visibleA: Bool = false
                 , visibleB: Bool = false
                 , triangleUnitMerit:    Float = 0
                 , distA:    Float = -1
                 , distB:    Float = -1 ){
        this.visibleA = visibleA;
        this.visibleB = visibleB;
        this.triangleUnitMerit    = triangleUnitMerit;
        this.distA    = ( distA == -1 )? Math.POSITIVE_INFINITY: distA;
        this.distB    = ( distB == -1 )? Math.POSITIVE_INFINITY: distA;
    }
}
/**
 * Adds a holes inside a shape by creating a bridge  
 * from the left hand side of the shape ( shell ).   
 * Progressive Hole-to-Shell Merger.  
 * Logic:  
 * 1. Sort Holes by Max X (Right-to-Left).  
 * 2. Connect rightmost hole point to shell.  
 * 3. Add Hole edges + Bridge edges to the Shell list.  
 * 4. Repeat for next hole.
 * 
 */
class Bridger {
    public static
    function triangleViable(  holePt:     Vertex2i<Int>
                            , edge:        Edge<Int>
                            , holes:       Array<EdgeData<Int>>
                            , shell:       EdgeData<Int>
                            , intersector: Null<Class<Intersector>> = null ): TriangleCheck {
        var pathA = BaseIntersector.create( edge.ax, edge.ay, holePt.x, holePt.y,  intersector );
        var pathB = BaseIntersector.create( edge.bx, edge.by, holePt.x, holePt.y,  intersector );
        var visibleA = true;
        var visibleB = true;
        for( i in 0...shell.edgeLength ){
            var ax = shell.ax(i);
            var ay = shell.ay(i);
            var bx = shell.bx(i);
            var by = shell.by(i);
            if( edge.isVertexXY( ax, ay ) || edge.isVertexXY( bx, by ) ) continue;
            if( visibleA ) if( pathA.check( ax, ay, bx, by ) != null )   visibleA = false;
            if( visibleB ) if( pathB.check( ax, ay, bx, by ) != null )   visibleB = false;
            var notVisible = ( !visibleA ) && ( !visibleB );
            if( notVisible ) return new TriangleCheck();
        }
        for( hole in holes ){
            for( i in 0...hole.edgeLength ){
                var ax = hole.ax(i);
                var ay = hole.ay(i);
                var bx = hole.bx(i);
                var by = hole.by(i);
                if( ax == holePt.x || ay == holePt.y ) continue;
                if( bx == holePt.x || by == holePt.y ) continue;
                if( edge.isVertexXY( ax, ay ) || edge.isVertexXY( bx, by ) ) continue;
                if( visibleA ) if( pathA.check( ax, ay, bx, by ) != null )   visibleA = false;
                if( visibleB ) if( pathB.check( ax, ay, bx, by ) != null )   visibleB = false;
                var notVisible = ( !visibleA ) && ( !visibleB );
                if( notVisible ) return new TriangleCheck();
            }
        }
        var trianglePossible = visibleA && visibleB;
        var triangleCheck = new TriangleCheck( visibleA, visibleB );
        if( trianglePossible ){
            triangleCheck.triangleUnitMerit = GoodTriangle.triangleUnitMerit( holePt, edge.a, edge.b );
            triangleCheck.distA = pathA.distanceSq();
            triangleCheck.distB = pathB.distanceSq();
        }
        return triangleCheck;
    }
    /**
     * Connects and merges holes into a shell progressively to the East of the Shell.
     */
    public static function mergeHolesEast(  shellEdges:         EdgeData<Int>
                                         ,  allHoles:           Array<EdgeData<Int>>
                                         ,  triangleUnitMerit : Float = 0.1
                                         ,  intersector:        Null<Class<Intersector>> = null 
                                         ): Null<EdgeData<Int>> {
        // East
        var bridgeDatas = new Array<Null<BridgeData>>();
        for( i in 0...allHoles.length ) bridgeDatas[i] = null;
        // 1. Sort holes so we process the one closest to the right side of the shell first
        var order: Array<Int> = EdgeData.sortMapDescendingX( allHoles );
        var hole = allHoles[ order[ 0 ] ];
        var e = new EdgeData<Int>( [] );
        var lastBegin = -1;
        for( i in 0...order.length ) {
            var hole  = allHoles[ order[ i ] ];
            var hole_i = hole.maxXindex();
            var holePt: Vertex2i<Int> = new Vertex2i<Int>( hole.px( hole_i ), hole.py( hole_i ) );
            var result = findBestTargetX( holePt, shellEdges, intersector );
            if(result != null) {
                var begin                         = shellEdges.axi(result.edgeIdx);
                var targetEdge: Edge<Int>         = shellEdges.getEdge( result.edgeIdx );
                var tri:        TriangleCheck     = triangleViable( holePt, targetEdge, allHoles, shellEdges, intersector );
                var bridgePoint = if( tri.triangleUnitMerit > triangleUnitMerit ) {
                    if( tri.distA < tri.distB ){
                        targetEdge.a;
                    } else {
                        targetEdge.b;
                    }
                } else {
                    result.point;
                }
                var e = connectHole(
                    shellEdges, 
                    hole, 
                    hole_i, 
                    bridgePoint, 
                    result.edgeIdx,
                );
                var b: BridgeData = new BridgeData(
                     begin
                    ,targetEdge
                    ,e
                    ,result.distanceSq
                );
                bridgeDatas[ order[ i ] ]  = b;
                b.addBridge( shellEdges );
            }
        }
        // remove bridges in order of creation
        /*
        var j = order.length-1;
        for( i in 0...order.length ) {
            bridgeDatas[order[j]].removeBridge(shellEdges);
            j--;
        }*/
        return shellEdges;
    }
    /**
     * Connects and merges holes into a shell progressively to the North of the Shell.
     */
    public static function mergeHolesNorth(  shellEdges:        EdgeData<Int>
                                          ,  allHoles:          Array<EdgeData<Int>>
                                          ,  triangleUnitMerit: Float = 0.1
                                          ,  intersector:       Null<Class<Intersector>> = null 
                                          ): Null<EdgeData<Int>> {
        // North
        var bridgeDatas = new Array<Null<BridgeData>>();
        for( i in 0...allHoles.length ) bridgeDatas[i] = null;
        // 1. Sort holes so we process the one closest to the top of the shell first
        var order: Array<Int> = EdgeData.sortMapDescendingY( allHoles );
        var hole = allHoles[ order[ 0 ] ];
        var e = new EdgeData<Int>( [] );
        var lastBegin = -1;
        for( i in 0...order.length ) {
            var hole  = allHoles[ order[ i ] ];
            var hole_i = hole.minYindex();
            var holePt: Vertex2i<Int> = new Vertex2i<Int>( hole.px( hole_i ), hole.py( hole_i ) );
            var result = findBestTargetnegY( holePt, shellEdges, intersector );
            if(result != null) {
                var begin                         = shellEdges.axi(result.edgeIdx);
                var targetEdge: Edge<Int>         = shellEdges.getEdge( result.edgeIdx );
                var tri:        TriangleCheck     = triangleViable( holePt, targetEdge, allHoles, shellEdges, intersector );
                var bridgePoint = if( tri.triangleUnitMerit > triangleUnitMerit ) {
                    if( tri.distA < tri.distB ){
                        targetEdge.a;
                    } else {
                        targetEdge.b;
                    }
                } else {
                    result.point;
                }
                var e = connectHole(
                    shellEdges, 
                    hole, 
                    hole_i, 
                    bridgePoint, 
                    result.edgeIdx,
                );
                var b: BridgeData = new BridgeData(
                     begin
                    ,targetEdge
                    ,e
                    ,result.distanceSq
                );
                bridgeDatas[ order[ i ] ]  = b;
                b.addBridge( shellEdges );
            }
        }
        // remove bridges in order of creation
        /*
        var j = order.length-1;
        for( i in 0...order.length ) {
            bridgeDatas[order[j]].removeBridge(shellEdges);
            j--;
        }*/
        return shellEdges;
    }
    /**
     * Connects and merges holes into a shell progressively to the West of the Shell.
     */
    public static function mergeHolesWest(  shellEdges:         EdgeData<Int>
                                         ,  allHoles:           Array<EdgeData<Int>>
                                         ,  triangleUnitMerit:  Float = 0.1
                                         ,  intersector:        Null<Class<Intersector>> = null 
                                         ): Null<EdgeData<Int>> {
        // North
        var bridgeDatas = new Array<Null<BridgeData>>();
        for( i in 0...allHoles.length ) bridgeDatas[i] = null;
        // 1. Sort holes so we process the one closest to the left of the shell first
        var order: Array<Int> = EdgeData.sortMapAssendingX( allHoles );
        var hole = allHoles[ order[ 0 ] ];
        var e = new EdgeData<Int>( [] );
        var lastBegin = -1;
        for( i in 0...order.length ) {
            var hole  = allHoles[ order[ i ] ];
            var hole_i = hole.minXindex();
            var holePt: Vertex2i<Int> = new Vertex2i<Int>( hole.px( hole_i ), hole.py( hole_i ) );
            var result = findBestTargetnegX( holePt, shellEdges, intersector );
            if(result != null) {
                var begin                         = shellEdges.axi(result.edgeIdx);
                var targetEdge: Edge<Int>         = shellEdges.getEdge( result.edgeIdx );
                var tri:        TriangleCheck     = triangleViable( holePt, targetEdge, allHoles, shellEdges, intersector );
                var bridgePoint = if( tri.triangleUnitMerit > triangleUnitMerit ) {
                    if( tri.distA < tri.distB ){
                        targetEdge.a;
                    } else {
                        targetEdge.b;
                    }
                } else {
                    result.point;
                }
                var e = connectHole(
                    shellEdges, 
                    hole, 
                    hole_i, 
                    bridgePoint, 
                    result.edgeIdx,
                );
                var b: BridgeData = new BridgeData(
                     begin
                    ,targetEdge
                    ,e
                    ,result.distanceSq
                );
                bridgeDatas[ order[ i ] ]  = b;
                b.addBridge( shellEdges );
            }
        }
        // remove bridges in order of creation
        /*
        var j = order.length-1;
        for( i in 0...order.length ) {
            bridgeDatas[order[j]].removeBridge(shellEdges);
            j--;
        }*/
        return shellEdges;
    }
        /**
     * Connects and merges holes into a shell progressively to the South of the Shell.
     */
    public static function mergeHolesSouth(  shellEdges:        EdgeData<Int>
                                          ,  allHoles:           Array<EdgeData<Int>>
                                          ,  triangleUnitMerit:  Float = 0.1
                                          ,  intersector:        Null<Class<Intersector>> = null 
                                          ): Null<EdgeData<Int>> {
        // North
        var bridgeDatas = new Array<Null<BridgeData>>();
        for( i in 0...allHoles.length ) bridgeDatas[i] = null;
        // 1. Sort holes so we process the one closest to the bottom of the shell first
        var order: Array<Int> = EdgeData.sortMapAssendingY( allHoles );
        var hole = allHoles[ order[ 0 ] ];
        var e = new EdgeData<Int>( [] );
        var lastBegin = -1;
        for( i in 0...order.length ) {
            var hole  = allHoles[ order[ i ] ];
            var hole_i = hole.maxYindex();
            var holePt: Vertex2i<Int> = new Vertex2i<Int>( hole.px( hole_i ), hole.py( hole_i ) );
            var result = findBestTargetY( holePt, shellEdges, intersector );
            if(result != null) {
                var begin                         = shellEdges.axi(result.edgeIdx);
                var targetEdge: Edge<Int>         = shellEdges.getEdge( result.edgeIdx );
                var tri:        TriangleCheck     = triangleViable( holePt, targetEdge, allHoles, shellEdges, intersector );
                var bridgePoint = if( tri.triangleUnitMerit > 0.1 ) {
                    if( tri.distA < tri.distB ){
                        targetEdge.a;
                    } else {
                        targetEdge.b;
                    }
                } else {
                    result.point;
                }
                var e = connectHole(
                    shellEdges, 
                    hole, 
                    hole_i, 
                    bridgePoint, 
                    result.edgeIdx,
                );
                var b: BridgeData = new BridgeData(
                     begin
                    ,targetEdge
                    ,e
                    ,result.distanceSq
                );
                bridgeDatas[ order[ i ] ]  = b;
                b.addBridge( shellEdges );
            }
        }
        // remove bridges in order of creation
        /*
        var j = order.length-1;
        for( i in 0...order.length ) {
            bridgeDatas[order[j]].removeBridge(shellEdges);
            j--;
        }*/
        return shellEdges;
    }
   /**
    * Finds the nearest shell edge and returns a BridgeResult struct.
    */
    private static function findBestTargetX( holePt: Vertex2i<Int>
                                           , shell: EdgeData<Int>
                                           , intersector: Null<Class<Intersector>> = null
                                          ): Null<BridgeResult> {
        var x: Int = holePt.x;
        var scanner = BaseIntersector.create( x, holePt.y, 999999, holePt.y, intersector );
        var bestPoint: Vertex2i<Int> = null;
        var bestIdx: Int = -1;
        var minDist: Float = Math.POSITIVE_INFINITY;
        for (i in 0...shell.edgeLength) {
            var hit = scanner.check( shell.ax(i), shell.ay(i), shell.bx(i), shell.by(i));
            if( hit != null ){
                var d: Float = hit.x - holePt.x;
                if( d < minDist ){
                    minDist = d;
                    bestPoint = hit;
                    bestIdx = i;
                }
            }
        }
        if (bestPoint == null) return null;
        return { point: bestPoint, edgeIdx: bestIdx, distanceSq: minDist*minDist };
    }
   private static function findBestTargetnegX( holePt: Vertex2i<Int>
                                             , shell: EdgeData<Int>
                                             , intersector: Null<Class<Intersector>> = null
                                             ): Null<BridgeResult> {
        var x: Int = holePt.x;
        var scanner = BaseIntersector.create(x, holePt.y, 0, holePt.y, intersector );
        var bestPoint: Vertex2i<Int> = null;
        var bestIdx: Int = -1;
        var minDist: Float = Math.POSITIVE_INFINITY;
        for (i in 0...shell.edgeLength) {
            var hit = scanner.check( shell.ax(i), shell.ay(i), shell.bx(i), shell.by(i));
            if( hit != null ){
                var d: Float = holePt.x - hit.x;
                if( d < minDist ){
                    minDist = d;
                    bestPoint = hit;
                    bestIdx = i;
                }
            }
        }
        if (bestPoint == null) return null;
        return { point: bestPoint, edgeIdx: bestIdx, distanceSq: minDist*minDist };
    }
    private static function findBestTargetY( holePt: Vertex2i<Int>
                                       , shell: EdgeData<Int>
                                       , intersector: Null<Class<Intersector>> = null
                                       ): Null<BridgeResult> {
        var y: Int = holePt.y;
        var scanner = BaseIntersector.create(holePt.x, y, holePt.x, 999999, intersector );
        var bestPoint: Vertex2i<Int> = null;
        var bestIdx: Int = -1;
        var minDist: Float = Math.POSITIVE_INFINITY;
        for (i in 0...shell.edgeLength) {
            var hit = scanner.check(shell.ax(i), shell.ay(i), shell.bx(i), shell.by(i));
            if (hit != null) {
                var d: Float = hit.y - holePt.y;
                if (d < minDist) {
                    minDist = d;
                    bestPoint = hit;
                    bestIdx = i;
                }
            }
        }
        if (bestPoint == null) return null;
        return { point: bestPoint, edgeIdx: bestIdx, distanceSq: minDist*minDist };
    }
    private static function findBestTargetnegY( holePt:      Vertex2i<Int>
                                              , shell:       EdgeData<Int>
                                              , intersector: Null<Class<Intersector>> = null
                                              ): Null<BridgeResult> {
        var y: Int = holePt.y;
        var scanner = BaseIntersector.create( holePt.x, y, holePt.x, 0, intersector );
        var bestPoint: Vertex2i<Int> = null;
        var bestIdx: Int = -1;
        var minDist: Float = Math.POSITIVE_INFINITY;
        for (i in 0...shell.edgeLength) {
            var hit = scanner.check(shell.ax(i), shell.ay(i), shell.bx(i), shell.by(i));
            if (hit != null) {
                var d: Float = holePt.y - hit.y;
                if (d < minDist) {
                    minDist = d;
                    bestPoint = hit;
                    bestIdx = i;
                }
            }
        }
        if (bestPoint == null) return null;
        return { point: bestPoint, edgeIdx: bestIdx, distanceSq: minDist*minDist };
    }
    /**
     * pushHole Circular walk  
     * @param tempEdgeData adding hole to temp EdgeData
     * @param holePtIdx    hole index
     * @param hole         hole as an EdgeData 
     * @return EdgeData<Int>
     */
    public static function pushHole( tempEdgeData: EdgeData<Int>
                                   , holePtIdx:    Int
                                   , hole:         EdgeData<Int> ): EdgeData<Int> {
        var e       = tempEdgeData;
        var holePt  = hole.getPoint( holePtIdx );
        var holeLen = hole.pointLength;
        e.addPoint( holePt.x, holePt.y );
        var lastX = holePt.x;
        var lastY = holePt.y;
        for (i in 1...holeLen ) { // Start from 1 because holePt is already added
            var id = ( holePtIdx + i ) % holeLen;
            var hx = hole.px( id ); var hy = hole.py( id );
            if (hx == lastX && hy == lastY) continue;
            e.addPoint(hx, hy);
            lastX = hx; lastY = hy;
        }
        if (lastX != holePt.x || lastY != holePt.y) e.addPoint(holePt.x, holePt.y);
        return tempEdgeData;
    } 
    /**
    * Splices a hole into the shell's edge sequence.
    * This creates a manifold polygon suitable for Ear Clipping.
    * 
    * @param shell         The current list of shell edges
    * @param hole          The points defining the hole
    * @param holePtIdx     The index of the rightmost vertex in the hole
    * @param bridgeTarget  The integer point on the shell edge (possibly snapped)
    * @param edgeIdx       The index of the shell edge being split
    */
    public static function connectHole( shell:          EdgeData<Int>,
                                        hole:           EdgeData<Int>, 
                                        holePtIdx:      Int, 
                                        bridgeTarget:   Vertex2i<Int>, 
                                        edgeIdx:        Int
                                    ):  EdgeData<Int> {
        var edgeAB = shell.getEdge( edgeIdx );
        var e = new EdgeData<Int>( [ ] );
        e.addPoint( edgeAB.ax, edgeAB.ay );
        var exitShell = edgeAB.a;
        if( !edgeAB.isA( bridgeTarget )){
            e.addPoint(bridgeTarget.x, bridgeTarget.y);
            exitShell = bridgeTarget;
        }
        pushHole( e, holePtIdx, hole );
        e.addPoint( exitShell.x, exitShell.y );
        if( !edgeAB.isB( exitShell ) ) e.addPoint( edgeAB.bx, edgeAB.by );
        return e;
    }



/**
 * Uses the 2D Cross Product to check if a vertex is convex.
 * a: previous vertex, b: current vertex (the one we want to snap to), c: next vertex.
 */
 public static inline function isConvex(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Bool {
    // Vector 1: a -> b
    var v1x = bx - ax;
    var v1y = by - ay;
    // Vector 2: b -> c
    var v2x = cx - bx;
    var v2y = cy - by;

    // 2D Cross Product: (x1 * y2) - (y1 * x2)
    // If > 0, it's a right turn (convex in CW winding)
    // If < 0, it's a left turn (concave/reflex in CW winding)
    // If 0, the points are collinear.
    return (v1x * v2y - v1y * v2x) >= 0;
}
}