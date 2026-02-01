package mortonHx.ear;

import haxe.Int64;
import haxe.ds.Vector;
import mortonHx.morton.Morton2Di64;
import mortonHx.pointInTriangle.PointHitInt64;
import mortonHx.ds.SortableArray64;
import mortonHx.ds.EdgeData;
/**
 * On C++, this is a packed struct (contiguous memory).
 * On JS/Flash, it is a standard object with optimized initialization.
 */
#if (cpp || hl)
@:struct 
#end
@:structInit
class EarNodeInt64 {
    public var x: Int;
    public var y: Int;
    public var m64: Int64;
    public var prev: EarNodeInt64;
    public var next: EarNodeInt64;
    public var isReflex: Bool;

    public function new(x: Int, y: Int, m64: Int64, ?isReflex: Bool = false) {
        this.x = x;
        this.y = y;
        this.m64 = m64;
        this.isReflex = isReflex;
    }
}

class EarCutMortonI64 {
    var pointHit: IHitInt64;
    var points: Array<{ x: Int, y: Int }>;
    var sortableArr: SortableArray64;

    public function new(points: Array<{ x: Int, y: Int }>, pointHit: IHitInt64 = null) {
        this.pointHit = (pointHit == null) ? new EdgeFunctionHitInt64() : pointHit;
        if (!isCounterClockwise(points)) points.reverse();
        this.points = points;
        
        var len = points.length;
        var mortonData: Array<Int64> = [];
        #if (haxe_ver >= 4.0) mortonData.resize(len); #end
        
        for (i in 0...len) {
            mortonData[i] = new Morton2Di64(points[i].x, points[i].y);
        }
        
        this.sortableArr = mortonData;
        this.sortableArr.assending(); 
    }

    public function pointsInTriangle(ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int): Bool {
        pointHit.prepare(ax, ay, bx, by, cx, cy);
        
        var v1: Int64 = new Morton2Di64(ax, ay);
        var v2: Int64 = new Morton2Di64(bx, by);
        var v3: Int64 = new Morton2Di64(cx, cy);
        
        var minCode = (v1 < v2) ? ((v1 < v3) ? v1 : v3) : ((v2 < v3) ? v2 : v3);
        var maxCode = (v1 > v2) ? ((v1 > v3) ? v1 : v3) : ((v2 > v3) ? v2 : v3);
        
        var start = sortableArr.findStartIndex(minCode);
        var end = sortableArr.findEndIndex(maxCode);
        
        // Quadtree shared-prefix calculation (once per triangle)
        var diff: Int64 = minCode ^ maxCode;
        var mask: Int64 = Int64.make(0xFFFFFFFF, 0xFFFFFFFF);
        if (diff != 0) {
            var v: Int64 = diff;
            v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16; v |= v >> 32;
            mask = ~v;
        }

        var p: Int64;
        var targetPrefix = v1 & mask;
        
        for (i in start...end) {
            p = sortableArr[i];
            
            // Fast Morton Prefix Filter
            if ((p & mask) != targetPrefix) continue;
            // Vertex identity check
            if (p == v1 || p == v2 || p == v3) continue;
            
            // Precise hit check
            #if cpp
            // Zero-allocation de-interleaving on C++
            if (pointHit.hitCheck(Morton2Di64.decode64(p), Morton2Di64.decode64(p >> 1))) return true;
            #else
            // Standard decode for JS/Flash/Other
            var d = (p : Morton2Di64).decode();
            if (pointHit.hitCheck(d.x, d.y)) return true;
            #end
        }
        return false;
    }

    private function createLinkedList(): EarNodeInt64 {
        var len = points.length;
        var nodes = new Vector<EarNodeInt64>(len);
        
        for (i in 0...len) {
            var px = points[i].x;
            var py = points[i].y;
            nodes[i] = new EarNodeInt64(px, py, new Morton2Di64(px, py));
        }
        
        for (i in 0...len) {
            nodes[i].next = nodes[(i + 1) % len];
            nodes[i].prev = nodes[(i + len - 1) % len];
        }
        return nodes[0];
    }

    public function triangulate(): Array<Int> {
        var current = createLinkedList();
        var indices = [];
        var count = points.length;

        var node = current;
        do {
            node.isReflex = !isConvexFloat(node.prev.x, node.prev.y, node.x, node.y, node.next.x, node.next.y);
            node = node.next;
        } while (node != current);

        var stopNode = current;
        while (count > 3) {
            if (isValidEar(current)) {
                indices.push(current.prev.x); indices.push(current.prev.y);
                indices.push(current.x);      indices.push(current.y);
                indices.push(current.next.x); indices.push(current.next.y);

                current.prev.next = current.next;
                current.next.prev = current.prev;
                
                current.prev.isReflex = !isConvexFloat(current.prev.prev.x, current.prev.prev.y, current.prev.x, current.prev.y, current.prev.next.x, current.prev.next.y);
                current.next.isReflex = !isConvexFloat(current.next.prev.x, current.next.prev.y, current.next.x, current.next.y, current.next.next.x, current.next.next.y);

                current = current.next;
                stopNode = current; 
                count--;
            } else {
                current = current.next;
                if (current == stopNode) break; 
            }
        }
        
        indices.push(current.prev.x); indices.push(current.prev.y);
        indices.push(current.x);      indices.push(current.y);
        indices.push(current.next.x); indices.push(current.next.y);
        
        return indices;
    }

    public inline function isValidEar(ear: EarNodeInt64): Bool {
        if (ear.isReflex) return false;
        return !pointsInTriangle(ear.prev.x, ear.prev.y, ear.x, ear.y, ear.next.x, ear.next.y);
    }

    public static inline function isConvexFloat(ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int): Bool {
        return ((cast(bx - ax, Float) * (cy - by)) - (cast(by - ay, Float) * (cx - bx))) > 0;
    }

    static function isCounterClockwise(p: Array<{ x: Int, y: Int }>): Bool {
        var area: Float = 0;
        var len = p.length;
        for (i in 0...len) {
            var j = (i + 1) % len;
            area += (cast(p[i].x, Float) * p[j].y) - (cast(p[j].x, Float) * p[i].y);
        }
        return area > 0;
    }
}