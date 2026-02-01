package mortonHx.ear;
import mortonHx.morton.Morton2D;
import mortonHx.pointInTriangle.PointHit;
import mortonHx.ds.SortableArray;
import mortonHx.ds.EdgeData;
import mortonHx.lineIntersection.IntersectorInt;


class EarCuttingMorton {
    var pointHit:    IHitInt;
    var points:      EdgeData<Int>;
    var sortableArr: SortableArray<Morton2D>;
    var edges:       EdgeData<Int>;
    public
    function new( points: EdgeData<Int>, pointHit: IHitInt = null ) {
        this.pointHit = (pointHit == null) ? new EdgeFunctionHitInt() : pointHit;
        if(!points.isCounterClockwise()){
            points.reverse();
        }
        edges = points;
        this.points = points;
        this.sortableArr = cast [ for ( p in points.iteratorPoints() ) new Morton2D( p.x, p.y ) ];
        this.sortableArr.assending();
    }
    public static
    function isCounterClockwise( p: Array<{ x: Int, y: Int }> ): Bool {
        var area: Float = 0;
        for ( i in 0...p.length ) {
            var j = (i + 1) % p.length;
            area += (cast(p[ i ].x, Float) * p[ j ].y) - (cast(p[ j ].x, Float) * p[ i ].y);
        }
        return area > 0;
    }
    public inline function setTriangle( ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int ) {
        pointHit.prepare( ax, ay, bx, by, cx, cy );
    }
    public function pointsInTriangle( ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int ): Bool {
        setTriangle( ax, ay, bx, by, cx, cy );
        var v1Code = new Morton2D( ax, ay );
        var v2Code = new Morton2D( bx, by );
        var v3Code = new Morton2D( cx, cy );
        var minCode = Morton2D.min3i( v1Code, v2Code, v3Code );
        var maxCode = Morton2D.max3i( v1Code, v2Code, v3Code );
        var start = sortableArr.findStartIndex( minCode );
        var end = sortableArr.findEndIndexFrom( maxCode, start );
        for( i in start...end ){
            var p = sortableArr[ i ]; 
            if( !isInRange( p, v1Code, minCode, maxCode ) ) continue;
            if( p == v1Code || p == v2Code || p == v3Code ) continue;
            var decode = p.decode();

            /*  Likely overkill not fixing problem but keep around incase //
            var px = decode.x;
            var py = decode.y;

            // ONLY skip if the point is exactly one of the three triangle corners.
            // This allows other bridge points with the same Morton code to be tested.
            if ((px == ax && py == ay) || 
                (px == bx && py == by) || 
                (px == cx && py == cy)) continue;
            //                                                            */

            if( pointHit.hitCheck( decode.x, decode.y ) ) return true;
        }
        return false;
    }

    private function createLinkedList(): EarNode {
        var list = [for ( p in points.iteratorPoints() ) {
            var n: EarNode = { 
                x: p.x, y: p.y, 
                m: (new Morton2D( p.x, p.y ):Int), 
                prev: null, next: null, isReflex: false 
            };
            n;
        }];
        for ( i in 0...list.length ) {
            list[ i ].next = list[ (i + 1) % list.length ];
            list[ i ].prev = list[ (i + list.length - 1) % list.length ];
        }
        return list[ 0 ];
    }
    
    public  function isValidEar( ear: EarNode ): Bool {
        if(ear.isReflex) return false;
        
        /**  Really heavy check made DO NOT USE in production // 
        var pathA = BaseIntersector.create( ear.prev.x, ear.prev.y, ear.x, ear.y, IntersectorFA  );
        var pathB = BaseIntersector.create( ear.x, ear.y, ear.next.x, ear.next.y, IntersectorFA  );
        var pathC = BaseIntersector.create( ear.prev.x, ear.prev.y, ear.next.x, ear.next.y, IntersectorFA  );
        var shell = edges;

        for( i in 0...shell.edgeLength ){
            var ax = shell.ax(i);
            var ay = shell.ay(i);
            var bx = shell.bx(i);
            var by = shell.by(i);
            var edge: Edge<Int> = shell.getEdge(i);
            // only check if vertex of triangle are not same as shell edge vertex
            if( !(   edge.isVertexXY( ear.prev.x,ear.prev.y ) 
                  || edge.isVertexXY( ear.x, ear.y )
                  || edge.isVertexXY( ear.next.x, ear.next.y )
                )
              ){
            if( pathA.check( ax, ay, bx, by ) != null ) return false;
            if( pathB.check( ax, ay, bx, by ) != null ) return false;
            if( pathC.check( ax, ay, bx, by ) != null ) return false;
                }
        }
        var pnx = ear.prev.x-ear.next.x;
        var pny = ear.prev.y-ear.next.y;
        if( pnx*pnx + pny*pny < 0.000001 ) return false;
        //                                               */

        return !pointsInTriangle( ear.prev.x, ear.prev.y, ear.x, ear.y, ear.next.x, ear.next.y );
    }
/*
    // old code check against below for speed and quality
    public function triangulate(): Array<Int> {
        var current = createLinkedList();
        var indices = [];
        var count = points.length;

        var node = current;
        do {
            node.isReflex = !isConvexFloat( node.prev.x, node.prev.y, node.x, node.y, node.next.x, node.next.y );
            node = node.next;
        } while (node != current);

        var stopNode = current;
        while (count > 3) {
            var prev = current.prev;
            var next = current.next;

            if(isValidEar( current )) {
                indices.push( prev.x ); indices.push( prev.y );
                indices.push( current.x ); indices.push( current.y );
                indices.push( next.x ); indices.push( next.y );

                prev.next = next;
                next.prev = prev;
                
                prev.isReflex = !isConvexFloat( prev.prev.x, prev.prev.y, prev.x, prev.y, prev.next.x, prev.next.y );
                next.isReflex = !isConvexFloat( next.prev.x, next.prev.y, next.x, next.y, next.next.x, next.next.y );

                current = next;
                stopNode = next; 
                count--;
            } else {
                current = next;
                if(current == stopNode) break; 
            }
        }
        
        indices.push( current.prev.x ); indices.push( current.prev.y );
        indices.push( current.x );      indices.push( current.y );
        indices.push( current.next.x ); indices.push( current.next.y );
        
        return indices;
    }
*/
    public
    function triangulate(): Array<Int> {
        var current = createLinkedList();
        var indices = [];
        var count = points.length;

        // 1. INITIAL PASS: Mark reflex nodes and detect zero-area bridge points
        var node = current;
        do {
            // Use a strict area check. If area is 0, it's a bridge or collinear; not a valid ear.
            node.isReflex = !isConvexFloat( node.prev.x, node.prev.y, node.x, node.y, node.next.x, node.next.y );
            node = node.next;
        } while( node != current );

        var stopNode = current;
        var iterations = 0;
        var maxIterations = count * 2; // Safety break for degenerate geometry

        while( count > 2 && iterations < maxIterations ){
            iterations++;
            var prev = current.prev;
            var next = current.next;

            // CRITICAL: A valid ear must have a POSITIVE area. 
            // If area is 0 (bridge), skipping it here prevents overdraw.
            if( isValidEar( current ) && getArea( prev, current, next ) > 0. ) {
                indices.push( prev.x ); indices.push( prev.y );
                indices.push( current.x ); indices.push( current.y );
                indices.push( next.x ); indices.push( next.y );

                // Remove node from linked list (Fast O(1))
                prev.next = next;
                next.prev = prev;

                // Only update neighbors
                prev.isReflex = !isConvexFloat( prev.prev.x, prev.prev.y, prev.x, prev.y, prev.next.x, prev.next.y );
                next.isReflex = !isConvexFloat( next.prev.x, next.prev.y, next.x, next.y, next.next.x, next.next.y );

                current = next;
                stopNode = next; 
                count--;
                continue;
            }

            current = next;
            if (current == stopNode) break; 
        }
    
        // Final triangle
        if( count == 3 ) {
            indices.push( current.prev.x ); indices.push( current.prev.y );
            indices.push( current.x );      indices.push( current.y );
            indices.push( current.next.x ); indices.push( current.next.y );
        }
        return indices;
    }

    // Add this helper for fast area check (cross product)
    private inline function getArea(a:EarNode, b:EarNode, c:EarNode):Float {
        return cast(b.x - a.x, Float) * (c.y - b.y) - cast(b.y - a.y, Float) * (c.x - b.x);
    }

    public static inline function isConvexFloat( ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int ): Bool {
        var val: Float = (cast(bx - ax, Float) * (cy - by)) - (cast(by - ay, Float) * (cx - bx));
        return val > 0.000000001; // Small epsilon to ignore near-collinear bridge points
        ///return val > 0;
    }
    /*public static inline function isConvexFloat( ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int ): Bool {
        // A zero or negative result means it's not a valid ear tip.
        // This immediately skips bridge-line degeneracies.
        return (cast(bx - ax, Float) * (cy - by)) - (cast(by - ay, Float) * (cx - bx)) > 0;
    }*/

    public static
    function isInRange( pCode:   Int
                      , v1Code:  Int
                      , minCode: Int, maxCode: Int ): Bool {
        var diff = minCode ^ maxCode;
        if( diff == 0 ) return pCode == v1Code;
        var v = diff;
        v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
        var mask = ~(v);
        return ( pCode & mask ) == ( v1Code & mask );
    }
}
