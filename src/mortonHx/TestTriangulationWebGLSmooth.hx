package mortonHx;

import js.Browser;
import js.html.webgl.GL;
import js.html.webgl.Program;
import js.html.CanvasElement;
import js.lib.Float32Array;
import mortonHx.ds.EdgeData;
import mortonHx.ear.EarCutMorton;
import mortonHx.scanLine.Bridger;
import mortonHx.pointInTriangle.PointHit.EdgeFunctionHitInt;
import mortonHx.TestData;

class TestTriangulationWebGLSmooth {
    static var gl: GL;
    static var program: Program;
    
    // Shader with 2026 Barycentric Interpolation
// Vertex Shader: Ensure NO space or newline before #version
static var vs = "#version 300 es
in vec2 a_pos;
in vec3 a_barycentric;
out vec3 v_bc;
uniform vec2 u_res;

void main() {
    v_bc = a_barycentric;
    // Snap to pixel centers to prevent edge jitter
    vec2 snappedPos = floor(a_pos) + 0.5;
    vec2 clipSpace = ((snappedPos / u_res) * 2.0 - 1.0) * vec2(1, -1);
    gl_Position = vec4(clipSpace, 0, 1);
}";

// Fragment Shader: Must also start with #version 300 es
static var fs = "#version 300 es
precision mediump float;
in vec3 v_bc;
out vec4 outColor;

void main() {
    // Calculate derivatives per-component for stability on skinny triangles
    vec3 d = fwidth(v_bc);
    
    // Normalize distance into 'pixel units' for each edge
    // 1.2 adds a slight softness that hides jitter on aliased edges
    vec3 edgeFactor = smoothstep(vec3(0.0), d * 1.2, v_bc);
    
    // Find the closest edge in pixel-space
    float closest = min(min(edgeFactor.x, edgeFactor.y), edgeFactor.z);
    
    // Mix Red (edge) and White (background)
    outColor = mix(vec4(1.0, 0.0, 0.0, 1.0), vec4(1.0, 1.0, 1.0, 1.0), closest);
}";


    static function main() {
        // --- mortonHx Logic Section ---
        var test1 = [93., 195., 129., 92., 280., 81., 402., 134., 477., 70., 619., 61., 759., 97., 758., 247., 662., 347., 665., 230., 721., 140., 607., 117., 472., 171., 580., 178., 603., 257., 605., 377., 690., 404., 787., 328., 786., 480., 617., 510., 611., 439., 544., 400., 529., 291., 509., 218., 400., 358., 489., 402., 425., 479., 268., 464., 341., 338., 393., 427., 373., 284., 429., 197., 301., 150., 296., 245., 252., 384., 118., 360., 190., 272., 244., 165., 81., 259., 40., 216.];
        
        var points = EdgeData.makePointsInt(test1, 1);
        var holes = [
            EdgeData.makePointsInt(hole1, 1), EdgeData.makePointsInt(hole2, 1),
            EdgeData.makePointsInt(hole5, 1), EdgeData.makePointsInt(hole6, 1),
            EdgeData.makePointsInt(hole7, 1), EdgeData.makePointsInt(hole8, 1),
            EdgeData.makePointsInt(hole9, 1, -10, -10), EdgeData.makePointsInt(hole10, 1, 0, -40)
        ];

        for(hole in holes) if(hole.isCounterClockwise()) hole.reverseData();
        
        var merged = Bridger.mergeHolesEast(points, holes);
        var minX = merged.minX;
        var minY = merged.minY;
        merged.translate(-minX, -minY);

        var earcut = new EarCuttingMorton(merged, new EdgeFunctionHitInt());
        var triangles: Array<Int> = earcut.triangulate(); 

        // Restoration for screen space
        var triData = new EdgeData(triangles);
        triData.translate(minX, minY);
        var restoredTris: Array<Int> = triData;

        // --- WebGL Section ---
        var canvas: CanvasElement = Browser.document.createCanvasElement();
        canvas.width = 1024; canvas.height = 768;
        Browser.document.body.appendChild(canvas);
        
        gl = canvas.getContextWebGL2({ antialias: true });
        initShaders();

        // Batching: [x, y, b1, b2, b3] (5 floats per vertex)
        var batch = new Array<Float>();
        var i = 0;
        while (i < restoredTris.length) {
            // Vertex A (1,0,0)
            batch.push(restoredTris[i]);   batch.push(restoredTris[i+1]);
            batch.push(1.0); batch.push(0.0); batch.push(0.0);
            // Vertex B (0,1,0)
            batch.push(restoredTris[i+2]); batch.push(restoredTris[i+3]);
            batch.push(0.0); batch.push(1.0); batch.push(0.0);
            // Vertex C (0,0,1)
            batch.push(restoredTris[i+4]); batch.push(restoredTris[i+5]);
            batch.push(0.0); batch.push(0.0); batch.push(1.0);
            i += 6;
        }

        renderBatch(batch);
    }

    static function renderBatch(data: Array<Float>) {
        var buffer = gl.createBuffer();
        gl.bindBuffer(GL.ARRAY_BUFFER, buffer);
        gl.bufferData(GL.ARRAY_BUFFER, new Float32Array(data), GL.STATIC_DRAW);

        var posLoc = gl.getAttribLocation(program, "a_pos");
        var bcLoc = gl.getAttribLocation(program, "a_barycentric");
        
        gl.enableVertexAttribArray(posLoc);
        gl.enableVertexAttribArray(bcLoc);
        
        // Stride: 5 floats * 4 bytes = 20 bytes
        gl.vertexAttribPointer(posLoc, 2, GL.FLOAT, false, 20, 0);
        gl.vertexAttribPointer(bcLoc, 3, GL.FLOAT, false, 20, 8);

        gl.clearColor(1.0, 1.0, 1.0, 1.0); // White background
        gl.clear(GL.COLOR_BUFFER_BIT);
        gl.drawArrays(GL.TRIANGLES, 0, Std.int(data.length / 5));
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
