package mortonHx;

/**
 * Interface for Integer-based hit testing.
 */
 interface IHitInt {
    function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void;
    function hitCheck(x:Int, y:Int):Bool;
}

/**
 * Interface for Float-based hit testing.
 */
interface IHitFloat {
    function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void;
    function hitCheck(x:Float, y:Float):Bool;
}

/**
 * OPTIMIZED: BarycentricHitInt
 * Uses pure integer math to avoid costly Float promotion and division.
 */
class BarycentricHitInt implements IHitInt {
    var ax:Int; var ay:Int;
    var v0x:Int; var v0y:Int;
    var v1x:Int; var v1y:Int;
    var d00:Int; var d01:Int;
    var d11:Int;
    var denom:Int; // Stores raw integer denominator

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        this.ax = ax; this.ay = ay;
        this.v0x = cx - ax; this.v0y = cy - ay;
        this.v1x = bx - ax; this.v1y = by - ay;
        this.d00 = v0x * v0x + v0y * v0y;
        this.d01 = v0x * v1x + v0y * v1y;
        this.d11 = v1x * v1x + v1y * v1y;
        this.denom = (d00 * d11 - d01 * d01);
    }

    public inline function hitCheck(x:Int, y:Int):Bool {
        final v2x = x - ax;
        final v2y = y - ay;
        final d02 = v0x * v2x + v0y * v2y;
        final d12 = v1x * v2x + v1y * v2y;

        // Calculate unscaled u/v numerators
        final uNum = d11 * d02 - d01 * d12;
        final vNum = d00 * d12 - d01 * d02;

        // Check against 0 and the raw denominator (avoids division)
        if (denom >= 0) {
            return (uNum >= 0) && (vNum >= 0) && (uNum + vNum <= denom);
        } else {
            return (uNum <= 0) && (vNum <= 0) && (uNum + vNum >= denom);
        }
    }
}

/**
 * BarycentricHitFloat
 * Standard barycentric logic for high-precision floating point targets.
 */
class BarycentricHitFloat implements IHitFloat {
    var ax:Float; var ay:Float;
    var v0x:Float; var v0y:Float;
    var v1x:Float; var v1y:Float;
    var d00:Float; var d01:Float;
    var d11:Float;
    var invDenom:Float;

    public function new() {}

    public inline function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void {
        this.ax = ax; this.ay = ay;
        this.v0x = cx - ax; this.v0y = cy - ay;
        this.v1x = bx - ax; this.v1y = by - ay;
        this.d00 = v0x * v0x + v0y * v0y;
        this.d01 = v0x * v1x + v0y * v1y;
        this.d11 = v1x * v1x + v1y * v1y;
        this.invDenom = 1.0 / (d00 * d11 - d01 * d01);
    }

    public inline function hitCheck(x:Float, y:Float):Bool {
        final v2x = x - ax; final v2y = y - ay;
        final d02 = v0x * v2x + v0y * v2y;
        final d12 = v1x * v2x + v1y * v2y;
        final u = (d11 * d02 - d01 * d12) * invDenom;
        final v = (d00 * d12 - d01 * d02) * invDenom;
        return (u >= 0) && (v >= 0) && (u + v < 1);
    }
}

/**
 * EdgeFunctionHitInt
 * Uses the bitwise XOR trick for fast sign comparison on integer targets.
 */
class EdgeFunctionHitInt implements IHitInt {
    var a1:Int; var b1:Int; var c1:Int;
    var a2:Int; var b2:Int; var c2:Int;
    var a3:Int; var b3:Int; var c3:Int;

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        a1 = ay - by; b1 = bx - ax; c1 = ax * by - ay * bx;
        a2 = by - cy; b2 = cx - bx; c2 = bx * cy - by * cx;
        a3 = cy - ay; b3 = ax - cx; c3 = cx * ay - cy * ax;
    }

    public inline function hitCheck(x:Int, y:Int):Bool {
        final s1 = a1 * x + b1 * y + c1;
        final s2 = a2 * x + b2 * y + c2;
        if ((s1 ^ s2) < 0) return false; // Early exit if signs differ
        final s3 = a3 * x + b3 * y + c3;
        return (s1 ^ s3) >= 0;
    }
}

/**
 * EdgeFunctionHitFloat
 * Standard edge function sign check for floats.
 */
class EdgeFunctionHitFloat implements IHitFloat {
    var a1:Float; var b1:Float; var c1:Float;
    var a2:Float; var b2:Float; var c2:Float;
    var a3:Float; var b3:Float; var c3:Float;

    public function new() {}

    public inline function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void {
        a1 = ay - by; b1 = bx - ax; c1 = ax * by - ay * bx;
        a2 = by - cy; b2 = cx - bx; c2 = bx * cy - by * cx;
        a3 = cy - ay; b3 = ax - cx; c3 = cx * ay - cy * ax;
    }

    public inline function hitCheck(x:Float, y:Float):Bool {
        final s1 = a1 * x + b1 * y + c1;
        final s2 = a2 * x + b2 * y + c2;
        final s3 = a3 * x + b3 * y + c3;
        return (s1 >= 0 && s2 >= 0 && s3 >= 0) || (s1 <= 0 && s2 <= 0 && s3 <= 0);
    }
}
/**
 * Same Side
 */
class SameSideHitInt implements IHitInt {
    // Vectors for edges
    var abx:Int; var aby:Int;
    var bcx:Int; var bcy:Int;
    var cax:Int; var cay:Int;
    
    // Triangle vertices
    var ax:Int; var ay:Int;
    var bx:Int; var by:Int;
    var cx:Int; var cy:Int;
    
    // Pre-calculated signs for each vertex vs opposite edge
    var signA:Int; var signB:Int; var signC:Int;

    public function new() {}

    public inline function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        this.ax = ax; this.ay = ay;
        this.bx = bx; this.by = by;
        this.cx = cx; this.cy = cy;

        this.abx = bx - ax; this.aby = by - ay;
        this.bcx = cx - bx; this.bcy = cy - by;
        this.cax = ax - cx; this.cay = ay - cy;

        // Cross product of edge and vector to opposite vertex
        // Use signA to determine which side point P must be on relative to edge BC
        signA = (cx - bx) * (ay - by) - (cy - by) * (ax - bx);
        signB = (ax - cx) * (by - cy) - (ay - cy) * (bx - cx);
        signC = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    }

    public inline function hitCheck(x:Int, y:Int):Bool {
        // Check side relative to BC (vs A)
        final cpA = (cx - bx) * (y - by) - (cy - by) * (x - bx);
        if ((cpA ^ signA) < 0) return false;

        // Check side relative to CA (vs B)
        final cpB = (ax - cx) * (y - cy) - (ay - cy) * (x - cx);
        if ((cpB ^ signB) < 0) return false;

        // Check side relative to AB (vs C)
        final cpC = (bx - ax) * (y - ay) - (by - ay) * (x - ax);
        return (cpC ^ signC) >= 0;
    }
}
class SameSideHitFloat implements IHitFloat {
    var ax:Float; var ay:Float;
    var bx:Float; var by:Float;
    var cx:Float; var cy:Float;
    
    var signA:Float; var signB:Float; var signC:Float;

    public function new() {}

    public inline function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void {
        this.ax = ax; this.ay = ay;
        this.bx = bx; this.by = by;
        this.cx = cx; this.cy = cy;

        // Pre-calculate reference signs
        signA = (cx - bx) * (ay - by) - (cy - by) * (ax - bx);
        signB = (ax - cx) * (by - cy) - (ay - cy) * (bx - cx);
        signC = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    }

    public inline function hitCheck(x:Float, y:Float):Bool {
        // Point P must be on the same side of edge BC as vertex A
        if (((cx - bx) * (y - by) - (cy - by) * (x - bx)) * signA < 0) return false;
        // Same for other edges
        if (((ax - cx) * (y - cy) - (ay - cy) * (x - cx)) * signB < 0) return false;
        if (((bx - ax) * (y - ay) - (by - ay) * (x - ax)) * signC < 0) return false;

        return true;
    }
}

/**
 * @:struct ensures stack-allocation (no GC) on C++.
 * @:structInit allows clean initialization syntax on HashLink/other targets.
 */
 #if cpp
 @:struct
 #end
 @:structInit
 class BarycentricResult {
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
// --- UV / WEIGHT INTERFACES ---
 interface IHitIntUV {
     function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void;
     function getWeights(x:Int, y:Int):BarycentricResult;
 }
 interface IHitFloatUV {
     function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void;
     function getWeights(x:Float, y:Float):BarycentricResult;
 }
// --- UV SPECIALIZED IMPLEMENTATIONS (With Weight Output) ---
 class BarycentricHitFloatUVearlyExit implements IHitFloatUV {
    var ax:Float; var ay:Float;
    var v0x:Float; var v1x:Float;
    var v0y:Float; var v1y:Float;
    var d00:Float; var d01:Float; var d11:Float;
    var invDenom:Float;
    var denom:Float; // Stored to avoid division in the loop

    public function new() {}

    public function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void {
        this.ax = ax; this.ay = ay;
        this.v0x = cx - ax; this.v0y = cy - ay;
        this.v1x = bx - ax; this.v1y = by - ay;
        this.d00 = v0x * v0x + v0y * v0y;
        this.d01 = v0x * v1x + v0y * v1y;
        this.d11 = v1x * v1x + v1y * v1y;
        
        this.denom = d00 * d11 - d01 * d01;
        this.invDenom = 1.0 / this.denom;
    }

    public inline function getWeights(x:Float, y:Float):BarycentricResult {
        final v2x = x - ax;
        final v2y = y - ay;
        
        final d02 = v0x * v2x + v0y * v2y;
        final d12 = v1x * v2x + v1y * v2y;

        // Calculate unscaled uNum
        final uNum = d11 * d02 - d01 * d12;

        // Early Exit 1: Check uNum bounds
        // If denom is positive, uNum must be between 0 and denom
        if (uNum < 0 || uNum > denom) return new BarycentricResult(false, 0, 0, 0);

        final vNum = d00 * d12 - d01 * d02;

        // Early Exit 2: Check vNum and combined bounds
        if (vNum < 0 || (uNum + vNum) > denom) {
            return new BarycentricResult(false, 0, 0, 0);
        }

        // Final calculations only occur if the point is inside
        final u = uNum * invDenom;
        final v = vNum * invDenom;
        final w = 1.0 - u - v;

        return new BarycentricResult(true, u, v, w);
    }
}

class BarycentricHitIntUVearlyExit implements IHitIntUV {
    var ax:Int; var ay:Int;
    var v0x:Int; var v1x:Int;
    var v0y:Int; var v1y:Int;
    var d00:Float; var d01:Float; var d11:Float;
    var invDenom:Float;
    var denom:Float;

    public function new() {}

    public function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
        this.ax = ax; this.ay = ay;
        this.v0x = cx - ax; this.v0y = cy - ay;
        this.v1x = bx - ax; this.v1y = by - ay;
        // Float promotion prevents 32-bit overflow on large coordinates
        this.d00 = (cast v0x:Float) * v0x + (cast v0y:Float) * v0y;
        this.d01 = (cast v0x:Float) * v1x + (cast v0y:Float) * v1y;
        this.d11 = (cast v1x:Float) * v1x + (cast v1y:Float) * v1y;
        
        this.denom = d00 * d11 - d01 * d01;
        this.invDenom = 1.0 / this.denom;
    }

    public inline function getWeights(x:Int, y:Int):BarycentricResult {
        final v2x = x - ax; final v2y = y - ay;
        
        final d02 = (cast v0x:Float) * v2x + (cast v0y:Float) * v2y;
        final d12 = (cast v1x:Float) * v2x + (cast v1y:Float) * v2y;

        final uNum = d11 * d02 - d01 * d12;
        if (uNum < 0 || uNum > denom) return new BarycentricResult(false, 0, 0, 0);

        final vNum = d00 * d12 - d01 * d02;
        if (vNum < 0 || (uNum + vNum) > denom) return new BarycentricResult(false, 0, 0, 0);

        final u = uNum * invDenom;
        final v = vNum * invDenom;
        final w = 1.0 - u - v;

        return new BarycentricResult(true, u, v, w);
    }
}



 // --- UV SPECIALIZED IMPLEMENTATIONS (With Weight Output) ---
 class BarycentricHitIntUV implements IHitIntUV {
     var ax:Int; var ay:Int;
     var v0x:Int; var v0y:Int;
     var v1x:Int; var v1y:Int;
     var d00:Float; var d01:Float; var d11:Float;
     var invDenom:Float;
 
     public function new() {}
 
     public function prepare(ax:Int, ay:Int, bx:Int, by:Int, cx:Int, cy:Int):Void {
         this.ax = ax; this.ay = ay;
         this.v0x = cx - ax; this.v0y = cy - ay;
         this.v1x = bx - ax; this.v1y = by - ay;
         // Promote to Float early for dot products to prevent overflow on large coordinates
         this.d00 = (cast v0x:Float) * v0x + (cast v0y:Float) * v0y;
         this.d01 = (cast v0x:Float) * v1x + (cast v0y:Float) * v1y;
         this.d11 = (cast v1x:Float) * v1x + (cast v1y:Float) * v1y;
         this.invDenom = 1.0 / (d00 * d11 - d01 * d01);
     }
 
     public inline function getWeights(x:Int, y:Int):BarycentricResult {
         final v2x = x - ax; final v2y = y - ay;
         final d02 = (cast v0x:Float) * v2x + (cast v0y:Float) * v2y;
         final d12 = (cast v1x:Float) * v2x + (cast v1y:Float) * v2y;
         final u = (d11 * d02 - d01 * d12) * invDenom;
         final v = (d00 * d12 - d01 * d02) * invDenom;
         final w = 1.0 - u - v;
         return new BarycentricResult((u >= 0) && (v >= 0) && (w >= 0), u, v, w);
     }
 }
 
 class BarycentricHitFloatUV implements IHitFloatUV {
     var ax:Float; var ay:Float;
     var v0x:Float; var v0y:Float;
     var v1x:Float; var v1y:Float;
     var d00:Float; var d01:Float; var d11:Float;
     var invDenom:Float;
 
     public function new() {}
 
     public function prepare(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Void {
         this.ax = ax; this.ay = ay;
         this.v0x = cx - ax; this.v0y = cy - ay;
         this.v1x = bx - ax; this.v1y = by - ay;
         this.d00 = v0x * v0x + v0y * v0y;
         this.d01 = v0x * v1x + v0y * v1y;
         this.d11 = v1x * v1x + v1y * v1y;
         this.invDenom = 1.0 / (d00 * d11 - d01 * d01);
     }
 
     public inline function getWeights(x:Float, y:Float):BarycentricResult {
         final v2x = x - ax; final v2y = y - ay;
         final d02 = v0x * v2x + v0y * v2y;
         final d12 = v1x * v2x + v1y * v2y;
         final u = (d11 * d02 - d01 * d12) * invDenom;
         final v = (d00 * d12 - d01 * d02) * invDenom;
         final w = 1.0 - u - v;
         return new BarycentricResult((u >= 0) && (v >= 0) && (w >= 0), u, v, w);
     }
 }