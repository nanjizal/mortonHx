package mortonHx;

import haxe.Int64;

#if cpp
import cpp.Struct;
// Specific struct for Int64 to ensure correct C++ headers
@:struct
class SortPair64 {
    public var val:Int64;
    public var originalIndex:Int;
    public function new(v:Int64, i:Int) {
        this.val = v;
        this.originalIndex = i;
    }
}
#end

/**
 * Specifically for Int64 based types (Morton2Di64, Morton3Di64, etc.)
 */
abstract SortableArray64(Array<Int64>) from Array<Int64> to Array<Int64> {
    public inline function new(a:Array<Int64>) {
        this = a;
    }

    public function sortWithOrder(f:(Int64, Int64) -> Int):Array<Int> {
        var len = this.length;
        var order = new Array<Int>();

        #if cpp
        var pairs = new Array<SortPair64>();
        for (i in 0...len) pairs.push(new SortPair64(this[i], i));
        
        pairs.sort((a, b) -> f(a.val, b.val));

        for (i in 0...len) {
            this[i] = pairs[i].val;
            order.push(pairs[i].originalIndex);
        }

        #else
        order = [for (i in 0...len) i];
        
        // Sorting the index map based on Int64 comparison
        order.sort((idxA, idxB) -> f(this[idxA], this[idxB]));
        
        var temp = this.copy();
        for (i in 0...len) {
            this[i] = temp[order[i]];
        }
        #end

        return order;
    }

    /**
     * Binary search using Int64 comparison logic.
     */
    public function findStartIndex(target:Int64):Int {
        var low:Int = 0;
        var high:Int = this.length;

        // Initialize to default values for Null Safety
        var mid:Int = 0; 
        var v:Int64 = Int64.ofInt(0); 

        while (low < high) {
            mid = (low + high) >>> 1; 
            v = this[mid];
            
            // Explicit cast ensures we use the correct operator 
            // even when dealing with Morton abstracts.
            if ((v : Int64) < (target : Int64)) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }
}
