package mortonHx;

import haxe.Int64;

/**
 * 64-bit 2D Morton Code (32 bits per dimension).
 * Supports spatial arithmetic and filtering without de-interleaving.
 */
@:forward
abstract Morton2Di64(Int64) from Int64 to Int64 {
    
    // --- Truncation Bounds ---
    static var max32(get, never):Int64;
    inline static function get_max32() return Int64.make(0x00000000, 0x7FFFFFFF);
    
    static var min32(get, never):Int64;
    inline static function get_min32() return Int64.make(0xFFFFFFFF, 0x80000000);

    @:from public static inline function fromInt(v:Int):Morton2Di64 return (Int64.ofInt(v):Morton2Di64);

    @:to public inline function toInt():Int {
        if ( (this > max32) || (this < min32) ) {
            throw "RangeError: Int64 value exceeds 32-bit signed range.";
        }
        return Int64.toInt(this);
    }

    // --- 64-bit Masks (Every 2nd bit) ---
    public static var maskX(get, never):Int64;
    inline static function get_maskX():Int64 {
        #if (haxe_ver >= 5.0) return 0x5555555555555555i64;
        #else return Int64.make(0x55555555, 0x55555555); #end
    }

    public static var maskY(get, never):Int64;
    inline static function get_maskY():Int64 {
        #if (haxe_ver >= 5.0) return 0xAAAAAAAAAAAAAAAAi64;
        #else return Int64.make(0xAAAAAAAA, 0xAAAAAAAA); #end
    }

    public static var maskNotX(get, never):Int64; inline static function get_maskNotX() return ~maskX;
    public static var maskNotY(get, never):Int64; inline static function get_maskNotY() return ~maskY;

    /**
     * Encodes x and y into a 64-bit Morton Code.
     * Max value for each dimension is 4,294,967,295 (32 bits).
     */
    public inline function new(x:Int, y:Int) {
        this = (part1By1(y) << 1) | part1By1(x);
    }

    inline function part1By1(v:Int):Int64 {
        var x:Int64 = Int64.ofInt(v);
        x = (x | (x << 16)) & Int64.make(0x0000FFFF, 0x0000FFFF);
        x = (x | (x << 8))  & Int64.make(0x00FF00FF, 0x00FF00FF);
        x = (x | (x << 4))  & Int64.make(0x0F0F0F0F, 0x0F0F0F0F);
        x = (x | (x << 2))  & Int64.make(0x33333333, 0x33333333);
        x = (x | (x << 1))  & Int64.make(0x55555555, 0x55555555);
        return x;
    }

    public inline function decode():{x:Int, y:Int} {
        return {
            x: compact1By1(this),
            y: compact1By1(this >> 1)
        };
    }

    inline function compact1By1(v:Int64):Int {
        var x = v & maskX;
        x = (x | (x >> 1)) & Int64.make(0x33333333, 0x33333333);
        x = (x | (x >> 2)) & Int64.make(0x0F0F0F0F, 0x0F0F0F0F);
        x = (x | (x >> 4)) & Int64.make(0x00FF00FF, 0x00FF00FF);
        x = (x | (x >> 8)) & Int64.make(0x0000FFFF, 0x0000FFFF);
        x = (x | (x >> 16)) & Int64.make(0x00000000, 0xFFFFFFFF);
        return Int64.toInt(x);
    }

    // --- Spatial Arithmetic ---

    @:op(A + B)
    public static inline function add(base:Morton2Di64, offset:Morton2Di64):Morton2Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b & maskX) + (o & maskX)) & maskX) |
               (((b & maskY) + (o & maskY)) & maskY);
    }

    @:op(A - B)
    public static inline function subtract(base:Morton2Di64, offset:Morton2Di64):Morton2Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b | maskNotX) - (o & maskX)) & maskX) |
               (((b | maskNotY) - (o & maskY)) & maskY);
    }

    @:op(A < B)  public static inline function lt(a:Morton2Di64, b:Morton2Di64):Bool return (a:Int64) < (b:Int64);
    @:op(A > B)  public static inline function gt(a:Morton2Di64, b:Morton2Di64):Bool return (a:Int64) > (b:Int64);
    @:op(A <= B) public static inline function lte(a:Morton2Di64, b:Morton2Di64):Bool return (a:Int64) <= (b:Int64);
    @:op(A >= B) public static inline function gte(a:Morton2Di64, b:Morton2Di64):Bool return (a:Int64) >= (b:Int64);
    @:op(A == B) public static inline function eq(a:Morton2Di64, b:Morton2Di64):Bool return (a:Int64) == (b:Int64);
    @:op(A != B) public static inline function neq(a:Morton2Di64, b:Morton2Di64):Bool return (a:Int64) != (b:Int64);
    
    public static inline function isInsideBox(p:Morton2Di64, min:Morton2Di64, max:Morton2Di64):Bool {
        var pi:Int64 = p, mi:Int64 = min, ma:Int64 = max;
        if ( ((pi & maskX) < (mi & maskX)) || ((pi & maskX) > (ma & maskX)) ) return false;
        if ( ((pi & maskY) < (mi & maskY)) || ((pi & maskY) > (ma & maskY)) ) return false;
        return true;
    }
}
