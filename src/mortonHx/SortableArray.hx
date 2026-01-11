package mortonHx;
import mortonHx.PointHit;
#if cpp
import cpp.Struct;
// Contiguous memory struct: Fastest for C++ (Zero-GC pressure)
@:struct
class SortPair<T> {
    public var val:T;
    public var originalIndex:Int;
    public function new(v:T, i:Int) {
        this.val = v;
        this.originalIndex = i;
    }
}
#end

abstract SortableArray<T:Float>(Array<T>) from Array<T> to Array<T> {
    public inline function new(a: Array<T>) {
        this = a;
    }

    // Fixed: Specify that we are returning an Array of indices (Int)
    public inline function assending(): Array<Int> {
        return sortWithOrder(( a, b ) -> {
            if(a < b) return -1;
            if(a > b) return 1;
            return 0;
        });
    }

    public inline function sortWithOrder( f: (T, T) -> Int ): Array<Int> {
        var len = this.length;
        var order = new Array<Int>();

        #if cpp
        // C++ Struct optimization for zero-GC pressure
        var pairs = new Array<SortPair<T>>();
        for ( i in 0...len ) pairs.push(new SortPair( this[ i ], i ));
        
        pairs.sort(( a, b ) -> f( a.val, b.val ));

        for ( i in 0...len ) {
            this[ i ] = pairs[ i ].val;
            order.push(pairs[ i ].originalIndex);
        }
        #else
        order = [for ( i in 0...len ) i];
        order.sort(( idxA, idxB ) -> f( this[ idxA ], this[ idxB ] ));
        
        var temp = this.copy();
        for ( i in 0...len ) {
            this[ i ] = temp[ order[ i ] ];
        }
        #end

        return order;
    }

    // findStartIndex and findEndIndex remain the same
    public function findStartIndex( target: T ): Int {
        var low: Int = 0;
        var high: Int = this.length;
        while (low < high) {
            var mid: Int = (low + high) >>> 1; 
            if(this[ mid ] < target) low = mid + 1;
            else high = mid;
        }
        return low;
    }

    public function findEndIndexFrom( target: T, startLow: Int ): Int {
        var low: Int = startLow;
        var high: Int = this.length;
        while (low < high) {
            var mid: Int = (low + high) >>> 1; 
            if(this[ mid ] <= target) low = mid + 1;
            else high = mid;
        }
        return low;
    }
}
