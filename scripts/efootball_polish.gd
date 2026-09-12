extends Node

class MobileStick:
	extends Control
	signal moved(value: Vector2)
	var value: Vector2 = Vector2.ZERO
	var active: bool = false
	var radius: float = 72.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var t: InputEventScreenTouch = event
			active = t.pressed
			if active:
				set_point(t.position)
			else:
				value = Vector2.ZERO
				moved.emit(value)
				queue_redraw()
		elif event is InputEventScreenDrag:
			var d: InputEventScreenDrag = event
			if active:
				set_point(d.position)

	func set_point(point: Vector2) -> void:
		var center: Vector2 = size * 0.5
		var delta: Vector2 = point - center
		if delta.length() > radius:
			delta = delta.normalized() * radius
		value = delta / radius
		moved.emit(value)
		queue_redraw()

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		draw_circle(c, radius, Color(0.01, 0.03, 0.06, 0.45))
		draw_arc(c, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.24), 3.0)
		var k: Vector2 = c + value * radius * 0.72
		draw_circle(k, 28.0, Color(0.92, 0.96, 1.0, 0.75))
		draw_circle(k, 22.0, Color(0.08, 0.14, 0.20, 0.82))

class MiniMap:
	extends Control
	var game: Node = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if game == null:
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.03, 0.06, 0.86), true)
		var r: Rect2 = Rect2(8.0, 8.0, size.x - 16.0, size.y - 16.0)
		draw_rect(r, Color("#176b3b"), true)
		draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.end.y), Color(1, 1, 1, 0.45), 1.0)
		var home: Array = game.home
		var away: Array = game.away
		for p in home:
			draw_player(r, p.pos, Color("#21d17d"), p == game.controlled)
		for p in away:
			draw_player(r, p.pos, Color("#e54848"), false)
		draw_player(r, game.ball_pos, Color.WHITE, false)

	func draw_player(r: Rect2, pos: Vector3, c: Color, selected: bool) -> void:
		var px: float = r.position.x + (pos.x + 23.0) / 46.0 * r.size.x
		var py: float = r.position.y + (pos.z + 14.0) / 28.0 * r.size.y
		draw_circle(Vector2(px, py), 6.0 if selected else 4.0, c)

var game: Node = null
var overlay: Control = null
var stick: MobileStick = null
var map: MiniMap = null

func _ready() -> void:
	game = get_parent()
	await get_tree().process_frame
	build_overlay()
	apply_visual_polish()

func _process(_delta: float) -> void:
	if game == null:
		return
	if is_instance_valid(game.camera) and game.controlled != null:
		var focus: Vector3 = game.controlled.pos.lerp(game.ball_pos, 0.30)
		var desired: Vector3 = focus + Vector3(0.0, 24.0, 27.0)
		game.camera.position = game.camera.position.lerp(desired, 0.055)
		game.camera.look_at(focus + Vector3(0.0, 0.0, 1.0), Vector3.UP)

func build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui.add_child(overlay)

	var title: Label = Label.new()
	title.text = "STREET FOOTBALL • PAKISTAN"
	title.position = Vector2(455.0, 7.0)
	title.size = Vector2(370.0, 30.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#b9cce0"))
	overlay.add_child(title)

	stick = MobileStick.new()
	stick.position = Vector2(28.0, 500.0)
	stick.size = Vector2(170.0, 170.0)
	stick.moved.connect(_on_stick)
	overlay.add_child(stick)

	var shoot: Button = make_action("SHOOT", Vector2(1090.0, 430.0), Vector2(145.0, 88.0), 19)
	shoot.pressed.connect(game.shoot_ball)
	var pass: Button = make_action("PASS", Vector2(890.0, 610.0), Vector2(105.0, 65.0), 16)
	pass.pressed.connect(game.pass_ball)
	var through: Button = make_action("THROUGH", Vector2(1000.0, 545.0), Vector2(120.0, 65.0), 14)
	through.pressed.connect(do_through)
	var dash: Button = make_action("DASH", Vector2(1040.0, 625.0), Vector2(105.0, 58.0), 15)
	dash.button_down.connect(_set_dash.bind(true))
	dash.button_up.connect(_set_dash.bind(false))
	var switch_player: Button = make_action("SWITCH", Vector2(785.0, 625.0), Vector2(105.0, 58.0), 14)
	switch_player.pressed.connect(game.switch_player)
	var press: Button = make_action("PRESS", Vector2(890.0, 530.0), Vector2(100.0, 58.0), 14)
	press.pressed.connect(do_pressure)

	map = MiniMap.new()
	map.game = game
	map.position = Vector2(525.0, 580.0)
	map.size = Vector2(230.0, 125.0)
	overlay.add_child(map)

func make_action(text: String, pos: Vector2, button_size: Vector2, font_size: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.position = pos
	b.size = button_size
	b.add_theme_font_size_override("font_size", font_size)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.08, 0.13, 0.90)
	normal.corner_radius_top_left = 28
	normal.corner_radius_top_right = 28
	normal.corner_radius_bottom_left = 28
	normal.corner_radius_bottom_right = 28
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1, 1, 1, 0.18)
	b.add_theme_stylebox_override("normal", normal)
	overlay.add_child(b)
	return b

func _on_stick(value: Vector2) -> void:
	game.touch_dir = value

func _set_dash(value: bool) -> void:
	game.sprinting = value

func do_through() -> void:
	if game.finished or game.controlled == null or game.ball_owner != game.controlled:
		return
	var target: Node = nearest_teammate()
	if target == null:
		return
	var direction: Vector3 = game.controlled.pos.direction_to(target.pos + Vector3(4.0, 0.0, 0.0))
	game.ball_velocity = direction * 18.0
	game.ball_owner = null

func do_pressure() -> void:
	if game.finished or game.controlled == null:
		return
	var nearest: Node = nearest_opponent()
	if nearest == null:
		return
	var direction: Vector3 = game.controlled.pos.direction_to(nearest.pos)
	game.controlled.pos += direction * 0.65
	if game.ball_owner == nearest and game.controlled.pos.distance_to(nearest.pos) < 1.7:
		game.ball_owner = game.controlled

func nearest_teammate() -> Node:
	var best: Node = null
	var best_distance: float = 9999.0
	for p in game.home:
		if p == game.controlled:
			continue
		var d: float = game.controlled.pos.distance_to(p.pos)
		if d < best_distance:
			best_distance = d
			best = p
	return best

func nearest_opponent() -> Node:
	var best: Node = null
	var best_distance: float = 9999.0
	for p in game.away:
		var d: float = game.controlled.pos.distance_to(p.pos)
		if d < best_distance:
			best_distance = d
			best = p
	return best

func apply_visual_polish() -> void:
	for child: Node in game.ui.get_children():
		if child is Button:
			var button: Button = child
			button.visible = false
	if is_instance_valid(game.camera):
		game.camera.fov = 54.0
