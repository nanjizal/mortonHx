package mortonHx;
#if cpp
@:struct 
#end
@:structInit
class EarNode {
    public var x:Int;
    public var y:Int;
    public var m:Int; // Morton Code
    
    public var prev:EarNode;
    public var next:EarNode;
    
    // The "isReflex" optimization flag
    public var isReflex:Bool; 
}