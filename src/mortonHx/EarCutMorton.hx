package mortonHx;
import mortonHx.Morton2D;
import mortonHx.PointHit;
import mortonHx.SortableArray;
class EarCuttingMorton {
    var pointHit: IHitInt;
    var points: Array<{ x: Int, y: Int }>;
    var sortableArr: SortableArray<Morton2D>;

    public inline static function fromArrayFloat( arr: Array<Float>, scale: Float = 32767/800, pointHit: IHitInt = null ) {
        var p = new Array<{ x: Int, y: Int }>();
        for ( i in 0...Std.int(arr.length / 2) ) {
            p[ i ] = { x: Std.int(arr[ i * 2 ] * scale), y: Std.int(arr[ i * 2 + 1 ] * scale) };
        }
        return new EarCuttingMorton( p, pointHit );
    }

    public function new( points: Array<{ x: Int, y: Int }>, pointHit: IHitInt = null ) {
        this.pointHit = (pointHit == null) ? new EdgeFunctionHitInt() : pointHit;
        
        if(!isCounterClockwise( points )) {
            points.reverse();
        }
        
        this.points = points;
        this.sortableArr = cast [for ( p in points ) new Morton2D( p.x, p.y )];
        this.sortableArr.assending(); 
    }
    
    static function isCounterClockwise( p: Array<{ x: Int, y: Int }> ): Bool {
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
        
        for ( i in start...end ) {
            var p = sortableArr[ i ];
            
            if(!isInRange( p, v1Code, minCode, maxCode )) continue;
            if( p == v1Code || p == v2Code || p == v3Code ) continue;
            
            var decode = p.decode();
            if(pointHit.hitCheck( decode.x, decode.y )) return true;
        }
        return false;
    }

    private function createLinkedList(): EarNode {
        var list = [for ( p in points ) {
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
    
    public inline function isValidEar( ear: EarNode ): Bool {
        if(ear.isReflex) return false;
        return !pointsInTriangle( ear.prev.x, ear.prev.y, ear.x, ear.y, ear.next.x, ear.next.y );
    }

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

    public static inline function isConvexFloat( ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int ): Bool {
        var val: Float = (cast(bx - ax, Float) * (cy - by)) - (cast(by - ay, Float) * (cx - bx));
        return val > 0;
    }

    public static function isInRange( pCode: Int, v1Code: Int, minCode: Int, maxCode: Int ): Bool {
        var diff = minCode ^ maxCode;
        if(diff == 0) return pCode == v1Code;
        var v = diff;
        v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
        var mask = ~(v);
        return (pCode & mask) == (v1Code & mask);
    }
}
