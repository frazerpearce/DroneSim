extends RefCounted
# Nearest valid point in the conservative ground-clearance map. Rectangular
# obstacles are expanded in their own axes, so diagonal gates remain oriented.
const EPS := 0.0001
var obstacles: Array = []
var low := Vector2.ZERO
var high := Vector2.ZERO
var clearance := 0.0

func collect(game: Node3D) -> void:
 clearance=2.0*game.drone.BODY_SIZE.z
 low=Vector2(-19.8+clearance,-29.8+clearance)
 high=-low
 obstacles.clear()
 for body in game.get_tree().get_nodes_in_group("respawn_obstacles"):
  if not game.is_ancestor_of(body): continue
  for child in body.get_children():
   if not child is CollisionShape3D or not child.shape is BoxShape3D: continue
   var half: Vector3=child.shape.size/2.0
   var t: Transform3D=child.global_transform
   var height_extent := absf(t.basis.x.y)*half.x+absf(t.basis.y.y)*half.y+absf(t.basis.z.y)*half.z
   if t.origin.y-height_extent>0.18+game.drone.BODY_SIZE.y/2+clearance: continue
   obstacles.append({"centre":Vector2(t.origin.x,t.origin.z),"x":Vector2(t.basis.x.x,t.basis.x.z).normalized(),"z":Vector2(t.basis.z.x,t.basis.z.z).normalized(),"half":Vector2(half.x+clearance,half.z+clearance)})

func valid(point: Vector2) -> bool:
 if point.x<low.x-EPS or point.x>high.x+EPS or point.y<low.y-EPS or point.y>high.y+EPS: return false
 for o in obstacles:
  var p: Vector2=point-o.centre
  if absf(p.dot(o.x))<o.half.x-EPS and absf(p.dot(o.z))<o.half.y-EPS: return false
 return true

func edges_of(c: Vector2, x: Vector2, z: Vector2, half: Vector2) -> Array:
 var corners := [c-x*half.x-z*half.y,c+x*half.x-z*half.y,c+x*half.x+z*half.y,c-x*half.x+z*half.y]
 var edges := []
 for i in range(4): edges.append([corners[i],corners[(i+1)%4]])
 return edges

func nearest(crash: Vector3) -> Vector3:
 var source := Vector2(crash.x,crash.z)
 var clamped := source.clamp(low,high)
 if valid(clamped): return Vector3(clamped.x,0.18,clamped.y)
 var edges := edges_of((low+high)/2,Vector2.RIGHT,Vector2.DOWN,(high-low)/2)
 for o in obstacles: edges.append_array(edges_of(o.centre,o.x,o.z,o.half))
 var candidates := []
 for edge in edges:
  var a: Vector2=edge[0]
  var direction: Vector2=edge[1]-a
  candidates.append(a+direction*clampf((source-a).dot(direction)/direction.length_squared(),0,1))
  candidates.append(a)
 # A nearest point on the boundary of overlapping forbidden regions can lie
 # at an edge intersection rather than a projection onto either edge alone.
 for i in range(edges.size()):
  var a: Vector2=edges[i][0]
  var r: Vector2=edges[i][1]-a
  for j in range(i+1,edges.size()):
   var b: Vector2=edges[j][0]
   var s: Vector2=edges[j][1]-b
   var cross := r.cross(s)
   if absf(cross)<0.0000001: continue
   var u := (b-a).cross(r)/cross
   var t := (b-a).cross(s)/cross
   if t>=0 and t<=1 and u>=0 and u<=1: candidates.append(a+r*t)
 var best := Vector2.INF
 var distance := INF
 for candidate in candidates:
  var point: Vector2=candidate
  var d := point.distance_squared_to(source)
  if d<distance and valid(point):
   best=point
   distance=d
 return Vector3(best.x,0.18,best.y)
