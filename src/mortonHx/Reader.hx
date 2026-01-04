import mortonHx.Writer;
public class Reader {
  var x: Int = 0; 
  var y: Int = 0;
  final scaler = 32767;
  public static inline function fromWriter( w: Writer ): Reader {
    return new Reader( w.v );
  }
  public inline function new( k: Int ){
    x = compact1By1( k );
    y = compact1By1( k >> 1 );
  }
  function inline compact1By1(j:Int):Int {
    j &= 0x55555555;
    j = (j ^ (j >> 1)) & 0x33333333;
    j = (j ^ (j >> 2)) & 0x0f0f0f0f;
    j = (j ^ (j >> 4)) & 0x00ff00ff;
    j = (j ^ (j >> 8)) & 0x0000ffff;
    return j;
  }
  public inline static function toFloatXY( wid: Float, hi: Float ): Int {
      var scaleX = wid*scaler;
      var scaleY = hi*scalar;
      return { x: x * scaleX , y: y * scaleY };
  }
}
