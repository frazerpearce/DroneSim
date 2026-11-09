extends Control
var game: Node3D
var tabs: TabContainer
var listening := ""
var slot := 0
var buttons := {}
var notice: Label
var network_status: Label
var name_field: LineEdit
var address: LineEdit
var port: SpinBox
var course_picker: OptionButton
var course_info: Label
var times_table: Tree
var times_status: Label
var previous_pause := false

func label(parent: Node, text: String) -> Label:
 var item := Label.new()
 item.text = text
 parent.add_child(item)
 return item
func button(parent: Node, text: String, callback: Callable) -> Button:
 var item := Button.new()
 item.text = text
 item.custom_minimum_size.y = 32
 item.pressed.connect(callback)
 parent.add_child(item)
 return item
func page(title: String) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.name = title
 tabs.add_child(scroll)
 var box := VBoxContainer.new()
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 box.add_theme_constant_override("separation",8)
 scroll.add_child(box)
 return box
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade := ColorRect.new()
 shade.color = Color(0.015,0.025,0.045,0.96)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var panel := MarginContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: panel.add_theme_constant_override("margin_"+side,36)
 add_child(panel)
 var box := VBoxContainer.new()
 panel.add_child(box)
 label(box,"DRONESIM 0.4.0 — SETUP").add_theme_font_size_override("font_size",28)
 label(box,"Menus freeze your drone; opening a menu during a timed run invalidates that attempt.")
 tabs = TabContainer.new()
 tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.add_child(tabs)
 var flight := page("Flight & course")
 label(flight,"Course (changing it resets your current attempt)")
 course_picker = OptionButton.new()
 for i in range(game.course.Catalog.COURSES.size()):
  var spec: Dictionary = game.course.Catalog.COURSES[i]
  course_picker.add_item("%02d — %s (%s)" % [i+1,spec.name,spec.difficulty])
 flight.add_child(course_picker)
 course_info = label(flight,"")
 course_picker.item_selected.connect(func(index): game.select_course(index))
 refresh_course()
 label(flight,"Pilot name (shown to LAN competitors)")
 name_field = LineEdit.new()
 name_field.max_length = 24
 name_field.text = game.session.player_name
 flight.add_child(name_field)
 label(flight,"Press Enter or leave the name field to load that player's saved times.")
 name_field.text_submitted.connect(func(_value): apply_player())
 name_field.focus_exited.connect(apply_player)
 var hold := CheckBox.new()
 hold.text = "Altitude hold"
 hold.button_pressed = game.drone.altitude_hold
 hold.toggled.connect(func(value): game.drone.altitude_hold=value; game.drone.target_height=game.drone.position.y; game.save_settings())
 flight.add_child(hold)
 var route := CheckBox.new()
 route.text = "Show suggested pathway"
 route.button_pressed = game.course.route.visible
 route.toggled.connect(func(value): game.course.route.visible=value; game.save_settings())
 flight.add_child(route)
 label(flight,"Camera field of view")
 var fov := HSlider.new()
 fov.min_value = 50
 fov.max_value = 110
 fov.step = 1
 fov.value = game.camera.fov
 fov.value_changed.connect(func(value): game.camera.fov=value; game.save_settings())
 flight.add_child(fov)
 label(flight,"Lift off the green plinth, pass every gate of the selected course in order,\nthen land on the purple plinth. Green = next; cyan = following gate.\nDotted blue marks the suggested route. Cross gates in the indicated direction.\nTimer starts on takeoff and stops at stable landing contact (0.5 s confirmation).\nFastest valid completed time wins. Reset begins another attempt.\nRemote drones are translucent ghosts: competitors cannot collide.\nLAN times are self-reported; this is a friendly race, not an anti-cheat system.")
 button(flight,"Reset drone and course",func(): game.reset_attempt())
 var history := page("Best times")
 label(history,"Best completed time per player and course • saved on this computer")
 label(history,"Names ignore surrounding spaces and letter case. Total requires a time on every course. A dash means incomplete.")
 times_table=Tree.new()
 times_table.columns=12
 times_table.hide_root=true
 times_table.column_titles_visible=true
 times_table.set_column_title(0,"Player")
 times_table.set_column_custom_minimum_width(0,150)
 for i in range(10):
  times_table.set_column_title(i+1,"%02d" % (i+1))
  times_table.set_column_custom_minimum_width(i+1,86)
 times_table.set_column_title(11,"Total")
 times_table.set_column_custom_minimum_width(11,100)
 times_table.custom_minimum_size=Vector2(0,260)
 times_table.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 history.add_child(times_table)
 var legend := ""
 for i in range(10): legend += "%02d: %s%s" % [i+1,game.course.Catalog.COURSES[i].name,"\n" if i%2==1 else "     "]
 label(history,legend)
 times_status=label(history,"")
 game.session.results_changed.connect(refresh_times)
 refresh_times()
 var lan := page("LAN race")
 label(lan,"Mac and Windows • up to 8 pilots • same version on every machine")
 var addresses: Array[String] = []
 for value in IP.get_local_addresses():
  if value.contains(".") and not value.begins_with("127."): addresses.append(value)
 label(lan,"This machine: "+", ".join(addresses))
 label(lan,"Host IP address")
 address = LineEdit.new()
 address.placeholder_text = "192.168.1.20"
 lan.add_child(address)
 label(lan,"UDP port (allow through the host firewall)")
 port = SpinBox.new()
 port.min_value = 1024
 port.max_value = 65535
 port.value = 24568
 lan.add_child(port)
 button(lan,"HOST race — clears session times",func(): game.session.host(int(port.value)))
 button(lan,"JOIN host — clears your session time",func(): game.session.join(address.text,int(port.value)))
 button(lan,"Disconnect / single player",func(): game.session.offline())
 network_status = label(lan,"")
 var keys := page("Key bindings")
 label(keys,"Three slots per action: keyboard, mouse buttons or wheel. Click a slot, then press input.\nEscape cancels capture; Backspace/Delete clears. Duplicate inputs are rejected.\nEscape always opens/closes setup, so you cannot lock yourself out.")
 var grid := GridContainer.new()
 grid.columns = 4
 keys.add_child(grid)
 for title in ["Action","Primary","Alternate","Third / mouse"]: label(grid,title)
 for action in game.controls.DEFAULTS:
  label(grid,game.controls.LABELS[action]).custom_minimum_size.x = 240
  buttons[action] = []
  for i in range(3):
   var b := button(grid,"",func(): listening=action; slot=i; notice.text="Press input for "+game.controls.LABELS[action])
   b.custom_minimum_size.x = 180
   buttons[action].append(b)
 button(keys,"Restore default bindings",func(): game.controls.restore_defaults(); persist(); refresh())
 notice = label(box,"")
 button(box,"Return to flight / Escape",close)
 button(box,"Quit / Q",func(): get_tree().quit())
 refresh()
 visible = false

func persist() -> void:
 var result: int = game.controls.save()
 notice.text = "Bindings saved" if result==OK else "Could not save bindings: "+error_string(result)
func refresh() -> void:
 for action in buttons:
  for i in range(3): buttons[action][i].text=game.controls.key_label(action,i)
func show_panel(network := false) -> void:
 if visible:
  if network: tabs.current_tab=2
  return
 refresh_times()
 previous_pause = game.paused
 game.course.invalidate("MENU OPENED — reset")
 game.paused = true
 game.drone.freeze = true
 game.held.clear()
 visible = true
 tabs.current_tab = 2 if network else 0
func close() -> void:
 apply_player()
 listening = ""
 visible = false
 game.paused = previous_pause
 game.drone.freeze = game.paused
 game.held.clear()
 var focus := get_viewport().gui_get_focus_owner()
 if focus: focus.release_focus()
func _input(event: InputEvent) -> void:
 if not visible: return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if listening.is_empty(): close()
  else: listening=""; notice.text="Cancelled"
  get_viewport().set_input_as_handled()
  return
 if listening.is_empty() and event is InputEventKey and event.pressed and not event.is_echo() and event.physical_keycode==KEY_Q:
  var focus := get_viewport().gui_get_focus_owner()
  if not focus is LineEdit and not focus is TextEdit:
   get_tree().quit()
   get_viewport().set_input_as_handled()
   return
 if listening.is_empty() or not event.is_pressed() or event.is_echo(): return
 var code: int = game.controls.event_code(event)
 if code==0: return
 if event is InputEventKey and event.keycode in [KEY_BACKSPACE,KEY_DELETE]: code=0
 if game.controls.assign_key(listening,slot,code):
  listening=""
  persist()
  refresh()
 else: notice.text=game.controls.error
 get_viewport().set_input_as_handled()
func _process(_dt: float) -> void:
 if visible:
  refresh_course()
  network_status.text=game.session.status+"\n\n"+game.session.leaderboard()

func refresh_course() -> void:
 if not course_picker: return
 course_picker.select(game.course.selected)
 var spec: Dictionary = game.course.Catalog.COURSES[game.course.selected]
 course_info.text = "%s • %d gates • %.1f × %.1f m openings\n%s\nIn LAN play the host selects the course for everyone." % [spec.difficulty,spec.points.size(),spec.width,spec.height,spec.hint]
 course_picker.disabled = game.session.net.peer != null and not game.session.net.is_host

func apply_player() -> void:
 if not name_field: return
 game.session.set_player_name(name_field.text)
 name_field.text=game.session.player_name
 game.save_settings()

func refresh_times() -> void:
 if not times_table: return
 times_table.clear()
 var root := times_table.create_item()
 var names: Array = game.session.results.players.keys()
 names.sort()
 for id in names:
  var profile: Dictionary = game.session.results.players[id]
  var item := times_table.create_item(root)
  item.set_text(0,profile.name)
  for i in range(10):
   var seconds: float = game.session.results.best(profile.name,game.course.Catalog.id_at(i))
   item.set_text(i+1,"%.3f s" % seconds if seconds>0 else "—")
   item.set_tooltip_text(i+1,game.course.Catalog.COURSES[i].name)
  var total: float = game.session.results.total(profile.name)
  item.set_text(11,"%.3f s" % total if total>0 else "—")
  item.set_tooltip_text(11,"Sum of personal bests; requires a time on all ten courses")
 times_status.text=game.session.results.error
