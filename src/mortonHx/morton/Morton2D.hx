package mortonHx.morton;
import mortonHx.ds.Vertex2i;
@:forward
abstract Point2DInt( Vertex2i<Int> ) from Vertex2i<Int> to Vertex2i<Int> {
    public inline function new( x: Int, y: Int ){
        this = new Vertex2i( x, y );
    }
    @:to
    public inline function toMordon2D(): Morton2D {
        return new Morton2D( this.x, this.y );
    }
    @:from
    public static inline function fromMordon2D( morton2d: Morton2D ):Point2DInt {
        return morton2d.decode();
    }
}
abstract Morton2D(Int) from Int to Int {
    // Standard multiplier for mapping -1.0...1.0 to Int16
    static inline var pack16: Float = 32767.0;
    public static function packFloatToInt16( v: Float ): Int {
        // Clamp to prevent overflow and round for precision
        if( v > 1. ){ 
            v = 1.;
        } else if( v < -1.0) {
            v = -1.0;
        }
        return Std.int( v * pack16 );
    }
    public inline function new( x: Int, y: Int ): Int {
        this = ( part1By1( y ) << 1 ) | part1By1( x );
    }
    inline function part1By1(v:Int):Int {
        v &= 0x0000ffff;
        v = (v ^ (v << 8)) & 0x00ff00ff;
        v = (v ^ (v << 4)) & 0x0f0f0f0f;
        v = (v ^ (v << 2)) & 0x33333333;
        v = (v ^ (v << 1)) & 0x55555555;
        return v;
    }
    public inline function decode(): Point2DInt {
        return new Point2DInt( compact1By1( this ), compact1By1( this >> 1 ) );
    }
    public inline function compact1By1( j: Int ): Int {
        j &= 0x55555555;//                  Isolate target bits (every 2nd bit)
        j = (j ^ (j >> 1)) & 0x33333333; // Pack bits into groups of 2
        j = (j ^ (j >> 2)) & 0x0f0f0f0f; // Pack bits into groups of 4
        j = (j ^ (j >> 4)) & 0x00ff00ff; // Pack bits into groups of 8
        j = (j ^ (j >> 8)) & 0x0000ffff; // Final alignment into a 16-bit integer
        return j;
    }

    // 2D bitmasks for 32-bit integers
    // x: 01010101... (even bits)
    static inline var maskX2d:Int = 0x55555555;
    // y: 10101010... (odd bits)
    // 
    static inline var maskY2d:Int = 0xAAAAAAAA;

    // Negated masks for borrow/carry protection
    static inline var maskNotX2d:Int = ~0x55555555;
    static inline var maskNotY2d:Int = ~0xAAAAAAAA;
    /**
     * Overloads the '+' operator for bitwise Morton addition.
     * Adds the coordinates interleaved, adding 'offset' to the 'base'.
     */
     @:op(A + B)
     public static inline function add(base:Morton2D, offset:Morton2D):Morton2D {
         return (
             ((base:Int) & maskX2d) + ((offset:Int) & maskX2d) |
             ((base:Int) & maskY2d) + ((offset:Int) & maskY2d)
             : Morton2D
         );
     }
     /**
     * Overloads the '-' operator for bitwise Morton subtraction.
     * Subtracts the coordinates interleaved in 'offset' from 'base'.
     */
     @:op(A - B)
     public static inline function subtract(base:Morton2D, offset:Morton2D):Morton2D {
         return (
             ((base:Int) | maskNotX2d) - ((offset:Int) & maskX2d) |
             ((base:Int) | maskNotY2d) - ((offset:Int) & maskY2d)
             : Morton2D
         );
     }
     @:op(A < B) static inline function lt(a:Morton2D, b:Morton2D):Bool return (a:Int) < (b:Int);
     @:op(A > B) static inline function gt(a:Morton2D, b:Morton2D):Bool return (a:Int) > (b:Int);
     @:op(A <= B) static inline function lte(a:Morton2D, b:Morton2D):Bool return (a:Int) <= (b:Int);
     @:op(A >= B) static inline function gte(a:Morton2D, b:Morton2D):Bool return (a:Int) >= (b:Int);
    
    // bounding xy code
    public static inline function minI( a: Int, b: Int ){
        return (a < b ? a : b);
    }
    public static inline function maxI( a: Int, b: Int ){
        return (a > b ? a : b);
    }
    public static inline function min3i( a: Int, b: Int, c: Int ){
        return minI(a, minI(b, c));
    }
    public static inline function max3i( a: Int, b: Int, c: Int ){
        return maxI(a, maxI(b, c));
    }
    public static function isInRange( pCode: Int, v1Code: Int, v2Code: Int, v3Code: Int ):Bool {
        // 1. Efficiently find the range of the triangle's Morton codes
        // Use your custom minI/maxI to avoid Math.min (which returns Floats)
        var minCode = Morton2D.min3i( v1Code, v2Code, v3Code );
        var maxCode = Morton2D.max3i( v1Code, v2Code, v3Code );
        // 2. Determine the bits that differ between the extreme vertices
        // A Morton range is a quadtree node if the shared prefix is the same
        var diff = minCode ^ maxCode;
        if (diff == 0) return pCode == v1Code;
        // 3. Find MSB without Math.log
        // This bit-smearing technique is faster than Math.log on all Haxe targets
        var v = diff;
        v |= v >> 1;
        v |= v >> 2;
        v |= v >> 4;
        v |= v >> 8;
        v |= v >> 16;
        // Create a mask that keeps the prefix shared by the triangle
        // (v + 1) is the next power of 2; we invert it for the mask
        var mask = ~(v);
        // 4. Check if pCode shares the same prefix as the triangle's cell
        return (pCode & mask) == (v1Code & mask);
    }

    // Checks if point 'p' is inside the box defined by 'min' and 'max' without de-interleaving
    public static inline function isInsideBox(p:Morton2D, min:Morton2D, max:Morton2D):Bool {
        // A point is in the box if its X and Y components are within bounds
        // We isolate components with the masks we built earlier
        var px = (p : Int) & maskX2d;
        var py = (p : Int) & maskY2d;
        return px >= ((min:Int) & maskX2d) && px <= ((max:Int) & maskX2d) &&
           py >= ((min:Int) & maskY2d) && py <= ((max:Int) & maskY2d);
    }

}