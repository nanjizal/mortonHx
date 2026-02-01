# mortonHx  
## Morton Code for haxe  

Fairly experimental.
Has some support for Morton Code with Int64 up to 5D, but is focused on Morton Code 2D for Int.
  
  
usage:
```haxe  
var p = (cast( number ,Morton2D)).decode();
trace( p.x + ' ' p.y );
var p = new Point2DInt( 100, 100 );
var m: Mordon2D = p.toMordon2D();
```  
  
## Has Earcut Implementation  
  
  
### Bridger  

Bridger provides code to bridge holes to the shell, isolated from actual triangulation.  
It is a Integer focused solution ( maybe viable to use Int64 parts...? or even Float )  
Has implementation of a choice of 3 Line Intersectors  
  
1.  Franklin Antonio (FA)         ```IntersectorFA```  
2.  Gareth Rees (Parametric)      ```IntersectorGareth```  
3.  Cramer's Rule (hxPolyK style) ```IntersectorCrammer```  
  
You can choose to connect Holes to the shell with a bridge from North, South, East or West.
East is the usual, West on the test has an overlay issue. 
Currently it uses a triangle 'fit', and visiblity to decide when to use the directions' nearest Edge vertices.  
The code is setup to allow exploring alternative bridging. There are optimisation on reducing the edge checks yet for the bridges but there is for point in triangle for actual triangulation.

### EarCutMorton  
  
The EarCut is fairly basic so hopefully fast as it uses Morton to reduce the number of pointInTriangle checks.
It is a Integer focused solution ( maybe viable to use Int64 parts...? or even Float )  
Has implementation of a choice of 3 Point in Triangle checks, they have a prepare and hitCheck stage to optimise.
  
1.  Edge function sign check    ```EdgeFunctionHitInt```
2.  Barycentric logic           ```BarycentricHitInt```
3.  Same Side                   ```SameSideHitInt```
  
Need to consider if it is worthwhile to use triangle fit code to flip some triangles.  May provide that as optional in future.  
  
### Ear Cut examples
  
There is a fairly robust basic test using Canvas, the tests needs tidying up. There is some experimental WebGL.  
Currently has not been compiled against C++/HL etc.. so may need to check there are no null issues.  
There are no examples but the code is pure haxe so it should be viable to use the EarCut or Morton with any haxe target.  
  
#### Dox  
  
Dox has been setup, but in many places comments are sparse.  As usual look at the examples.  

### Links  
  
[canvas test 800x600](https://nanjizal.github.io/mortonHx/testMorton.html)  
  
[canvas test Isometric 3D](https://nanjizal.github.io/mortonHx/testMorton3D.html)  
  
<img width="400" height="300" alt="image" src="https://github.com/user-attachments/assets/d880e8c3-d6f0-421e-82d7-79928d55454d" />


[dox](https://nanjizal.github.io/mortonHx/pages/index.html)
  
