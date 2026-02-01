package mortonHx.ds;

import mortonHx.ds.Vertex2i;
import haxe.Int64;

#if cpp
@:struct 
#end
@:structInit
class Edge<T:Float> {
    public var ax:T; public var ay:T;
    public var bx:T; public var by:T;
    public function new(ax:T, ay:T, bx:T, by:T) {
        this.ax = ax; this.ay = ay;
        this.bx = bx; this.by = by;
    }
    public inline function toArray(): Array<T> {
        return [ax,ay,bx,by];
    }
    public inline function isA( p: Vertex2i<T> ): Bool {
        return ( p.x == ax && p.y == ay );
    }
    public inline function isB( p: Vertex2i<T> ): Bool {
        return ( p.x == bx && p.y == by );
    }
    public inline function isVertex( p: Vertex2i<T> ){
        return isA( p ) || isB( p );
    }
    public inline function isVertexXY( x: T, y: T ): Bool {
        return ( x == ax && y == ay ) || ( x == bx && y == by );
    }
    public var a( get, set ): Vertex2i<T>;
    inline function get_a(): Vertex2i<T> {
        return new Vertex2i<T>( ax, ay );
    }
    inline function set_a( v: Vertex2i<T> ): Vertex2i<T> {
        ax = v.x;
        ay = v.y;
        return v;
    }
    public var b( get, set ): Vertex2i<T>;
    inline function get_b(): Vertex2i<T> {
        return new Vertex2i<T>( bx, by );
    }
    inline function set_b( v: Vertex2i<T> ): Vertex2i<T> {
        bx = v.x;
        by = v.y;
        return v;
    }
}
@:forward
abstract EdgeData<T:Float>(Array<T>) from Array<T> to Array<T> {
    public inline function new(a:Null<Array<T>>){
        if( a == null ){
            a = new Array<T>();
        } else {
            #if debug
            if (a.length % 2 != 0) {
                throw "EdgeData error: Array length must be even to represent X,Y pairs.";
            }
            #end
        }
        this = a;
    }
    // Heavy approach translates to origin.
    public inline function translate( x: T, y: T ){
        var j = 0;
        for( p in iteratorPoints() ){
            setXY( j, p.x + x, p.y + y );
            j++;
        }
    }
    public inline function scaleFloat( s: Float ){
        var j = 0;
        for( p in iteratorPoints() ){
            //px(i):Float) *
            setXY( j, (cast ((cast p.x: Null<Float> )* s): T ), (cast ((cast p.y: Null<Float> )* s): T ) );
            j++;
        }
    }
    // --- Length Properties ---
    /** The number of points (vertices) in the array. */
    public var pointLength(get, never):Int;
    inline function get_pointLength() return this.length >> 1; // length/2

    /** The number of edges (n-1 for segments, or n for loops). */
    public var edgeLength(get, never):Int;
    inline function get_edgeLength() return pointLength > 0 ? pointLength - 1 : 0;

    // --- Point Methods ---
    public inline function pxi( pairIndex: Int ) return pairIndex << 1;
    public inline function pyi( pairIndex: Int ) return 1 + pxi( pairIndex );
    public inline function setXY( pairIndex: Int, x: T, y: T ){
        this[ pxi( pairIndex ) ] = x;
        this[ pyi( pairIndex ) ] = y;
    }
    public inline function getPoint( pairIndex: Int ):Vertex2i<T> {
        return new Vertex2i<T>( px( pairIndex ), py( pairIndex ) );
    }
    public inline function px( pairIndex: Int ):T return this[ pxi( pairIndex ) ];
    public inline function py( pairIndex: Int ):T return this[ pyi( pairIndex ) ];

    public inline function addPoint( x: T, y: T ):EdgeData<T> { 
        this.push(x); 
        this.push(y);
        return (this: EdgeData<T>);
    }
    // does not return as Vertex2i as that adds creation.
    public inline function removePoint( pairIndex: Int ){ 
        this.splice( pxi( pairIndex ), 2 ); 
    }
    @:op(A += B)
    public inline function addassign(rhs:EdgeData<T>):EdgeData<T> {
        #if (cpp || hl )
            //this.concat(rhs);
            for (i in 0...rhs.length) {
                this.push( rhs[ i ] );
            }
        #else
            var len = this.length;
            for( i in 0...rhs.length ){
                this[len] = rhs[i];
                len++;
            }
        #end
        return (this:EdgeData<T>);
    }
    // Insert EdgeData at the pairIndex.
    public inline function insertEdgeData( pairIndex:Int, values:EdgeData<T>):EdgeData<T> {
        var pos = pxi( pairIndex );
        for (i in 0...values.length) this.insert(pos + i, values[i]);
        return (this: EdgeData<T>);
    }

    // --- Edge Access (ax, ay, bx, by) ---
    public inline function axi( edgeIndex: Int ) return edgeIndex << 1;
    // only allow to set whole edge or whole point.
    public inline function setEdgeAB( edgeIndex: Int, ax: T, ay: T, bx: T, by: T ){
        var i = axi( edgeIndex );
        this[ i ] = ax;
        this[ i+1 ] = ay;
        this[ i+2 ] = bx;
        this[ i+3 ] = by;
    }
    public inline function getEdge( edgeIndex: Int ):Edge<T> {
        return { ax: ax( edgeIndex )
               , ay: ay( edgeIndex )
               , bx: bx( edgeIndex )
               , by: by( edgeIndex ) 
               };
    }
    public inline function ax( edgeIndex: Int ):T return this[ axi( edgeIndex ) ];
    public inline function ay( edgeIndex: Int ):T return this[ axi( edgeIndex ) + 1 ];
    public inline function bx( edgeIndex: Int ):T return this[ axi( edgeIndex ) + 2 ];
    public inline function by( edgeIndex: Int ):T return this[ axi( edgeIndex ) + 3 ];

    // --- Data Management ---
    
    public inline function insertEdge(edgeIndex: Int, e: Edge<T>):EdgeData<T> {
        var pos = axi( edgeIndex );
        var i = 0;
        this.insert(pos + i, e.ax);
        i++;
        this.insert(pos + i, e.ay);
        i++;
        this.insert(pos + i, e.bx );
        i++;
        this.insert(pos + i, e.by );
        return (this: EdgeData<T>);
    }
/*
    public inline function insertPointsAtEdge(edgeIdx:Int, values:Array<T>):EdgeData<T> {
        return insertPoints(pointAidxFromEdgeidx(edgeIdx), values);
  }
  */

    public inline function removePointAtEdge( edgeIndex: Int ): EdgeData<T> { 
        return this.splice( axi( edgeIndex ), 2 ); 
    }
    // Removes the Edge and return the Edge;
    public inline function removeEdge( edgeIdx: Int ): Edge<T> {
        var out = this.splice( axi( edgeIdx) ,4 );
        return new Edge<T>( out[0], out[1], out[2], out[3] ); 
    }

    // --- Iterator Support ---
    /** Allows looping: for (edge in myEdgeData) { ... } */
    public function iteratorEdge():Iterator<Edge<T>> {
        var i = 0;
        return {
            hasNext: () -> i < edgeLength,
            next: () -> getEdge(i++)
        };
    }
    /*
    public function iteratorPoints():Iterator<Vertex2i<T>> {
        var i = 0;
        // 1. Capture the abstract instance explicitly
        var self:EdgeData<T> = abstract; 
        // 2. Cache the length as a local variable to prevent re-evaluation
        var totalPoints = self.pointLength; 
    
        return {
            hasNext: function() {
                return i < totalPoints;
            },
            next: function() {
                // 3. Access then increment clearly
                var p = self.getPoint(i);
                i = i + 1;
                return p;
            }
        };
    }
    */
    public function iteratorPoints():Iterator<Vertex2i<T>> {
        var i = 0;
        var data = this; // Capture the underlying Array<T>
        var totalPoints = data.length >> 1;
    
        return {
            hasNext: () -> i < totalPoints,
            next: () -> {
                var px = data[i << 1];
                var py = data[(i << 1) + 1];
                i++;
                return new Vertex2i(px, py);
            }
        };
    }

    /**
     * Reverses the order of (x, y) pairs in-place.
     */
     public inline function reverseData():EdgeData<T> {
        var len = this.length;
        var half = (len >> 2); // only exchange half
        var a: Int;
        var b: Int;
        for (i in 0...half) {
            a = i << 1; // i*2
            b = len - 2 - a;
            swap(a, b);     // Swap X
            swap(a + 1, b + 1); // Swap Y
        }
        return (this: EdgeData<T> );
    }
    private inline function swap(a:Int, b:Int) {
        var temp = this[a];
        this[a] = this[b];
        this[b] = temp;
    }
    public inline function copy():EdgeData<T>{
        return ( this.copy(): EdgeData<T> );
    }
   // Note: 'inline' removed for methods containing loops
    public var minX( get, never ):T;
    public inline function get_minX():T {
        if (pointLength == 0) return (cast 0.0:T); // Handle empty data
        var m = px(0);
        for (i in 1...pointLength){
            var n = px(i);
            if (n < m) m = n;
        }
        return m;
    }
    public var maxX( get, never ): T;
    public inline function get_maxX():T {
        if (pointLength == 0) return (cast 0.0:T);
        var m = px(0);
        for (i in 1...pointLength){
            var n = px(i);
            if (n > m) m = n;
        }
        return m;
    }
    public var minY( get, never ): T;
    public inline function get_minY():T {
        if (pointLength == 0) return (cast 0.0: T);
        var m = py(0);
        for (i in 1...pointLength){
            var n = py(i);
            if (n < m) m = n;
        }
        return m;
    }
    public var maxY( get, never ): T;
    public inline function get_maxY():T {
        if (pointLength == 0) return (cast 0.0: T );
        var m = py(0);
        for (i in 1...pointLength){
            var n = py(i);
            if (n > m) m = n;
        }
        return m;
    }
   // Note: 'inline' removed for methods containing loops
   public var minXpoint( get, never ):Null<Vertex2i<T>>;
   public inline function get_minXpoint():Null<Vertex2i<T>> {
       if (pointLength == 0) return null; // Handle empty data
       var m = px(0);
       var point = new Vertex2i<T>( px(0), py(0) );
       for (i in 1...pointLength){
           var n = px(i);
           if (n < m){ 
                m = n;
                point = new Vertex2i<T>( px(i),py(i));
           }
       }
       return point;
   }
   public var maxXpoint( get, never ): Null<Vertex2i<T>>;
   public inline function get_maxXpoint():Null<Vertex2i<T>> {
       if (pointLength == 0) return null;
       var m = px(0);
       var point = new Vertex2i<T>( px(0), py(0) );
       for (i in 1...pointLength){
           var n = px(i);
           if (n > m){
                m = n;
                point = new Vertex2i<T>( px(i),py(i));
           }
        }
        return point;
   }
   public var minYpoint( get, never ): Null<Vertex2i<T>>;
   public inline function get_minYpoint():Null<Vertex2i<T>> {
       if (pointLength == 0) return null;
       var m = py(0);
       var point = new Vertex2i<T>( px(0), py(0) );
       for (i in 1...pointLength){
           var n = py(i);
           if (n < m) {
                m = n;
                point = new Vertex2i<T>( px(i),py(i));
           }
        }
        return point;
   }
   public var maxYpoint( get, never ): Null<Vertex2i<T>>;
   public inline function get_maxYpoint():Null<Vertex2i<T>> {
       if (pointLength == 0) return null;
       var m = py(0);
       var point = new Vertex2i<T>( px(0), py(0) );
       for (i in 1...pointLength){
           var n = py(i);
           if (n > m) {
                m = n;
                point = new Vertex2i<T>( px(i),py(i));
           }
       }
       return point;
   }
    // --- Bounding Box Index Methods (Non-inline, returns Int) ---

    public function minXindex():Int { // Returns Int, not T
        if (pointLength <= 1) return 0;
        var m = px(0);
        var idx = 0;
        for (i in 1...pointLength){
            var n = px(i);
            if( n < m ){
                m = n;
                idx = i;
            }
        }
        return idx;
    }
    
    // Remaining Index methods follow the same pattern...
    public function maxXindex():Int { 
        if (pointLength <= 1) return 0;
        var m = px(0);
        var idx = 0;
        for (i in 1...pointLength){
            var n = px(i);
            if (n > m){
                m = n;
                idx = i;
            }
        }
        return idx;
    }
    
    public function minYindex():Int { 
        if (pointLength <= 1) return 0;
        var m = py(0);
        var idx = 0;
        for (i in 1...pointLength){
            var n = py(i);
            if (n < m){
                m = n;
                idx = i;
            }
        }
        return idx;
    }
    
    public function maxYindex():Int { 
        if (pointLength <= 1) return 0;
        var m = py(0);
        var idx = 0;
        for (i in 1...pointLength){
            var n = py(i);
            if (n > m){
                m = n;
                idx = i;
            }
        }
        return idx;
    }
    public function replaceRange( pos: Int, len: Int, arr:Array<T> ): Void {
        // Removes exactly 'len' items. Array shrinks here.
        this.splice( pos, len ); 
        // Inserts all items from 'toInsert'. Array grows here.
        var i = arr.length;
        while (i-- > 0) {
            this.insert(pos, arr[i]);
        }
    }

    public inline static function makePointsInt(arr:Array<Float>, scale:Float = 1, dx:Float = 0, dy:Float = 0):EdgeData<Int> {
        var p = new Array<Int>();
        var len = arr.length;
        #if (cpp || hl || jvm || reflaxe_cs || reflaxe_java || flash )
        p.resize(len);
        #end
        var j = 0;
        var totalPoints = Std.int(len / 2);
        
        for (i in 0...totalPoints) {
            var base = i * 2;
            p[j] = Std.int(arr[base] * scale + scale * dx);
            j++;
            p[j] = Std.int(arr[base + 1] * scale + scale * dy);
            j++;
        }
        
        return new EdgeData<Int>(p);
    }
    /**
    * Returns an array of indices representing the sorted order of the input array.
    * @param arr The array of data (e.g., EdgeData)
    * @param f   A comparator function: returns > 0 if 'b' should come before 'a'
    */
    public static inline function getSortedMap<T>(arr:Array<T>, f:(a:T, b:T) -> Int):Array<Int> {
        var order = [for (i in 0...arr.length) i]; 
        // Sort the indices by looking up the values in the original array
        order.sort( ( idxA, idxB ) -> f( arr[ idxA ], arr[ idxB ] )  );
        return order;
    }
    // If your maxX values are floats, 
    // remember that the sort function expects an Int return. 
    // Use Math.round or a simple if (a > b) 1 else -1 if you switch to floating point coordinates.
            /*allHoles.sort((a, b)-> {
            if (b.maxX < a.maxX) return -1;
            if (b.maxX > a.maxX) return 1;
            return 0;
        });*/
    public static inline function sortMapDescendingX(arr:Array<EdgeData<Int>>):Array<Int> {
        return getSortedMap(arr, (a, b) -> b.maxX - a.maxX);
    }
    public static inline function sortMapAssendingX(arr:Array<EdgeData<Int>>):Array<Int> {
        return getSortedMap(arr, (a, b) -> a.maxX - b.maxX);
    }
    public static inline function sortMapDescendingY(arr:Array<EdgeData<Int>>):Array<Int> {
        return getSortedMap(arr, (a, b) -> b.maxY - a.maxY);
    }
    public static inline function sortMapAssendingY(arr:Array<EdgeData<Int>>):Array<Int> {
        return getSortedMap(arr, (a, b) -> a.maxY - b.maxY);
    }
    /*
    public function isCounterClockwise(): Bool {
        var area: Float = 0;
        for ( i in 0...pointLength ) {
            var j = (i + 1) % pointLength;
            area += ( 1.0 * px( i ) ) * py( j ) -  ( 1.0 * px( j ) ) * py( i );
        }
        return area > 0;
    }
    */
    public inline function isCounterClockwise(): Bool {
        return !isClockwise();
    }
    /**
 * Returns true if the path is clockwise.
 * For Y-down (standard screen coords), sum > 0 is Clockwise.
 * For Y-up (standard math coords), sum > 0 is Counter-Clockwise.
 */
/*public inline function isClockwise():Bool {
    var sum:Float = 0;
    var len = pointLength;
    if (len < 3) return false;

    for (i in 0...len) {
        var x1 = px(i);
        var y1 = py(i);
        // Use modulo to wrap the last point back to the first
        var next = (i + 1) % len;
        var x2 = px(next);
        var y2 = py(next);
        
        sum += (cast x2 - x1) * (cast y2 + y1);
    }
    return sum > 0;
}*/
/*
public inline function isClockwise():Bool {
    var area:Float = 0;
    var len = pointLength;
    if (len < 3) return false;

    for (i in 0...len) {
        var j = (i + 1) % len;
        // Shoelace: (x2 - x1) * (y2 + y1)
        area += (cast px(j) - px(i)) * (cast py(j) + py(i));
    }
    // In standard screen coords (Y-down), positive area is Clockwise.
    return area > 0;
}
*/
public inline function isClockwise():Bool {
    var area:Float = 0;
    var len = pointLength;
    if (len < 3) return false;

    // Use a small epsilon to ignore nearly degenerate segments
    // For integer coordinates, 1e-9 is a safe buffer
    var EPSILON:Float = 1e-9;

    for (i in 0...len) {
        var j = (i + 1) % len;
        // Shoelace term: (x_i * y_j) - (x_j * y_i)
        // casting to Float to handle large products
        area += (cast px(i):Float) * (cast py(j):Float) - (cast px(j):Float) * (cast py(i):Float);
    }

    // A positive area typically means Counter-Clockwise in standard math.
    // In screen coordinates (Y-down), positive usually means Clockwise.
    // If the area is within (-EPSILON, EPSILON), the winding is ambiguous.
    if (Math.abs(area) < EPSILON) return false; 
    
    return area < 0; // Return true for Clockwise (adjust sign based on your Y-axis)
}
}


