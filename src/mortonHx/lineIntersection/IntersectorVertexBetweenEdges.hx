package mortonHx.lineIntersection;
import mortonHx.ds.Vertex2i;
import mortonHx.ds.EdgeData;
enum abstract VertexState(Int) from Int to Int {
    var BELOW = -1;
    var ON    = 0;
    var ABOVE = 1;
}
/**
 * Vertex-to-edge intersector
 */
class IntersectorVertexBetweenEdges {
    var dxE:Float;
    var dyE:Float;
    var dxV:Float;
    var dyV:Float;
    public var v: Vertex2i<Int>;
    public var e: Edge<Int>;
    public static inline var EPSILON:Float = 1e-9;
    public function new(){}
    /**
     * Determines if Vertex2i VertexState
     */
    public function check( v: Vertex2i<Int>, e: Edge<Int> ): Int {
        this.v = v;
        this.e = e;
        // Relative deltas
        dxE = e.b.x - e.a.x;
        dyE = e.b.y - e.a.y;
        dxV = v.x   - e.a.x;
        dyV = v.y   - e.a.y;
        var bbox = yBox();                    // Bounding Box Check
        if (bbox != ON ) return bbox;
        var orient = orientation();           // Orientation Check
        if (orient != ON) return orient;
        return collinear();                   // Touch Check
    }
    inline
    function yBox():Int {
        var minY = e.a.y < e.b.y ? e.a.y : e.b.y;
        var maxY = e.a.y > e.b.y ? e.a.y : e.b.y;
        if( v.y > maxY ) return ABOVE;  
        if( v.y < minY ) return BELOW; 
        return ON; 
    }
    inline
    function orientation():Int {
        var area = ( dxE * dyV ) - ( dyE * dxV );
        if( area > EPSILON ) return ABOVE;  
        if( area < -EPSILON ) return BELOW; 
        return 0; // Effectively Collinear
    }
    inline
    function collinear():Int {
        // Check if the vertex is physically within the X-bounds of the segment
        var minX = e.a.x < e.b.x ? e.a.x : e.b.x;
        var maxX = e.a.x > e.b.x ? e.a.x : e.b.x;
        if( v.x >= minX && v.x <= maxX ) return ON; // Touching the edge (Bridge point found!)
        return ABOVE; // Consistent tie-breaker: if collinear but outside, treat as 'Above'
    }
}
