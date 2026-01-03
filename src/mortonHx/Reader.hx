import mortonHx.Writer;
public class Reader {
  var x: Int = 0; 
  var y: Int = 0;
  public static inline function fromWriter( v: Writer ): Reader {
    return fromWriterXY( morton.x, morton.y );
  }
  public static inline function fromWriterXY( morton: Int ): Reader {
    return new Reader( x, y );
  }
  public inline function new( x: Int, y: Int ){
    x = compact1By1( morton );
    y = compact1By1( morton >> 1 );
  }
  function inline compact1By1(j:Int):Int {
    j &= 0x55555555;
    j = (j ^ (j >> 1)) & 0x33333333;
    j = (j ^ (j >> 2)) & 0x0f0f0f0f;
    j = (j ^ (j >> 4)) & 0x00ff00ff;
    j = (j ^ (j >> 8)) & 0x0000ffff;
    return j;
  }
}
