package mortonHx.ds;

@:structInit
@:nativeGen
@:generic
class Vertex3i_<T:Float> {
    public var x:T;
    public var y:T;
    public var z:T;
    public function new(x:T, y:T, z:T) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}
@:transitive
@:forward
abstract Vertex3i<T:Float>( Vertex3i_<T> ) from Vertex3i_<T> to Vertex3i_<T>{
    public inline function new( x: T, y: T, z: T ){
        this = new Vertex3i_<T>( x, y, z );
    } 
    @:to public inline function toString():String {
        return 'Vertex(${this.x}, ${this.y},${this.z})';
    }
    public inline function clone():Vertex3i<T> {
        return new Vertex3i<T>(this.x, this.y, this.z);
    }
}