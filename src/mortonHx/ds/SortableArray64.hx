package mortonHx.ds;

import haxe.Int64;

#if cpp
#if (haxe_ver >= 4.0) @:struct #end
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
 * Cross-version compatible SortableArray for 64-bit integers.
 * Works with Haxe 3.4+, 4.x, and 5.x.
 */
abstract SortableArray64(Array<Int64>) from Array<Int64> to Array<Int64> {
    
    public inline function new(a:Array<Int64>) {
        this = a;
    }

    /**
     * Helper to sort the array in ascending order and return the index map.
     */
    public inline function assending(): Array<Int> {
        return sortWithOrder(function(a, b) {
            if ((a : Int64) < (b : Int64)) return -1;
            if ((a : Int64) > (b : Int64)) return 1;
            return 0;
        });
    }

    public function sortWithOrder(f:(Int64, Int64) -> Int):Array<Int> {
        var len = this.length;
        var order:Array<Int> = [];

        #if cpp
        var pairs = new Array<SortPair64>();
        for (i in 0...len) {
            pairs.push(new SortPair64(this[i], i));
        }
        
        pairs.sort(function(a, b) return f(a.val, b.val));

        for (i in 0...len) {
            this[i] = pairs[i].val;
            order.push(pairs[i].originalIndex);
        }

        #else
        for (i in 0...len) order.push(i);
        
        order.sort(function(idxA, idxB) return f(this[idxA], this[idxB]));
        
        var temp = this.copy();
        for (i in 0...len) {
            this[i] = temp[order[i]];
        }
        #end

        return order;
    }

    /**
     * Binary search for the first index where arr[index] >= target.
     */
    public function findStartIndex(target:Int64):Int {
        var low:Int = 0;
        var high:Int = this.length;
        var mid:Int = 0;
        var v:Int64 = Int64.make(0, 0); 

        while (low < high) {
            mid = (low + high) >>> 1; 
            v = this[mid];
            if ((v : Int64) < (target : Int64)) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }

    /**
     * Binary search for the first index where arr[index] > target.
     */
    public function findEndIndex(target:Int64):Int {
        var low:Int = 0;
        var high:Int = this.length;
        var mid:Int = 0;
        var v:Int64 = Int64.make(0, 0); 

        while (low < high) {
            mid = (low + high) >>> 1;
            v = this[mid];
            if ((v : Int64) <= (target : Int64)) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }
}
