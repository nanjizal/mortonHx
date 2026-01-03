package mortonHx;
class Writer {
    public var v:( get_v, null ): Int;
    public inline function get_v(): Int {
        return xy;
    }
    var xy: Int = 0;
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
