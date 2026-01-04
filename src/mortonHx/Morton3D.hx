package mortonHx;

@:structInit
class Point3DInt_ {
    public var x: Int;
    public var y: Int;
    public var z: Int;
    public inline function new( x: Int, y: Int, z: Int ){
        this.x = x;
        this.y = y;
        this.z = z;
    }
}
@:forward
abstract Point3DInt( Point3DInt_ ) from Point3DInt_ to Point3DInt_ {
    public inline function new( x: Int, y: Int, z: Int ){
        this = new Point3DInt_( x, y, z );
    }
    @:to
    public inline function toMorton3D(): Morton3D {
        return new Morton3D( this.x, this.y, this.z );
    }
}
abstract Morton3D(Int) from Int to Int {
    // Max value for 10 bits is 1023
    public static inline var maxCoord = 1023; 
    
    // Bitmask code for addition and subtraction //
    // 3D bitmasks for 32-bit integers (10 bits per dimension)
    // x: bits 0, 3, 6, 9...
    static inline var maskX3d:Int = 0x09249249; 
    // y: bits 1, 4, 7, 10...
    static inline var maskY3d:Int = 0x12492492;
    // z: bits 2, 5, 8, 11...
    static inline var maskZ3d:Int = 0x24924924;
    // Negated masks to set "guard bits" for borrow handling
    static inline var maskNotX3d:Int = ~0x09249249;
    static inline var maskNotY3d:Int = ~0x12492492;
    static inline var maskNotZ3d:Int = ~0x24924924;

    public inline function new( x: Int, y: Int, z: Int ) {
        // Interleave: z in bits 2, 5, 8... y in 1, 4, 7... x in 0, 3, 6...
        this = (part1By2(z) << 2) | (part1By2(y) << 1) | part1By2(x);
    }

    // Spreads 10 bits into 30 bits (leaving 2 empty spaces between bits)
    inline function part1By2(v:Int):Int {
        v &= 0x000003ff;                  // xxxxxxxxxx (10 bits)
        v = (v | (v << 16)) & 0x030000ff; // x......x........xxxxxx
        v = (v | (v << 8))  & 0x0300f00f; // x......x....xxxx....xxxx
        v = (v | (v << 4))  & 0x030c30c3; // x....xx....xx....xx....xx
        v = (v | (v << 2))  & 0x09249249; // x..x..x..x..x..x..x..x..x..x
        return v;
    }

    public inline function decode(): Point3DInt {
        return new Point3DInt( 
            compact1By2( this ), 
            compact1By2( this >> 1 ), 
            compact1By2( this >> 2 ) 
        );
    }

    // Compresses bits by removing 2 spaces between bits
    inline function compact1By2(v:Int):Int {
        v &= 0x09249249;
        v = (v | (v >> 2)) & 0x030c30c3;
        v = (v | (v >> 4)) & 0x0300f00f;
        v = (v | (v >> 8)) & 0x030000ff;
        v = (v | (v >> 16)) & 0x000003ff;
        return v;
    }
 
     /**
      * Overloading the '+' operator.
      */
      @:op(A + B)
      public static inline function add(base:Morton3D, offset:Morton3D):Morton3D {
          return (
              ((base:Int) & maskX3d) + ((offset:Int) & maskX3d) |
              ((base:Int) & maskY3d) + ((offset:Int) & maskY3d) |
              ((base:Int) & maskZ3d) + ((offset:Int) & maskZ3d)
              : Morton3D
          );
      }
      /**
     * Overloading the '-' operator allows you to use `codeA - codeB` 
     * where both are Morton3D types.
     */
      @:op(A - B)
      public static inline function subtract(base:Morton3D, offset:Morton3D):Morton3D {
          return (
              ((base:Int) | maskNotX3d) - ((offset:Int) & maskX3d) |
              ((base:Int) | maskNotY3d) - ((offset:Int) & maskY3d) |
              ((base:Int) | maskNotZ3d) - ((offset:Int) & maskZ3d)
              : Morton3D
          );
      }
}