package mortonHx;

@:structInit
class Point4DInt_ {
    public var x: Int;
    public var y: Int;
    public var z: Int;
    public var w: Int;
    public inline function new( x: Int, y: Int, z: Int, w: Int ){
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }
}

@:forward
abstract Point4DInt( Point4DInt_ ) from Point4DInt_ to Point4DInt_ {
    public inline function new( x: Int, y: Int, z: Int, w: Int ){
        this = new Point4DInt_( x, y, z, w );
    }
    @:to
    public inline function toMorton4D(): Morton4D {
        return new Morton4D( this.x, this.y, this.z, this.w );
    }
}

abstract Morton4D(Int) from Int to Int {
    // Max value for 8 bits is 255 (8 * 4 = 32 bits total)
    public static inline var maxCoord = 255; 
    
    // 4D bitmasks for 32-bit integers
    static inline var maskX4d:Int = 0x11111111; // bits 0, 4, 8...
    static inline var maskY4d:Int = 0x22222222; // bits 1, 5, 9...
    static inline var maskZ4d:Int = 0x44444444; // bits 2, 6, 10...
    static inline var maskW4d:Int = 0x88888888; // bits 3, 7, 11...

    static inline var maskNotX4d:Int = ~0x11111111;
    static inline var maskNotY4d:Int = ~0x22222222;
    static inline var maskNotZ4d:Int = ~0x44444444;
    static inline var maskNotW4d:Int = ~0x88888888;

    public inline function new( x: Int, y: Int, z: Int, w: Int ) {
        // Interleave: w(3), z(2), y(1), x(0)
        this = (part1By3(w) << 3) | (part1By3(z) << 2) | (part1By3(y) << 1) | part1By3(x);
    }

    // Spreads 8 bits into 32 bits (leaving 3 empty spaces between bits)
    inline function part1By3(v:Int):Int {
        v &= 0x000000ff;                  
        v = (v | (v << 12)) & 0x000f000f; 
        v = (v | (v << 6))  & 0x03030303; 
        v = (v | (v << 3))  & 0x11111111; 
        return v;
    }

    public inline function decode(): Point4DInt {
        return new Point4DInt( 
            compact1By3( this ), 
            compact1By3( this >> 1 ), 
            compact1By3( this >> 2 ),
            compact1By3( this >> 3 )
        );
    }

    // Compresses bits by removing 3 spaces between bits
    inline function compact1By3(v:Int):Int {
        v &= 0x11111111;
        v = (v | (v >> 3)) & 0x03030303;
        v = (v | (v >> 6)) & 0x000f000f;
        v = (v | (v >> 12)) & 0x000000ff;
        return v;
    }
 
    @:op(A + B)
    public static inline function add(base:Morton4D, offset:Morton4D):Morton4D {
        return (
            ((base:Int) & maskX4d) + ((offset:Int) & maskX4d) |
            ((base:Int) & maskY4d) + ((offset:Int) & maskY4d) |
            ((base:Int) & maskZ4d) + ((offset:Int) & maskZ4d) |
            ((base:Int) & maskW4d) + ((offset:Int) & maskW4d)
            : Morton4D
        );
    }

    @:op(A - B)
    public static inline function subtract(base:Morton4D, offset:Morton4D):Morton4D {
        return (
            ((base:Int) | maskNotX4d) - ((offset:Int) & maskX4d) |
            ((base:Int) | maskNotY4d) - ((offset:Int) & maskY4d) |
            ((base:Int) | maskNotZ4d) - ((offset:Int) & maskZ4d) |
            ((base:Int) | maskNotW4d) - ((offset:Int) & maskW4d)
            : Morton4D
        );
    }

    @:op(A < B) static inline function lt(a:Morton4D, b:Morton4D):Bool return (a:Int) < (b:Int);
    @:op(A > B) static inline function gt(a:Morton4D, b:Morton4D):Bool return (a:Int) > (b:Int);
    @:op(A <= B) static inline function lte(a:Morton4D, b:Morton4D):Bool return (a:Int) <= (b:Int);
    @:op(A >= B) static inline function gte(a:Morton4D, b:Morton4D):Bool return (a:Int) >= (b:Int);

    public static inline function isInsideBox(p:Morton4D, min:Morton4D, max:Morton4D):Bool {
        var pi:Int = (p:Int);
        var mi:Int = (min:Int);
        var ma:Int = (max:Int);

        if ((pi & maskX4d) < (mi & maskX4d) || (pi & maskX4d) > (ma & maskX4d)) return false;
        if ((pi & maskY4d) < (mi & maskY4d) || (pi & maskY4d) > (ma & maskY4d)) return false;
        if ((pi & maskZ4d) < (mi & maskZ4d) || (pi & maskZ4d) > (ma & maskZ4d)) return false;
        if ((pi & maskW4d) < (mi & maskW4d) || (pi & maskW4d) > (ma & maskW4d)) return false;

        return true;
    }
}
