extends Control
# Same view order and cross layout as Elite/Dogfight, relative to the main view.
const VIEWS := [1,4,5,2,3]
const LABELS := ["REAR","UP","DOWN","LEFT","RIGHT"]
const OFFSETS := [Vector2i(1,1),Vector2i(1,0),Vector2i(1,2),Vector2i(0,1),Vector2i(2,1)]
const TILE := Vector2(144,86)
const GAP := 4.0
var game: Node3D
var viewports: Array[SubViewport] = []
var cameras: Array[Camera3D] = []
var tiles: Array[Control] = []
var next_frame_ms := 0

static func view_basis(view: int) -> Basis:
 if view==4: return Basis(Vector3.RIGHT,PI/2)
 if view==5: return Basis(Vector3.RIGHT,-PI/2)
 return Basis(Vector3.UP,[0.0,PI,PI/2,-PI/2][clampi(view,0,3)])

func tile_rect(slot: int) -> Rect2:
 return Rect2(get_viewport_rect().size-Vector2(460,285)+Vector2(OFFSETS[slot])*(TILE+Vector2.ONE*GAP),TILE)

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in range(5):
  var viewport := SubViewport.new()
  viewport.size=Vector2i(288,172)
  viewport.gui_disable_input=true
  viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
  game.add_child(viewport)
  viewport.world_3d=game.get_world_3d()
  var cam := Camera3D.new()
  cam.fov=68
  cam.near=0.025
  viewport.add_child(cam)
  cam.current=true
  viewports.append(viewport)
  cameras.append(cam)
  var tile := Panel.new()
  tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
  tile.size=TILE
  add_child(tile)
  var image := TextureRect.new()
  image.texture=viewport.get_texture()
  image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode=TextureRect.STRETCH_SCALE
  image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  image.mouse_filter=Control.MOUSE_FILTER_IGNORE
  tile.add_child(image)
  var label := Label.new()
  label.text=LABELS[i]
  label.add_theme_font_size_override("font_size",12)
  label.add_theme_color_override("font_shadow_color",Color.BLACK)
  label.add_theme_constant_override("shadow_offset_x",1)
  label.add_theme_constant_override("shadow_offset_y",1)
  label.position=Vector2(5,2)
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  tile.add_child(label)
  tiles.append(tile)

func update_views(main: Camera3D, active: bool) -> void:
 visible=active
 var render := active and Time.get_ticks_msec()>=next_frame_ms
 if render: next_frame_ms=Time.get_ticks_msec()+33
 for i in range(5):
  tiles[i].position=tile_rect(i).position
  cameras[i].global_transform=Transform3D(main.global_basis*view_basis(VIEWS[i]),main.global_position)
  cameras[i].cull_mask=main.cull_mask
  viewports[i].render_target_update_mode=SubViewport.UPDATE_ONCE if render else SubViewport.UPDATE_DISABLED
