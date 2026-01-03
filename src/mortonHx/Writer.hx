package mortonHx;
class Writer {
    public var v:( get_v, null ): Int;
    public inline function get_v(): Int {
        return xy;
    }
    var xy: Int = 0;
    final scaler = 32767;
    public inline static function fromFloatXY( x: Float, y: Float, wid: Float, hi: Float ): Int {
        var scaleX = scalar/wid;
        var scaleY = scalar/hi;
        return new Writer( Std.int( x * scaleX ), std.int( y * scaleY ) );
    }
    public inline static function fromFloatXYoffSet( x: Float, y: Float, xOff: Float, yOff: Float, wid: Float, hi: Float ): Int {
        return new fromFloatXY( x - offX, y - offY );
    }
    public inline static function fromFloatX_YoffSet( x: Float, y: Float, xOff: Float, yOff: Float, wid: Float, hi: Float ): Int {
        return new fromFloatXY( x - offX, -(y - offY) );
    }    
    /**
     * Interleaves bits of two 16-bit integers into one 32-bit Morton code.
     */
    public inline function new( x: Int, y: Int ): Int {
        xy = ( part1By1( y ) << 1 ) | part1By1( x );
    }

   inline function part1By1(x:Int):Int {
        xy &= 0x0000ffff;
        xy = (x ^ (x << 8)) & 0x00ff00ff;
        xy = (xy ^ (xy << 4)) & 0x0f0f0f0f;
        xy = (xy ^ (xy << 2)) & 0x33333333;
        xy = (xy ^ (xy << 1)) & 0x55555555;
    }
}
