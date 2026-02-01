package mortonHx;

import js.Browser;
import js.html.webgl.GL;
import js.html.webgl.Program;
import js.html.CanvasElement;
import js.lib.Float32Array;
import mortonHx.ds.EdgeData;
import mortonHx.ds.Vertex2i;
import mortonHx.ear.EarCutMorton;
import mortonHx.scanLine.Bridger;
import mortonHx.pointInTriangle.PointHit.EdgeFunctionHitInt;
import mortonHx.TestData;
/**
 * 2026 Standard: Zero-overhead Enum Abstract for batching
 */
enum abstract RenderType(Float) {
    var Fill = 0.0;
    var Outline = 1.0;
}

class TestTriangulationWebGL {
    static var gl: GL;
    static var program: Program;
    
    // Shader with 2026 Batching logic
// Vertex Shader: Version MUST be the very first characters
static var vs = "#version 300 es
layout(location = 0) in vec2 a_pos;
layout(location = 1) in vec3 a_barycentric;
out vec3 v_bc;
uniform vec2 u_res;

void main() {
    v_bc = a_barycentric;
    vec2 clipSpace = ((a_pos / u_res) * 2.0 - 1.0) * vec2(1, -1);
    gl_Position = vec4(clipSpace, 0, 1);
}";

// Fragment Shader: Version MUST be the very first characters
static var fs = "#version 300 es
precision mediump float;
in vec3 v_bc;
out vec4 outColor;

void main() {
    float d = min(v_bc.x, min(v_bc.y, v_bc.z));
    float thickness = 0.8;
    float alpha = smoothstep(0.0, fwidth(d) * thickness, d);
    outColor = mix(vec4(1.0, 0.0, 0.0, 1.0), vec4(1.0, 1.0, 1.0, 1.0), alpha);
}";


    static function main() {
        // --- mortonHx Logic Section ---
        var test1 = [93., 195., 129., 92., 280., 81., 402., 134., 477., 70., 619., 61., 759., 97., 758., 247., 662., 347., 665., 230., 721., 140., 607., 117., 472., 171., 580., 178., 603., 257., 605., 377., 690., 404., 787., 328., 786., 480., 617., 510., 611., 439., 544., 400., 529., 291., 509., 218., 400., 358., 489., 402., 425., 479., 268., 464., 341., 338., 393., 427., 373., 284., 429., 197., 301., 150., 296., 245., 252., 384., 118., 360., 190., 272., 244., 165., 81., 259., 40., 216.];
        
        var points: EdgeData<Int> = EdgeData.makePointsInt(test1, 1);
        var holes  = [EdgeData.makePointsInt( hole1, 1 )
            , EdgeData.makePointsInt( hole2, 1 )
            , EdgeData.makePointsInt( hole5, 1, 0, 0 )
            , EdgeData.makePointsInt( hole6, 1 )
            , EdgeData.makePointsInt( hole7, 1 )
            , EdgeData.makePointsInt( hole8, 1 )
            , EdgeData.makePointsInt( hole9, 1, -10, -10 )
            , EdgeData.makePointsInt( hole10, 1, 0, -40 )
         ];
        for( hole in holes ){
            if( hole.isCounterClockwise() ) {
                hole.reverseData();
            } else {
            }
        }
        
        // Use your Bridger for hole merging
        var merged: EdgeData<Int> = Bridger.mergeHolesEast(points, holes);
        var minX = merged.minX;
        var minY = merged.minY;
        merged.translate( -minX, -minY );
        // Triangulate using mortonHx EarCuttingMorton
        var earcut = new EarCuttingMorton(merged, new EdgeFunctionHitInt());
        var triangles: Array<Int> = earcut.triangulate(); 
        
        var tri = new EdgeData(triangles);
        tri.translate( minX, minY );
        
        // --- 2026 WebGL Rendering Section ---
        var canvas: CanvasElement = Browser.document.createCanvasElement();
        canvas.width = 1024; canvas.height = 768;
        Browser.document.body.appendChild(canvas);
        
        gl = canvas.getContextWebGL2({ antialias: true });
        initShaders();

        // Single Draw Call Batching: [x, y, type]
        var batch = new Array<Float>();

        // Add Triangulated Fill
        var i = 0;
        while (i < triangles.length) {
            addVertex(batch, triangles[i], triangles[i+1], RenderType.Fill);
            addVertex(batch, triangles[i+2], triangles[i+3], RenderType.Fill);
            addVertex(batch, triangles[i+4], triangles[i+5], RenderType.Fill);
            i += 6;
        }

        // Add Outline Quads from EdgeData
        var outline: EdgeData<Int> = merged;//.getData();
        outline.translate( minX, minY );
        generateThickOutline(batch, outline, 2.0);

        // Upload and Render
        renderBatch(batch);
    }

    static inline function addVertex(batch:Array<Float>, x:Float, y:Float, type:RenderType) {
        batch.push(x); batch.push(y); batch.push(cast type);
    }

    static function generateThickOutline(batch:Array<Float>, pts:Array<Int>, thick:Float) {
        var half = thick / 2.0;
        var i = 0;
        while (i < pts.length) {
            var x1 = pts[i]; var y1 = pts[i+1];
            var next = (i + 2 >= pts.length) ? 0 : i + 2;
            var x2 = pts[next]; var y2 = pts[next+1];
            
            var dx = x2 - x1; var dy = y2 - y1;
            var len = Math.sqrt(dx * dx + dy * dy);
            var nx = -dy / len * half; var ny = dx / len * half;

            // Quad Triangle 1
            addVertex(batch, x1 + nx, y1 + ny, RenderType.Outline);
            addVertex(batch, x2 + nx, y2 + ny, RenderType.Outline);
            addVertex(batch, x1 - nx, y1 - ny, RenderType.Outline);
            // Quad Triangle 2
            addVertex(batch, x2 + nx, y2 + ny, RenderType.Outline);
            addVertex(batch, x2 - nx, y2 - ny, RenderType.Outline);
            addVertex(batch, x1 - nx, y1 - ny, RenderType.Outline);
            i += 2;
        }
    }

    static function renderBatch(data: Array<Float>) {
        var buffer = gl.createBuffer();
        gl.bindBuffer(GL.ARRAY_BUFFER, buffer);
        gl.bufferData(GL.ARRAY_BUFFER, new Float32Array(data), GL.STATIC_DRAW);

        var posLoc = gl.getAttribLocation(program, "a_pos");
        var typeLoc = gl.getAttribLocation(program, "a_type");
        
        gl.enableVertexAttribArray(posLoc);
        gl.enableVertexAttribArray(typeLoc);
        
        // 3 Floats per vertex: X(4b) + Y(4b) + Type(4b) = 12 bytes stride
        gl.vertexAttribPointer(posLoc, 2, GL.FLOAT, false, 12, 0);
        gl.vertexAttribPointer(typeLoc, 1, GL.FLOAT, false, 12, 8);

        gl.enable(GL.BLEND);
        gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
        gl.clearColor(0.1, 0.1, 0.1, 1);
        gl.clear(GL.COLOR_BUFFER_BIT);
        gl.drawArrays(GL.TRIANGLES, 0, Std.int(data.length / 3));
    }

    static function initShaders() {
        var v = gl.createShader(GL.VERTEX_SHADER);
        gl.shaderSource(v, vs); gl.compileShader(v);
        var f = gl.createShader(GL.FRAGMENT_SHADER);
        gl.shaderSource(f, fs); gl.compileShader(f);
        program = gl.createProgram();
        gl.attachShader(program, v); gl.attachShader(program, f);
        gl.linkProgram(program); 
        if (!gl.getProgramParameter(program, GL.LINK_STATUS)) {
            throw "Program Link Error: " + gl.getProgramInfoLog(program);
        }
        
        
        gl.useProgram(program);

        gl.uniform2f(gl.getUniformLocation(program, "u_res"), 1024, 768);
    }
}
