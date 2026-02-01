package mortonHx.pointInTriangle;

import haxe.Int64;

/**
 * Interface for 64-bit safe High-Precision Hit Testing.
 */
interface IHitInt64 {
    function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void;
    function hitCheck(x:Int, y:Int):Bool;
}

/**
 * Optimized BarycentricHitInt64
 * Uses internal Float math (53-bit precision) to handle 32-bit axis coordinates.
 */
class BarycentricHitInt64 implements IHitInt64 {
    var ax:Float; var ay:Float;
    var v0x:Float; var v0y:Float;
    var v1x:Float; var v1y:Float;
    var d00:Float; var d01:Float;
    var d11:Float;
    var denom:Float;

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        this.ax = (ax : Float); this.ay = (ay : Float);
        this.v0x = (cx : Float) - this.ax; this.v0y = (cy : Float) - this.ay;
        this.v1x = (bx : Float) - this.ax; this.v1y = (by : Float) - this.ay;
        this.d00 = v0x * v0x + v0y * v0y;
        this.d01 = v0x * v1x + v0y * v1y;
        this.d11 = v1x * v1x + v1y * v1y;
        this.denom = (d00 * d11 - d01 * d01);
    }

    public inline function hitCheck(x:Int, y:Int):Bool {
        final v2x = (x : Float) - ax;
        final v2y = (y : Float) - ay;
        final d02 = v0x * v2x + v0y * v2y;
        final d12 = v1x * v2x + v1y * v2y;

        final uNum = d11 * d02 - d01 * d12;
        final vNum = d00 * d12 - d01 * d02;

        if (denom >= 0) {
            return (uNum >= 0) && (vNum >= 0) && (uNum + vNum <= denom);
        } else {
            return (uNum <= 0) && (vNum <= 0) && (uNum + vNum >= denom);
        }
    }
}

/**
 * Optimized EdgeFunctionHitInt64
 * Uses Float coefficients to prevent overflow in large coordinate spaces.
 */
class EdgeFunctionHitInt64 implements IHitInt64 {
    var a1:Float; var b1:Float; var c1:Float;
    var a2:Float; var b2:Float; var c2:Float;
    var a3:Float; var b3:Float; var c3:Float;

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        var fax:Float = ax; var fay:Float = ay;
        var fbx:Float = bx; var fby:Float = by;
        var fcx:Float = cx; var fcy:Float = cy;

        a1 = fay - fby; b1 = fbx - fax; c1 = fax * fby - fay * fbx;
        a2 = fby - fcy; b2 = fcx - fbx; c2 = fbx * fcy - fby * fcx;
        a3 = fcy - fay; b3 = fax - fcx; c3 = fcx * fay - fcy * fax;
    }

    public inline function hitCheck(x:Int, y:Int):Bool {
        var fx:Float = x; var fy:Float = y;
        final s1 = a1 * fx + b1 * fy + c1;
        final s2 = a2 * fx + b2 * fy + c2;
        if ((s1 < 0) != (s2 < 0)) return false; 
        final s3 = a3 * fx + b3 * fy + c3;
        return (s1 < 0) == (s3 < 0);
    }
}

/**
 * Optimized SameSideHitInt64
 * Cross-product based hit test safe for 32-bit coordinates.
 */
class SameSideHitInt64 implements IHitInt64 {
    var ax:Float; var ay:Float;
    var bx:Float; var by:Float;
    var cx:Float; var cy:Float;
    var signA:Float; var signB:Float; var signC:Float;

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        this.ax = ax; this.ay = ay;
        this.bx = bx; this.by = by;
        this.cx = cx; this.cy = cy;

        signA = (cx - bx) * (ay - by) - (cy - by) * (ax - bx);
        signB = (ax - cx) * (by - cy) - (ay - cy) * (bx - cx);
        signC = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    }

    public inline function hitCheck(x:Int, y:Int):Bool {
        var fx:Float = x; var fy:Float = y;
        if (((cx - bx) * (fy - by) - (cy - by) * (fx - bx)) * signA < 0) return false;
        if (((ax - cx) * (fy - cy) - (ay - cy) * (fx - cx)) * signB < 0) return false;
        if (((bx - ax) * (fy - ay) - (by - ay) * (fx - ax)) * signC < 0) return false;
        return true;
    }
}

/**
 * High-performance struct for returning barycentric weights.
 */
#if cpp @:struct #end
@:structInit
class BarycentricResultUV {
    public var hit:Bool;
    public var u:Float;
    public var v:Float;
    public var w:Float;

    public function new(hit:Bool, u:Float, v:Float, w:Float) {
        this.hit = hit;
        this.u = u;
        this.v = v;
        this.w = w;
    }
}

/**
 * Interface for returning UV weights using 64-bit safe math.
 */
interface IHitInt64UV {
    function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void;
    function getWeights(x:Int, y:Int):BarycentricResultUV;
}

/**
 * BarycentricWeightInt64
 * Calculates precise triangle weights for points in large coordinate spaces.
 */
class BarycentricWeightInt64 implements IHitInt64UV {
    var ax:Float; var ay:Float;
    var v0x:Float; var v0y:Float;
    var v1x:Float; var v1y:Float;
    var d00:Float; var d01:Float;
    var d11:Float;
    var invDenom:Float;

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        this.ax = ax; this.ay = ay;
        this.v0x = (cx : Float) - ax; this.v0y = (cy : Float) - ay;
        this.v1x = (bx : Float) - ax; this.v1y = (by : Float) - ay;
        this.d00 = v0x * v0x + v0y * v0y;
        this.d01 = v0x * v1x + v0y * v1y;
        this.d11 = v1x * v1x + v1y * v1y;
        this.invDenom = 1.0 / (d00 * d11 - d01 * d01);
    }

    public inline function getWeights(x:Int, y:Int):BarycentricResultUV {
        final v2x = (x : Float) - ax;
        final v2y = (y : Float) - ay;
        final d02 = v0x * v2x + v0y * v2y;
        final d12 = v1x * v2x + v1y * v2y;
        final u = (d11 * d02 - d01 * d12) * invDenom;
        final v = (d00 * d12 - d01 * d02) * invDenom;
        final w = 1.0 - u - v;
        return { hit: (u >= 0 && v >= 0 && w >= 0), u: u, v: v, w: w };
    }
}
