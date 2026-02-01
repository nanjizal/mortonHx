package mortonHx.lineIntersection;
//import mortonHx.Morton2D;
import mortonHx.ds.Vertex2i;
 /**
  * Abstract Base for stateful intersectors.  
  * Acting as the 'Interface' for thread-safe triangulation logic.  
  * In relation to expected speed..  
  * 1. Franklin Antonio (IntersectorFA):  
  *    Highest Performance. Excels at quickly rejecting non-intersecting segments.  
  * 2. Gareth Rees (IntersectorGareth):  
  *    High Performance. A very clean, robust parametric solution.  
  *    Slightly slower than FA because it usually performs the division calculation 
  *    earlier in the logic.  
  * 3. Cramer's Rule (IntersectorCramer):  
  *    Standard Performance. ( BROKEN - ISH? )  
  *    It has the most arithmetic operations overall and relies on an inRect check  
  *    making it the slowest of the three optimized versions.  
  */
interface Intersector{
    public function check( b1x: Int, b1y: Int, b2x: Int, b2y: Int ): Null<Vertex2i<Int>>;
    public function distanceSq(): Float;
}
  /*
   * Note: 'use FA for your broad-phase cardinal scans 
   * and Gareth for your high-precision triangle-bridge checks'
  */
@:nativeGen
abstract class BaseIntersector implements Intersector {
    public final a1x: Int;
    public final a1y: Int;
    public final s1x: Int;
    public final s1y: Int;
    public final dist: Float;
    public function new( x1: Int, y1: Int, x2: Int, y2: Int ) {
        this.a1x = x1;
        this.a1y = y1;
        this.s1x = x2 - x1;
        this.s1y = y2 - y1;
        dist = (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2);
    }

    public function distanceSq(): Float {
        return dist;
    }
    /**
      * Core check method. 
      * Returns a new Vertex2i on hit, or null.
      */
    public abstract function check( b1x: Int, b1y: Int, b2x: Int, b2y: Int ): Null<Vertex2i<Int>>;
 
    /**
      * Shared finalizer to handle result conversion back to Vertex2i.
      */
    private inline function finalizeInt( num: Float, den: Float ): Vertex2i<Int> {
        var t = num / den;
        return new Vertex2i( Std.int( a1x + t * s1x )
                           , Std.int( a1y + t * s1y ) );
    }
    /**
     * Use to allow passing the type of Intersector to use.
     * @param intersector 
     * @param x1 
     * @param y1 
     * @param x2 
     * @param y2 
     * @return Intersector
     */
    public static inline function create( x1: Int, y1: Int, x2: Int, y2: Int, intersector: Null<Class<Intersector>> ):Intersector {
        if( intersector == null ){
            return new IntersectorFA( x1, y1, x2, y2 );
        } else if( intersector == IntersectorFA ){ 
            return new IntersectorFA( x1, y1, x2, y2 );
        } else if( intersector == IntersectorGareth ){
            return new IntersectorGareth( x1, y1, x2, y2 );
        } else if( intersector == IntersectorCramer ){
            return new IntersectorCramer( x1, y1, x2, y2 );
        } else {
            return new IntersectorFA( x1, y1, x2, y2 );
        }
    }
 }
 
 /**
  * Strategy: Franklin Antonio (FA)
  * Best for mass culling of shell edges.
  */
 @:nativeGen
 class IntersectorFA extends BaseIntersector {
     public function check(b1x:Int, b1y:Int, b2x:Int, b2y:Int):Null<Vertex2i<Int>> {
         // Broad Phase (AABB Culling)
         if (s1x > 0 ) { if (b1x > (a1x+s1x) && b2x > (a1x+s1x) || b1x < a1x && b2x < a1x) return null; }
         else { if (b1x > a1x && b2x > a1x || b1x < (a1x+s1x) && b2x < (a1x+s1x)) return null; }
         
         if (s1y > 0) { if (b1y > (a1y+s1y) && b2y > (a1y+s1y) || b1y < a1y && b2y < a1y) return null; }
         else { if (b1y > a1y && b2y > a1y || b1y < (a1y+s1y) && b2y < (a1y+s1y)) return null; }
 
         var bx = b1x - b2x;
         var by = b1y - b2y;
         var cx = a1x - b1x;
         var cy = a1y - b1y;
 
         var den: Float = s1y * bx - s1x * by;
         if (den == 0) return null;
 
         var alphaNum = by * cx - bx * cy;
         var betaNum = s1x * cy - s1y * cx;
 
         if (den > 0) {
             if (alphaNum < 0 || alphaNum > den || betaNum < 0 || betaNum > den) return null;
         } else {
             if (alphaNum > 0 || alphaNum < den || betaNum > 0 || betaNum < den) return null;
         }
 
         return finalizeInt(alphaNum, den);
     }
 }
 
 /**
  * Strategy: Gareth Rees (Parametric)
  */
 @:nativeGen
 class IntersectorGareth extends BaseIntersector {
     public function check(b1x:Int, b1y:Int, b2x:Int, b2y:Int):Null<Vertex2i<Int>> {
         var s2x = b2x - b1x, s2y = b2y - b1y;
         var den = (-s2x * s1y + s1x * s2y);
         if (den == 0.0 ) return null;
 
         var s = (-s1y * (a1x - b1x) + s1x * (a1y - b1y)) / den;
         var t = (s2x * (a1y - b1y) - s2y * (a1x - b1x)) / den;
 
         if (s >= 0 && s <= 1 && t >= 0 && t <= 1) return finalizeInt(t * den, den);
         return null;
     }
 }
 
 /**
  * Strategy: Cramer's Rule (hxPolyK style)
  */
  class IntersectorCramer extends BaseIntersector {
    public function check(b1x:Int, b1y:Int, b2x:Int, b2y:Int):Null<Vertex2i<Int>> {
        var dx2 = b2x - b1x;
        var dy2 = b2y - b1y;

        // The determinant (Cramer's denominator)
        var det = (s1x * dy2 - s1y * dx2);
        
        // Use a 2026-standard epsilon for precision safety
        if (Math.abs(det) < 1e-10) return null; 

        var dx3 = b1x - a1x;
        var dy3 = b1y - a1y;

        // Cramer's Rule to find t (parameter on your segment) 
        // and u (parameter on the target segment)
        var t = (dx3 * dy2 - dy3 * dx2) / det;
        var u = (dx3 * s1y - dy3 * s1x) / det;

        // ONLY if BOTH are between 0 and 1 is it a valid SEGMENT intersection
        if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
            // Now it is safe to use your finalizer
            return finalizeInt(t * det, det);
        }
        
        return null;
    }
}


/*

 @:nativeGen
 class IntersectorCramer extends BaseIntersector {
     public function check(b1x:Int, b1y:Int, b2x:Int, b2y:Int):Null<Vertex2i<Int>> {
         var dax = -s1x, day = -s1y;
         var dbx = b1x - b2x, dby = b1y - b2y;
         var det = dax * dby - day * dbx;
         if (det == 0.0) return null;
 
         var A = a1x * (a1y + s1y) - a1y * (a1x + s1x);
         var B = b1x * b2y - b1y * b2x;
         
         var ix = (A * dbx - dax * B) / det;
         var iy = (A * dby - day * B) / det;
 
         if (inRect(cast ix, cast iy, b1x, b1y, b2x, b2y)) {
             return new Vertex2i(cast ix, cast iy);
         }
         return null;
     }
 
     private inline function inRect(px:Float, py:Float, x1:Int, y1:Int, x2:Int, y2:Int):Bool {
         var eps = 0.000001;
         return (px - x1) * (px - x2) <= eps && (py - y1) * (py - y2) <= eps;
     }
 }
 */


 //
 /*
 The preference for Franklin Antonio (FA) and Gareth Rees 
 over Cramer's Rule in high-performance triangulation like earcut 
 is based on the specific computational needs of different phases 
 of the algorithm. 
 
 1. Why Franklin Antonio (FA) for Broad-Phase? 
 The "Broad-Phase" scan involves checking a single ray 
 (your cardinal scan) against hundreds or thousands of potential 
 shell edges. AABB Culling: FA's algorithm starts with an 
 Axis-Aligned Bounding Box (AABB) test. It uses simple 
 comparisons (e.g., if (b1x > max_x)) to reject intersections 
 without performing any expensive multiplications or divisions.
 Early Exit: In the majority of cases, a ray will not hit an edge. 
 FA allows the CPU to "fail fast," skipping the more complex math 
 for 99% of your data.Arithmetic Efficiency: It avoids division 
 until the very last possible moment, which is critical since division 
 is one of the slowest operations on modern CPUs. 
 
 2. Why Gareth Rees for Triangle-Bridge Checks? 
 Once you've identified a candidate edge, you need to verify if the 
 path is clear to create a "Triangle Bridge." This is a "Narrow-Phase" 
 check where precision is more important than raw culling speed. 
 Parametric Robustness: Gareth Rees's method is built on a parametric 
 model (\(0\le t\le 1\)). 
 This identifies not just if two lines intersect, but exactly where on 
 the segment they hit.Edge-Case Stability: It handles "degenerate" 
 cases—like bridges that are nearly parallel to shell edges—more 
 robustly than simpler methods, preventing earcut from creating 
 overlapping triangles that crash the renderer. 
 
 3. Why discard Cramer's Rule with inRect? Cramer's Rule is a classic 
 algebraic method for solving systems of linear equations. 
 However, its application in 2D geometry for line segments is 
 considered legacy for several reasons: Numerical Instability: 
 Cramer's Rule is notorious for rounding errors and 
 "numerical instability," especially when the determinant is near zero.
  This can cause "fake" solutions or missed intersections in complex 
  polygons.The inRect Fallacy: The inRect check is a secondary geometric
   test used to fix the fact that Cramer's Rule solves for infinite 
   lines, not segments. This two-step process is slower and less 
   precise than the "all-in-one" parametric checks used 
   by FA or Gareth Rees.Redundancy: Any "fixed" version of Cramer's 
   Rule that uses \(t\) and \(u\) parameters to validate segment 
   bounds is mathematically equivalent to the Gareth Rees approach 
   but typically involves more redundant arithmetic operations.
*/