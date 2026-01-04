package mortonHx;
@:structInit
class Point2DInt_ {
    public var x: Int;
    public var y: Int;
    public inline function new( x: Int, y: Int ){
        this.x = x;
        this.y = y;
    }
}
@:forward
abstract Point2DInt( Point2DInt_ ) from Point2DInt_ to Point2DInt_ {
    public inline function new( x: Int, y: Int ){
        this = new Point2DInt_( x, y );
    }
    @:to
    public inline function toMordon2D(): Morton2D {
        return new Morton2D( this.x, this.y );
    }
    @:from
    public static inline function fromMordon2D( morton2d: Morton2D ):Point2DInt {
        return morton2d.decode();
    }
}
abstract Morton2D(Int) from Int to Int {
    public static inline var size = 32767;
    public inline function new( x: Int, y: Int ): Int {
        this = ( part1By1( y ) << 1 ) | part1By1( x );
    }
    inline function part1By1(v:Int):Int {
        v &= 0x0000ffff;
        v = (v ^ (v << 8)) & 0x00ff00ff;
        v = (v ^ (v << 4)) & 0x0f0f0f0f;
        v = (v ^ (v << 2)) & 0x33333333;
        v = (v ^ (v << 1)) & 0x55555555;
        return v;
    }
    public inline function decode(): Point2DInt {
        return new Point2DInt( compact1By1( this ), compact1By1( this >> 1 ) );
    }
    public inline function compact1By1( j: Int ): Int {
        j &= 0x55555555;
        j = (j ^ (j >> 1)) & 0x33333333;
        j = (j ^ (j >> 2)) & 0x0f0f0f0f;
        j = (j ^ (j >> 4)) & 0x00ff00ff;
        j = (j ^ (j >> 8)) & 0x0000ffff;
        return j;
    }
}