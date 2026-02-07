package mortonHx.lineIntersection;

import mortonHx.ds.Vertex2i;
import mortonHx.ds.EdgeData;
import mortonHx.lineIntersection.IntersectorVertexBetweenEdges;
/**
 * Optimized Active Edge List Manager.
 */
@:forward(length, push, splice, indexOf)
abstract ActiveEdgeManager( EdgeData<Int> ) from EdgeData<Int> to EdgeData<Int> {
    // Using a shared intersector for this specific AEL instance
    // We store it as a static for speed, but reset it or keep it per-thread
    public static var intersector = new IntersectorVertexBetweenEdges();
    public inline function new() {
        this = new EdgeData<Int>([]);
    }
    /**
     * Adds an edge while maintaining vertical sort order.
     */
    public function addVertexSorted( vStart: Vertex2i<Int>, newEdge: Edge<Int> ): Void {
        var low = 0;
        var high = this.length - 1;
        while( low <= high ) {
            var mid = (low + high) >> 1;
            // Use the internal static intersector
            var state = intersector.check( vStart, this.getEdge( mid ) );
            if( state == ABOVE) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        this.insertEdge( low, newEdge );
    }
    /**
     * Returns the index of the edge immediately ABOVE the vertex.
     * Use this to find the 'floor' and 'ceiling' of a hole.
     */
    public function findSandwichIndex( vHole: Vertex2i<Int> ): Int {
        var low = 0;
        var high = this.edgeLength;
        while( low <= high ){
            var mid = ( low + high ) >> 1;
            var state = intersector.check( vHole, this.getEdge( mid ) );
            ( state == ABOVE )? low = mid + 1: high = mid - 1;
        }
        return low; 
    }
    public function findBridgeEdge( vHole: Vertex2i<Int> ): Null<Edge<Int>> {
        var idx = findSandwichIndex( vHole );
        // We look at the edge immediately ABOVE (idx)
        // In a standard east-sweep, this is usually the safest bridge.
        if (idx < this.edgeLength) return this.getEdge( idx );
        // If no edge above, bridge to the one immediately BELOW
        if (idx > 0) return this.getEdge( idx - 1 );
        return null; // Should not happen in a valid polygon
    }
}