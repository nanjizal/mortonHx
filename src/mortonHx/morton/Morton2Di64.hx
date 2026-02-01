package mortonHx.morton;

import haxe.Int64;

/**
 * High-performance Look-Up Tables for Morton Encoding/Decoding.
 * Using camelCase for Haxe consistency.
 */
class MortonLut {
    public static var encodeTable:Array<Int> = {
        var a = [];
        for (i in 0...256) {
            var v = i;
            v = (v | (v << 8)) & 0x00FF00FF;
            v = (v | (v << 4)) & 0x0F0F0F0F;
            v = (v | (v << 2)) & 0x33333333;
            v = (v | (v << 1)) & 0x55555555;
            a.push(v);
        }
        a;
    };

    public static var decodeTable:Array<Int> = {
        var a = [for (i in 0...256) 0];
        for (i in 0...256) {
            var v = i & 0x55;
            v = (v | (v >> 1)) & 0x33;
            v = (v | (v >> 2)) & 0x0F;
            v = (v | (v >> 4)) & 0x00FF;
            a[i] = v;
        }
        a;
    };
}

@:structInit
class Point2DInt64_ {
    public var x: Int;
    public var y: Int;
    public inline function new(x: Int, y: Int) {
        this.x = x;
        this.y = y;
    }
}

@:forward
abstract Point2DInt64(Point2DInt64_) from Point2DInt64_ to Point2DInt64_ {
    public inline function new(x: Int, y: Int) {
        this = new Point2DInt64_(x, y);
    }
    @:to public inline function toMorton2Di64(): Morton2Di64 {
        return new Morton2Di64(this.x, this.y);
    }
    @:from public static inline function fromMorton2Di64(m: Morton2Di64): Point2DInt64 {
        return m.decode();
    }
}

/**
 * Extreme Performance 64-bit 2D Morton Code (camelCase version).
 */
@:forward
abstract Morton2Di64(Int64) from Int64 to Int64 {
    
    public inline function new(x: Int, y: Int) {
        this = (encode32(y) << 1) | encode32(x);
    }

    static inline function encode32(v: Int): Int64 {
        return (Int64.ofInt(MortonLut.encodeTable[(v >>> 24) & 0xFF]) << 48) |
               (Int64.ofInt(MortonLut.encodeTable[(v >>> 16) & 0xFF]) << 32) |
               (Int64.ofInt(MortonLut.encodeTable[(v >>> 8) & 0xFF]) << 16) |
                Int64.ofInt(MortonLut.encodeTable[v & 0xFF]);
    }

    public inline function decode(): Point2DInt64 {
        return new Point2DInt64(decode64(this), decode64(this >> 1));
    }

    static inline function decode64(v: Int64): Int {
        var low = v.low;
        var high = v.high;
        return (MortonLut.decodeTable[(high >>> 16) & 0xFF] << 24) |
               (MortonLut.decodeTable[high & 0xFF] << 16) |
               (MortonLut.decodeTable[(low >>> 16) & 0xFF] << 8) |
                MortonLut.decodeTable[low & 0xFF];
    }

    // --- Masks ---
    public static var maskX(get, never): Int64;
    inline static function get_maskX(): Int64 return Int64.make(0x55555555, 0x55555555);

    public static var maskY(get, never): Int64;
    inline static function get_maskY(): Int64 return Int64.make(0xAAAAAAAA, 0xAAAAAAAA);

    public static var maskNotX(get, never): Int64; inline static function get_maskNotX() return ~maskX;
    public static var maskNotY(get, never): Int64; inline static function get_maskNotY() return ~maskY;

    // --- Spatial Arithmetic ---
    @:op(A + B)
    public static inline function add(base: Morton2Di64, offset: Morton2Di64): Morton2Di64 {
        return (((base & maskX) + (offset & maskX)) & maskX) |
               (((base & maskY) + (offset & maskY)) & maskY);
    }

    @:op(A - B)
    public static inline function subtract(base: Morton2Di64, offset: Morton2Di64): Morton2Di64 {
        return (((base | maskNotX) - (offset & maskX)) & maskX) |
               (((base | maskNotY) - (offset & maskY)) & maskY);
    }

    @:op(A < B)  static inline function lt(a: Morton2Di64, b: Morton2Di64): Bool return (a: Int64) < (b: Int64);
    @:op(A > B)  static inline function gt(a: Morton2Di64, b: Morton2Di64): Bool return (a: Int64) > (b: Int64);
    @:op(A <= B) static inline function lte(a: Morton2Di64, b: Morton2Di64): Bool return (a: Int64) <= (b: Int64);
    @:op(A >= B) static inline function gte(a: Morton2Di64, b: Morton2Di64): Bool return (a: Int64) >= (b: Int64);

    // --- Range & Box Filtering ---
    public static inline function isInsideBox(p: Morton2Di64, min: Morton2Di64, max: Morton2Di64): Bool {
        var px = (p : Int64) & maskX;
        var py = (p : Int64) & maskY;
        return (px >= ((min: Int64) & maskX) && px <= ((max: Int64) & maskX)) &&
               (py >= ((min: Int64) & maskY) && py <= ((max: Int64) & maskY));
    }

    public static function isInRange(p: Morton2Di64, v1: Morton2Di64, v2: Morton2Di64, v3: Morton2Di64): Bool {
        // min/max selection using Int64 comparison
        var min = (v1 < v2) ? ((v1 < v3) ? v1 : v3) : ((v2 < v3) ? v2 : v3);
        var max = (v1 > v2) ? ((v1 > v3) ? v1 : v3) : ((v2 > v3) ? v2 : v3);
        
        var diff: Int64 = Int64.xor(min,max);
        if (diff == Int64.make(0, 0)) return (p : Int64) == (v1 : Int64);

        var v: Int64 = diff;
        v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16; v |= v >> 32;
        
        var mask: Int64 = ~v;
        return ((p : Int64) & mask) == ((v1 : Int64) & mask);
    }
}
