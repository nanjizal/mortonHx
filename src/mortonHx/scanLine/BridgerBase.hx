package mortonHx.scanLine;
import mortonHx.ds.EdgeData;
import mortonHx.ds.Vertex2i;
class BridgerBase {
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