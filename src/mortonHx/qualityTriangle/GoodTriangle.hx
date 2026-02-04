package mortonHx.qualityTriangle;
import mortonHx.ds.Vertex2i;
class GoodTriangle {
    /**
     * Quality Score Reference Table:
     * 
     *    Shape Style      | Shader Impact            | triangleUnitMerit
     *   ------------------|---------------------------------------
     *   Equilateral       | Perfect sampling         |  nearly 1
     *   Right Isosceles   | Very stable              |  0.75
     *   Oblique           | Good                     |  0.5   
     *   Thin Sliver       | Potential Moire/Aliasing |  0.25
     *   Needle/Flat       | High artifact risk       |  0.05 
     *
     */
     public static function triangleUnitMerit( a: Vertex2i<Int>, b: Vertex2i<Int>, c: Vertex2i<Int> ):Float {
        var baX = b.x - a.x;
        var baY = b.y - a.y;
        var caX = c.x - a.x;
        var caY = c.y - a.y;
        var bcX = b.x - c.x;
        var bcY = b.y - c.y;
        var area = baX * caY - baY * caX;
        if (area == 0) return 0; // flat (degenerate)
        var aSq: Float = cast(area, Float) * area; 
        var ba = baX * baX + baY * baY;
        var ca = caX * caX + caY * caY;
        var bc = bcX * bcX + bcY * bcY;
        var sides: Float = cast( ba, Float ) + ca + bc;
        return ( 12 * aSq ) / ( sides * sides );
    }

}
