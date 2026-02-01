package mortonHx.morton;

import haxe.Int64;

/**
 * Data container for decoded 5D Morton coordinates.
 */
@:structInit
class Point5DInt_ {
    public var x: Int;
    public var y: Int;
    public var z: Int;
    public var w: Int;
    public var v: Int;
    
    public inline function new(x: Int, y: Int, z: Int, w: Int, v: Int) {
        this.x = x; this.y = y; this.z = z; this.w = w; this.v = v;
    }
    
    public function toString() return '($x, $y, $z, $w, $v)';
}

/**
 * Abstract wrapper for Point5DInt providing conversion to/from Morton5Di64.
 */
@:forward
abstract Point5DInt(Point5DInt_) from Point5DInt_ to Point5DInt_ {
    public inline function new(x: Int, y: Int, z: Int, w: Int, v: Int) {
        this = new Point5DInt_(x, y, z, w, v);
    }

    @:to
    public inline function toMorton5D(): Morton5Di64 {
        return new Morton5Di64(this.x, this.y, this.z, this.w, this.v);
    }

    @:from
    public static inline function fromMorton5D(m: Morton5Di64): Point5DInt {
        return m.decode();
    }
}

/**
 * 64-bit 5D Morton Code (12 bits per dimension: 0-4095).
 * Interleaves as: v11,w11,z11,y11,x11 ... v0,w0,z0,y0,x0
 */
@:forward
abstract Morton5Di64(Int64) from Int64 to Int64 {
    
    static var max32(get, never):Int64;
    inline static function get_max32() return Int64.make(0x00000000, 0x7FFFFFFF);
    
    static var min32(get, never):Int64;
    inline static function get_min32() return Int64.make(0xFFFFFFFF, 0x80000000);

    // --- 64-bit Masks (isolating every 5th bit) ---
    public static var maskX(get, never):Int64;
    inline static function get_maskX() return Int64.make(0x08421084, 0x21084210);
    public static var maskY(get, never):Int64;
    inline static function get_maskY() return Int64.make(0x10842108, 0x42108421);
    public static var maskZ(get, never):Int64;
    inline static function get_maskZ() return Int64.make(0x21084210, 0x84210842);
    public static var maskW(get, never):Int64;
    inline static function get_maskW() return Int64.make(0x42108421, 0x08421084);
    public static var maskV(get, never):Int64;
    inline static function get_maskV() return Int64.make(0x84210842, 0x10842108);

    public static var maskNotX(get, never):Int64; inline static function get_maskNotX() return ~maskX;
    public static var maskNotY(get, never):Int64; inline static function get_maskNotY() return ~maskY;
    public static var maskNotZ(get, never):Int64; inline static function get_maskNotZ() return ~maskZ;
    public static var maskNotW(get, never):Int64; inline static function get_maskNotW() return ~maskW;
    public static var maskNotV(get, never):Int64; inline static function get_maskNotV() return ~maskV;

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m = new Morton5Di64(1, 2, 3, 4, 5);
     * ...   var d = m.decode();
     * ...   d.x == 1 && d.y == 2 && d.z == 3 && d.w == 4 && d.v == 5; }) == true
     * </code></pre>
     */
    public inline function new(x:Int, y:Int, z:Int, w:Int, v:Int) {
        this = (spread(v) << 4) | (spread(w) << 3) | (spread(z) << 2) | (spread(y) << 1) | spread(x);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m:Morton5Di64 = 1000;
     * ...   m.toInt() == 1000; }) == true
     * </code></pre>
     */
    @:from public static inline function fromInt(v:Int):Morton5Di64 return (Int64.ofInt(v):Morton5Di64);

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m:Morton5Di64 = 500;
     * ...   m.toInt(); }) == 500
     * >>> ({ 
     * ...   var m = new Morton5Di64(4000, 4000, 4000, 4000, 4000); 
     * ...   try { m.toInt(); false; } catch(e:String) { true; }; }) == true
     * </code></pre>
     */
    @:to public inline function toInt():Int {
        if ( (this > max32) || (this < min32) ) {
            throw "RangeError: Morton5Di64 value exceeds 32-bit range.";
        }
        return Int64.toInt(this);
    }

    inline function spread(n:Int):Int64 {
        var x:Int64 = Int64.ofInt(n & 0xFFF);
        x = (x | (x << 32)) & Int64.make(0x00000F00, 0x000000FF);
        x = (x | (x << 16)) & Int64.make(0x000C0300, 0xC0300C03);
        x = (x | (x << 8))  & Int64.make(0x08421084, 0x21084210);
        return x;
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m = new Morton5Di64(4095, 0, 4095, 0, 4095);
     * ...   var res = m.decode();
     * ...   res.x == 4095 && res.y == 0 && res.v == 4095; }) == true
     * </code></pre>
     */
    public inline function decode():Point5DInt {
        return new Point5DInt(compact(this), compact(this >> 1), compact(this >> 2), compact(this >> 3), compact(this >> 4));
    }

    inline function compact(v:Int64):Int {
        var x = v & maskX;
        x = (x | (x >> 8))  & Int64.make(0x000C0300, 0xC0300C03);
        x = (x | (x >> 16)) & Int64.make(0x00000F00, 0x000000FF);
        x = (x | (x >> 32)) & Int64.make(0x00000000, 0x00000FFF);
        return Int64.toInt(x);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m1 = new Morton5Di64(10, 10, 10, 10, 10);
     * ...   var m2 = new Morton5Di64(5, 5, 5, 5, 5);
     * ...   var res = (m1 + m2).decode();
     * ...   res.x == 15 && res.v == 15; }) == true
     * </code></pre>
     */
    @:op(A + B)
    public static inline function add(base:Morton5Di64, offset:Morton5Di64):Morton5Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b & maskX) + (o & maskX)) & maskX) |
               (((b & maskY) + (o & maskY)) & maskY) |
               (((b & maskZ) + (o & maskZ)) & maskZ) |
               (((b & maskW) + (o & maskW)) & maskW) |
               (((b & maskV) + (o & maskV)) & maskV);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m1 = new Morton5Di64(1, 1, 1, 1, 1);
     * ...   var m2 = new Morton5Di64(1, 1, 1, 1, 2);
     * ...   m1 < m2 && m1 != m2 && m1 <= m1 && m2 >= m1; }) == true
     * </code></pre>
     */
     @:op(A < B)  public static inline function lt(a:Morton5Di64, b:Morton5Di64):Bool return (a:Int64) < (b:Int64);
     @:op(A > B)  public static inline function gt(a:Morton5Di64, b:Morton5Di64):Bool return (a:Int64) > (b:Int64);
     @:op(A <= B) public static inline function lte(a:Morton5Di64, b:Morton5Di64):Bool return (a:Int64) <= (b:Int64);
     @:op(A >= B) public static inline function gte(a:Morton5Di64, b:Morton5Di64):Bool return (a:Int64) >= (b:Int64);
     @:op(A == B) public static inline function eq(a:Morton5Di64, b:Morton5Di64):Bool return (a:Int64) == (b:Int64);
     @:op(A != B) public static inline function neq(a:Morton5Di64, b:Morton5Di64):Bool return (a:Int64) != (b:Int64);

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var p = new Morton5Di64(10, 10, 10, 10, 10);
     * ...   var min = new Morton5Di64(0, 0, 0, 0, 0);
     * ...   var max = new Morton5Di64(20, 20, 20, 20, 20);
     * ...   Morton5Di64.isInsideBox(p, min, max); }) == true
     * </code></pre>
     */
    public static inline function isInsideBox(p:Morton5Di64, min:Morton5Di64, max:Morton5Di64):Bool {
        var pi:Int64 = p, mi:Int64 = min, ma:Int64 = max;
        if ( ((pi & maskX) < (mi & maskX)) || ((pi & maskX) > (ma & maskX)) ) return false;
        if ( ((pi & maskY) < (mi & maskY)) || ((pi & maskY) > (ma & maskY)) ) return false;
        if ( ((pi & maskZ) < (mi & maskZ)) || ((pi & maskZ) > (ma & maskZ)) ) return false;
        if ( ((pi & maskW) < (mi & maskW)) || ((pi & maskW) > (ma & maskW)) ) return false;
        if ( ((pi & maskV) < (mi & maskV)) || ((pi & maskV) > (ma & maskV)) ) return false;
        return true;
    }
}

