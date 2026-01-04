package mortonHx;
import mortonHx.Reader;
import mortonHx.Writer;

abstract IntScale from Int to Int {
    public inline function new( v: Int ){
        this = v;
    }
    final scaler = 32767;
    /*public inline static function fromFloatXY( x: Float, y: Float, wid: Float, hi: Float ): Writer {
        var scaleX = scalar/wid;
        var scaleY = scalar/hi;
        return new Writer( Std.int( x * scaleX ), Std.int( y * scaleY ) );
    }
*/
    public inline static function toFloatXY( v: j, wid: Float, hi: Float ): Int {
        var out = new Reader( v );
        var scaleX = wid*scaler;
        var scaleY = hi*scalar;
        return { x: out.x * scaleX , y: out.y * scaleY };
    }
}
