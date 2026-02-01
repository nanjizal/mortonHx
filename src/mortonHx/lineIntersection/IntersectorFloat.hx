package mortonHx.lineIntersection;

@:structInit
@:nativeGen
class Point2DFloat_ {
    public var x: Float;
    public var y: Float;
    public inline function new( x: Float, y: Float ){
        this.x = x;
        this.y = y;
    }
}
/**
 * Stateful intersector for Float coordinates using Point2DFloat_.
 */
 /**
 * Base Abstract Class for Float-based Intersectors.
 */
@:nativeGen
abstract class BaseIntersectorFloat {
    public final a1x:Float;
    public final a1y:Float;
    public final s1x:Float;
    public final s1y:Float;

    public function new(x1:Float, y1:Float, x2:Float, y2:Float) {
        this.a1x = x1;
        this.a1y = y1;
        this.s1x = x2 - x1;
        this.s1y = y2 - y1;
    }

    public abstract function check(b1x:Float, b1y:Float, b2x:Float, b2y:Float):Null<Point2DFloat_>;

    private inline function finalize(num:Float, den:Float):Point2DFloat_ {
        var t = num / den;
        return new Point2DFloat_(a1x + t * s1x, a1y + t * s1y);
    }
}

/**
 * STRATEGY 1: Franklin Antonio (FA)
 * The fastest "Early Exit" strategy. Highly recommended for 2026 triangulation.
 */
@:nativeGen
class IntersectorFloatFA extends BaseIntersectorFloat {
    public function check(b1x:Float, b1y:Float, b2x:Float, b2y:Float):Null<Point2DFloat_> {
        // Broad Phase AABB
        if (s1x > 0) { if (b1x > (a1x+s1x) && b2x > (a1x+s1x) || b1x < a1x && b2x < a1x) return null; }
        else { if (b1x > a1x && b2x > a1x || b1x < (a1x+s1x) && b2x < (a1x+s1x)) return null; }
        
        if (s1y > 0) { if (b1y > (a1y+s1y) && b2y > (a1y+s1y) || b1y < a1y && b2y < a1y) return null; }
        else { if (b1y > a1y && b2y > a1y || b1y < (a1y+s1y) && b2y < (a1y+s1y)) return null; }

        var bx = b1x - b2x, by = b1y - b2y;
        var cx = a1x - b1x, cy = a1y - b1y;

        var den = s1y * bx - s1x * by;
        if (Math.abs(den) < 0.00000001) return null;

        var alphaNum = by * cx - bx * cy;
        var betaNum = s1x * cy - s1y * cx;

        if (den > 0) {
            if (alphaNum < 0 || alphaNum > den || betaNum < 0 || betaNum > den) return null;
        } else {
            if (alphaNum > 0 || alphaNum < den || betaNum > 0 || betaNum < den) return null;
        }

        return finalize(alphaNum, den);
    }
}

/**
 * STRATEGY 2: Gareth Rees (Parametric)
 * Standard parametric interpolation.
 */
@:nativeGen
class IntersectorFloatGareth extends BaseIntersectorFloat {
    public function check( b1x: Float, b1y: Float
                         , b2x: Float, b2y: Float ): Null<Point2DFloat_> {
        var s2x = b2x - b1x, s2y = b2y - b1y;
        var den = (-s2x * s1y + s1x * s2y);
        if (Math.abs(den) < 0.00000001) return null;

        var s = (-s1y * (a1x - b1x) + s1x * (a1y - b1y)) / den;
        var t = (s2x * (a1y - b1y) - s2y * (a1x - b1x)) / den;

        if (s >= 0 && s <= 1 && t >= 0 && t <= 1) return finalize(t * den, den);
        return null;
    }
}

/**
 * STRATEGY 3: Cramer's Rule (Cartesian)
 * General linear solver based on hxPolyK logic.
 */
@:nativeGen
class IntersectorFloatCramer extends BaseIntersectorFloat {
    public function check(b1x:Float, b1y:Float, b2x:Float, b2y:Float):Null<Point2DFloat_> {
        var dax = -s1x, day = -s1y;
        var dbx = b1x - b2x, dby = b1y - b2y;
        var det = dax * dby - day * dbx;
        if (Math.abs(det) < 0.00000001) return null;

        var A = a1x * (a1y + s1y) - a1y * (a1x + s1x);
        var B = b1x * b2y - b1y * b2x;
        
        var ix = (A * dbx - dax * B) / det;
        var iy = (A * dby - day * B) / det;

        if (inRect(ix, iy, b1x, b1y, b2x, b2y)) {
            return new Point2DFloat_(ix, iy);
        }
        return null;
    }

    private inline function inRect(px:Float, py:Float, x1:Float, y1:Float, x2:Float, y2:Float):Bool {
        var eps = 0.000001;
        // Optimization trick: avoids separate min/max checks
        return (px - x1) * (px - x2) <= eps && (py - y1) * (py - y2) <= eps;
    }
}