package mortonHx.ds;

/**
 * XYPack: A 32-bit packed 2D coordinate for high-performance sorting.
 * High 16 bits: X (Primary Sort)
 * Low 16 bits:  Y (Secondary Sort)
 * Range: 0 to 65535 for each axis.
 */
abstract XYpack(Int) from Int to Int {
    
    public static inline final MAX:Int = 0xFFFF;

    public inline function new(ix:Int, iy:Int) {
        this = ((ix & MAX) << 16) | (iy & MAX);
    }

    /**
     * Static constructor following Morton2D style.
     */
    public static inline function create(ix:Int, iy:Int):XYpack {
        return new XYpack(ix, iy);
    }

    // Properties for easy access
    public var x(get, never):Int;
    inline function get_x():Int return (this >>> 16) & MAX;

    public var y(get, never):Int;
    inline function get_y():Int return this & MAX;

    // Operator overloading for comparison (identical to Morton2D style)
    @:op(A < B) static inline function lt(a:XYpack, b:XYpack):Bool return (a : Int) < (b : Int);
    @:op(A > B) static inline function gt(a:XYpack, b:XYpack):Bool return (a : Int) > (b : Int);
    @:op(A <= B) static inline function lte(a:XYpack, b:XYpack):Bool return (a : Int) <= (b : Int);
    @:op(A >= B) static inline function gte(a:XYpack, b:XYpack):Bool return (a : Int) >= (b : Int);
    @:op(A == B) static inline function eq(a:XYpack, b:XYpack):Bool return (a : Int) == (b : Int);
    @:op(A != B) static inline function neq(a:XYpack, b:XYpack):Bool return (a : Int) != (b : Int);

    /**
     * Allows native array sorting: points.sort((a, b) -> a - b);
     */
    @:op(A - B) static inline function sub(a:XYpack, b:XYpack):Int return (a : Int) - (b : Int);
    @:op(A + B) static inline function add(a:XYpack, b:XYpack):Int return (a : Int) - (b : Int);
    public inline function toString():String {
        return 'XYpack(x: $x, y: $y, raw: $this)';
    }
    /**
    * Ultimate Performance: insideBox using packed boundaries.
    * Inputs minP and maxP are already XyPack objects.
    */
    public inline function insideBox( minP: XYpack, maxP: XYpack): Bool {
        // 1. Separate the high (X) and low (Y) components into 32-bit registers
        // using masks to prevent 'bleeding' between coordinates during subtraction.
        var pX:Int = (this >>> 16) & 0xFFFF;
        var pY:Int = this & 0xFFFF;
        
        var minX:Int = (minP >>> 16) & 0xFFFF;
        var minY:Int = minP & 0xFFFF;
        
        var maxX:Int = (maxP >>> 16) & 0xFFFF;
        var maxY:Int = maxP & 0xFFFF;

        /**
        * THE BRANCHLESS SIGN-BIT HACK:
        * (A - B) results in a negative value (31st bit = 1) if A < B.
        * We OR these checks together; if any bit is 1, the point is OUTSIDE.
        */
        var check:Int = (pX - minX)    // 31st bit is 1 if pX < minX
                      | (maxX - pX)    // 31st bit is 1 if pX > maxX
                      | (pY - minY)    // 31st bit is 1 if pY < minY
                      | (maxY - pY);   // 31st bit is 1 if pY > maxY

        // Shift the accumulated sign bit to the 0th position.
        // If it is 0, the point is inside all four bounds.
        return (check >>> 31) == 0;
    }

}