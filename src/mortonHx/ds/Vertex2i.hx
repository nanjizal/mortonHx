package mortonHx.ds;
/**
 * A 2D Int Vector ( structInit )  
 * instead use {@link mortonHx.ds.Vertex2x} 
 */
@:structInit
@:nativeGen
@:generic
class Vertex2i_<T:Float> {
    public var x:T;
    public var y:T;
    public function new(x:T, y:T) {
        this.x = x;
        this.y = y;
    }
}
/**
 * 2D Vector abstract type.
 * ( @see mortonHx.ds.Vertex2i_ )
 */
@:transitive
@:forward
abstract Vertex2i<T:Float>( Vertex2i_<T> ) from Vertex2i_<T> to Vertex2i_<T>{
    public inline function new( x: T, y: T ){
        this = new Vertex2i_<T>(x,y);
    } 
    @:to public inline function toString():String {
        return 'Vertex(${this.x}, ${this.y})';
    }
    public inline function clone():Vertex2i<T> {
        return new Vertex2i<T>(this.x, this.y);
    }
}