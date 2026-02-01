package mortonHx.morton;
import mortonHx.pointInTriangle.PointHitInt64;
import mortonHx.morton.Morton4Di64;
import mortonHx.morton.Morton4D;
import haxe.Int64;

/**
 * 64-bit 4D Morton Code (16 bits per dimension).
 * Supports spatial arithmetic and filtering without de-interleaving.
 */
@:forward
abstract Morton4Di64(Int64) from Int64 to Int64 {
    
    // --- Truncation Bounds ---
    static var max32(get, never):Int64;
    inline static function get_max32() return Int64.make(0x00000000, 0x7FFFFFFF);
    
    static var min32(get, never):Int64;
    inline static function get_min32() return Int64.make(0xFFFFFFFF, 0x80000000);

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m64 = new Morton4Di64(5, 0, 0, 0); 
     * ...   var m32:Morton4D = m64;
     * ...   (m32 : Int) > 0; }) == true
     * >>> ({ 
     * ...   var m64 = new Morton4Di64(65535, 65535, 65535, 65535); 
     * ...   try { var m32:Morton4D = m64; false; } catch(e:String) { true; }; }) == true
     * </code></pre>
     */
    @:from public static inline function fromMorton32(v:Morton4D):Morton4Di64 {
        return (Int64.ofInt((v : Int)):Morton4Di64);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m64 = new Morton4Di64(10, 10, 10, 10);
     * ...   m64.toMorton32() != null; }) == true
     * </code></pre>
     */
    @:access( haxe.Int64 )
    @:to public inline function toMorton32():Morton4D {
        if ( (this > max32) || (this < min32) ) {
            throw "RangeError: Morton4Di64 value exceeds 32-bit signed range and would truncate.";
        }
        return (Int64.toInt(this) : Morton4D);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m:Morton4Di64 = 12345;
     * ...   m.toInt() == 12345; }) == true
     * </code></pre>
     */
    @:from public static inline function fromInt(v:Int):Morton4Di64 return (Int64.ofInt(v):Morton4Di64);

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m:Morton4Di64 = 100;
     * ...   m.toInt(); }) == 100
     * </code></pre>
     */
    @:to public inline function toInt():Int {
        if ( (this > max32) || (this < min32) ) {
            throw "RangeError: Int64 value exceeds 32-bit signed range.";
        }
        return Int64.toInt(this);
    }

    // --- 64-bit Masks ---
    public static var maskX(get, never):Int64;
    inline static function get_maskX():Int64 {
        #if (haxe_ver >= 5.0) return 0x1111111111111111i64;
        #else return Int64.make(0x11111111, 0x11111111); #end
    }

    public static var maskY(get, never):Int64;
    inline static function get_maskY():Int64 {
        #if (haxe_ver >= 5.0) return 0x2222222222222222i64;
        #else return Int64.make(0x22222222, 0x22222222); #end
    }

    public static var maskZ(get, never):Int64;
    inline static function get_maskZ():Int64 {
        #if (haxe_ver >= 5.0) return 0x4444444444444444i64;
        #else return Int64.make(0x44444444, 0x44444444); #end
    }

    public static var maskW(get, never):Int64;
    inline static function get_maskW():Int64 {
        #if (haxe_ver >= 5.0) return 0x8888888888888888i64;
        #else return Int64.make(0x88888888, 0x88888888); #end
    }

    public static var maskNotX(get, never):Int64; inline static function get_maskNotX() return ~maskX;
    public static var maskNotY(get, never):Int64; inline static function get_maskNotY() return ~maskY;
    public static var maskNotZ(get, never):Int64; inline static function get_maskNotZ() return ~maskZ;
    public static var maskNotW(get, never):Int64; inline static function get_maskNotW() return ~maskW;

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m = new Morton4Di64(1, 2, 3, 4);
     * ...   var d = m.decode();
     * ...   d.x == 1 && d.y == 2 && d.z == 3 && d.w == 4; }) == true
     * </code></pre>
     */
    public inline function new(x:Int, y:Int, z:Int, w:Int) {
        this = (part1By3(w) << 3) | (part1By3(z) << 2) | (part1By3(y) << 1) | part1By3(x);
    }

    inline function part1By3(v:Int):Int64 {
        var x:Int64 = Int64.ofInt(v & 0xFFFF);
        x = (x | (x << 24)) & Int64.make(0x000F0000, 0x0000000F);
        x = (x | (x << 12)) & Int64.make(0x000F000F, 0x000F000F);
        x = (x | (x << 6))  & Int64.make(0x03030303, 0x03030303);
        x = (x | (x << 3))  & Int64.make(0x11111111, 0x11111111);
        return x;
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m = new Morton4Di64(65535, 32768, 0, 1);
     * ...   var res = m.decode();
     * ...   res.x == 65535 && res.y == 32768 && res.z == 0 && res.w == 1; }) == true
     * </code></pre>
     */
    public inline function decode():Point4DInt {
        return new Point4DInt(compact1By3(this), compact1By3(this >> 1), compact1By3(this >> 2), compact1By3(this >> 3));
    }

    inline function compact1By3(v:Int64):Int {
        var x = v & maskX;
        x = (x | (x >> 3))  & Int64.make(0x03030303, 0x03030303);
        x = (x | (x >> 6))  & Int64.make(0x000F000F, 0x000F000F);
        x = (x | (x >> 12)) & Int64.make(0x000F0000, 0x0000000F);
        x = (x | (x >> 24)) & Int64.make(0x00000000, 0x0000FFFF);
        return Int64.toInt(x);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m1 = new Morton4Di64(100, 100, 100, 100);
     * ...   var m2 = new Morton4Di64(50, 50, 50, 50);
     * ...   var res = (m1 + m2).decode();
     * ...   res.x == 150 && res.y == 150 && res.z == 150 && res.w == 150; }) == true
     * </code></pre>
     */
    @:op(A + B)
    public static inline function add(base:Morton4Di64, offset:Morton4Di64):Morton4Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b & maskX) + (o & maskX)) & maskX) |
               (((b & maskY) + (o & maskY)) & maskY) |
               (((b & maskZ) + (o & maskZ)) & maskZ) |
               (((b & maskW) + (o & maskW)) & maskW);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m1 = new Morton4Di64(10, 10, 10, 10);
     * ...   var m2 = new Morton4Di64(3, 3, 3, 3);
     * ...   var res = (m1 - m2).decode();
     * ...   res.x == 7 && res.y == 7 && res.z == 7 && res.w == 7; }) == true
     * </code></pre>
     */
    @:op(A - B)
    public static inline function subtract(base:Morton4Di64, offset:Morton4Di64):Morton4Di64 {
        var b:Int64 = base, o:Int64 = offset;
        return (((b | maskNotX) - (o & maskX)) & maskX) |
               (((b | maskNotY) - (o & maskY)) & maskY) |
               (((b | maskNotZ) - (o & maskZ)) & maskZ) |
               (((b | maskNotW) - (o & maskW)) & maskW);
    }

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var m1 = new Morton4Di64(0, 0, 0, 10);
     * ...   var m2 = new Morton4Di64(0, 0, 0, 20);
     * ...   m1 < m2 && m1 != m2 && m1 <= m2 && m2 >= m1; }) == true
     * </code></pre>
     */
    @:op(A < B)  public static inline function lt(a:Morton4Di64, b:Morton4Di64):Bool return (a:Int64) < (b:Int64);
    @:op(A > B)  public static inline function gt(a:Morton4Di64, b:Morton4Di64):Bool return (a:Int64) > (b:Int64);
    @:op(A <= B) public static inline function lte(a:Morton4Di64, b:Morton4Di64):Bool return (a:Int64) <= (b:Int64);
    @:op(A >= B) public static inline function gte(a:Morton4Di64, b:Morton4Di64):Bool return (a:Int64) >= (b:Int64);
    @:op(A == B) public static inline function eq(a:Morton4Di64, b:Morton4Di64):Bool return (a:Int64) == (b:Int64);
    @:op(A != B) public static inline function neq(a:Morton4Di64, b:Morton4Di64):Bool return (a:Int64) != (b:Int64);

    /**
     * <pre><code>
     * >>> ({ 
     * ...   var p = new Morton4Di64(50, 50, 50, 50);
     * ...   var min = new Morton4Di64(40, 40, 40, 40);
     * ...   var max = new Morton4Di64(60, 60, 60, 60);
     * ...   Morton4Di64.isInsideBox(p, min, max); }) == true
     * >>> ({ 
     * ...   var p = new Morton4Di64(70, 50, 50, 50);
     * ...   var min = new Morton4Di64(40, 40, 40, 40);
     * ...   var max = new Morton4Di64(60, 60, 60, 60);
     * ...   Morton4Di64.isInsideBox(p, min, max); }) == false
     * </code></pre>
     */
    public static inline function isInsideBox(p:Morton4Di64, min:Morton4Di64, max:Morton4Di64):Bool {
        var pi:Int64 = p, mi:Int64 = min, ma:Int64 = max;
        if ( ((pi & maskX) < (mi & maskX)) || ((pi & maskX) > (ma & maskX)) ) return false;
        if ( ((pi & maskY) < (mi & maskY)) || ((pi & maskY) > (ma & maskY)) ) return false;
        if ( ((pi & maskZ) < (mi & maskZ)) || ((pi & maskZ) > (ma & maskZ)) ) return false;
        if ( ((pi & maskW) < (mi & maskW)) || ((pi & maskW) > (ma & maskW)) ) return false;
        return true;
    }
}
