package mortonHx;

import haxe.Int64;

/**
 * 64-bit 3D Morton Code (21 bits per dimension).
 * Supports spatial arithmetic and filtering without de-interleaving.
 */
@:forward
abstract Morton3Di64(Int64) from Int64 to Int64 {
    
    // --- Truncation Bounds ---
    static var max32(get, never):Int64;
    inline static function get_max32() return Int64.make(0x00000000, 0x7FFFFFFF);
    
    static var min32(get, never):Int64;
    inline static function get_min32() return Int64.make(0xFFFFFFFF, 0x80000000);

    @:from public static inline function fromInt(v:Int):Morton3Di64 return (Int64.ofInt(v):Morton3Di64);

    @:to public inline function toInt():Int {
        if ( (this > max32) || (this < min32) ) {
            throw "RangeError: Int64 value exceeds 32-bit signed range.";
        }
        return Int64.toInt(this);
    }

    // --- 64-bit Masks (Every 3rd bit) ---
    public static var maskX(get, never):Int64;
    inline static function get_maskX():Int64 {
        #if (haxe_ver >= 5.0) return 0x1249249249249249i64;
        #else return Int64.make(0x12492492, 0x49249249); #end
    }

    public static var maskY(get, never):Int64;
    inline static function get_maskY():Int64 {
        #if (haxe_ver >= 5.0) return 0x2492492492492492i64;
        #else return Int64.make(0x24924924, 0x92492492); #end
    }

    public static var maskZ(get, never):Int64;
    inline static function get_maskZ():Int64 {
        #if (haxe_ver >= 5.0) return 0x4924924924924924i64;
        #else return Int64.make(0x49249249, 0x24924924); #end
    }

    public static var maskNotX(get, never):Int64; inline static function get_maskNotX() return ~maskX;
    public static var maskNotY(get, never):Int64; inline static function get_maskNotY() return ~maskY;
    public static var maskNotZ(get, never):Int64; inline static function get_maskNotZ() return ~maskZ;

    /**
     * Encodes x, y, z into a 64-bit Morton Code.
     * Max value for each dimension is 2,097,151 (21 bits).
     */
    public inline function new(x:Int, y:Int, z:Int) {
        this = (part1By2(z) << 2) | (part1By2(y) << 1) | part1By2(x);
    }

    inline function part1By2(v:Int):Int64 {
        var x:Int64 = Int64.ofInt(v & 0x1FFFFF);
        x = (x | (x << 32)) & Int64.make(0x1F000000, 0x00FFFF);
        x = (x | (x << 16)) & Int64.make(0x1F0000FF, 0x0000FF);
        x = (x | (x << 8))  & Int64.make(0x100F00F0, 0x0F00F00F);
        x = (x | (x << 4))  & Int64.make(0x10C30C30, 0xC30C30C3);
        x = (x | (x << 2))  & Int64.make(0x12492492, 0x49249249);
        return x;
    }

    public inline function decode():{x:Int, y:Int, z:Int} {
        return {
            x: compact1By2(this),
            y: compact1By2(this >> 1),
            z: compact1By2(this >> 2)
        };
    }

    inline function compact1By2(v:Int64):Int {
        var x = v & maskX;
        x = (x | (x >> 2))  & Int64.make(0x10C30C30, 0xC30C30C3);
        x = (x | (x >> 4))  & Int64.make(0x100F00F0, 0x0F00F00F);
        x = (x | (x >> 8))  & Int64.make(0x1F0000FF, 0x0000FF);
        x = (x | (x >> 16)) & Int64.make(0x1F000000, 0x00FFFF);
        x = (x | (x >> 32)) & Int64.make(0x00000000, 0x1FFFFF);
        return Int64.toInt(x);
    }

    // --- Spatial Arithmetic ---

    @:op(A + B)
    public static inline function add(base:Morton3Di64, offset:Morton3Di64):Morton3Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b & maskX) + (o & maskX)) & maskX) |
               (((b & maskY) + (o & maskY)) & maskY) |
               (((b & maskZ) + (o & maskZ)) & maskZ);
    }

    @:op(A - B)
    public static inline function subtract(base:Morton3Di64, offset:Morton3Di64):Morton3Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b | maskNotX) - (o & maskX)) & maskX) |
               (((b | maskNotY) - (o & maskY)) & maskY) |
               (((b | maskNotZ) - (o & maskZ)) & maskZ);
    }

    @:op(A < B)  public static inline function lt(a:Morton3Di64, b:Morton3Di64):Bool return (a:Int64) < (b:Int64);
    @:op(A > B)  public static inline function gt(a:Morton3Di64, b:Morton3Di64):Bool return (a:Int64) > (b:Int64);
    @:op(A <= B) public static inline function lte(a:Morton3Di64, b:Morton3Di64):Bool return (a:Int64) <= (b:Int64);
    @:op(A >= B) public static inline function gte(a:Morton3Di64, b:Morton3Di64):Bool return (a:Int64) >= (b:Int64);
    @:op(A == B) public static inline function eq(a:Morton3Di64, b:Morton3Di64):Bool return (a:Int64) == (b:Int64);
    @:op(A != B) public static inline function neq(a:Morton3Di64, b:Morton3Di64):Bool return (a:Int64) != (b:Int64);
    
    public static inline function isInsideBox(p:Morton3Di64, min:Morton3Di64, max:Morton3Di64):Bool {
        var pi:Int64 = p, mi:Int64 = min, ma:Int64 = max;
        if ( ((pi & maskX) < (mi & maskX)) || ((pi & maskX) > (ma & maskX)) ) return false;
        if ( ((pi & maskY) < (mi & maskY)) || ((pi & maskY) > (ma & maskY)) ) return false;
        if ( ((pi & maskZ) < (mi & maskZ)) || ((pi & maskZ) > (ma & maskZ)) ) return false;
        return true;
    }
}
