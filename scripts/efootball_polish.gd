extends Node

class MobileStick:
	extends Control
	signal moved(value: Vector2)
	var value: Vector2 = Vector2.ZERO
	var active: bool = false
	var radius: float = 70.0

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
		elif event is InputEventScreenDrag and active:
			var d: InputEventScreenDrag = event
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
		draw_circle(c, radius + 9.0, Color(0.0, 0.0, 0.0, 0.24))
		draw_circle(c, radius, Color(0.02, 0.05, 0.08, 0.72))
		draw_arc(c, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.34), 2.0)
		var k: Vector2 = c + value * radius * 0.68
		draw_circle(k, 29.0, Color(0.12, 0.70, 0.42, 0.95))
		draw_circle(k, 22.0, Color(0.04, 0.12, 0.12, 0.95))

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
		draw_style_box(panel(Color(0.01, 0.03, 0.04, 0.88), 14, Color(1, 1, 1, 0.16), 1), Rect2(Vector2.ZERO, size))
		var r: Rect2 = Rect2(9.0, 9.0, size.x - 18.0, size.y - 18.0)
		draw_rect(r, Color("#145d35"), true)
		draw_rect(Rect2(r.position, r.size), Color(1, 1, 1, 0.16), false, 1.0)
		draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.end.y), Color(1, 1, 1, 0.38), 1.0)
		draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.16, Color(1, 1, 1, 0.04))
		for p in game.home:
			draw_player(r, p.pos, Color("#20d47f"), p == game.controlled)
		for p in game.away:
			draw_player(r, p.pos, Color("#ff4f57"), false)
		draw_player(r, game.ball_pos, Color.WHITE, false)

	func draw_player(r: Rect2, pos: Vector3, c: Color, selected: bool) -> void:
		var px: float = r.position.x + (pos.x + 23.0) / 46.0 * r.size.x
		var py: float = r.position.y + (pos.z + 14.0) / 28.0 * r.size.y
		if selected:
			draw_circle(Vector2(px, py), 7.0, Color(1, 1, 1, 0.32))
		draw_circle(Vector2(px, py), 5.0 if selected else 3.5, c)

func panel(bg: Color, radius: int, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = width
	s.border_width_right = width
	s.border_width_top = width
	s.border_width_bottom = width
	s.border_color = border
	return s

var game: Node = null
var overlay: Control = null
var stick: MobileStick = null
var map: MiniMap = null
var selected_ring: MeshInstance3D = null
var player_rings: Array[MeshInstance3D] = []

func _ready() -> void:
	game = get_parent()
	await get_tree().process_frame
	await get_tree().process_frame
	apply_visual_polish()
	build_stadium_upgrade()
	build_overlay()
	refresh_players()

func _process(_delta: float) -> void:
	if game == null:
		return
	if is_instance_valid(game.camera) and game.controlled != null:
		var focus: Vector3 = game.controlled.pos.lerp(game.ball_pos, 0.24)
		var desired: Vector3 = focus + Vector3(0.0, 15.5, 19.5)
		game.camera.position = game.camera.position.lerp(desired, 0.075)
		game.camera.look_at(focus + Vector3(0.0, 0.65, 0.0), Vector3.UP)
		game.camera.fov = lerpf(game.camera.fov, 51.0, 0.06)
	refresh_players()

func apply_visual_polish() -> void:
	for child: Node in game.ui.get_children():
		child.visible = false
	if is_instance_valid(game.camera):
		game.camera.fov = 51.0
		game.camera.near = 0.05
		game.camera.far = 180.0
	if is_instance_valid(game.world):
		var env_node: WorldEnvironment = game.world.get_node_or_null("WorldEnvironment")
		if env_node != null and env_node.environment != null:
			env_node.environment.background_mode = Environment.BG_COLOR
			env_node.environment.background_color = Color("#07121b")
			env_node.environment.ambient_light_energy = 0.58
			var sun: DirectionalLight3D = game.world.get_node_or_null("DirectionalLight3D")
			if sun != null:
				sun.light_energy = 1.05

func build_stadium_upgrade() -> void:
	var stadium := Node3D.new()
	stadium.name = "ProfessionalStadiumPresentation"
	game.world.add_child(stadium)
	# Stands around the compact street stadium.
	for side in [-1.0, 1.0]:
		var stand := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(52.0, 5.0, 3.0)
		stand.mesh = mesh
		stand.material_override = make_mat(Color("#202936"), 0.9)
		stand.position = Vector3(0.0, 2.2, side * 18.0)
		stadium.add_child(stand)
		for x in range(-20, 21, 4):
			var seat := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(2.8, 0.55, 0.65)
			seat.mesh = sm
			seat.material_override = make_mat(Color("#344153"), 0.85)
			seat.position = Vector3(float(x), 4.8, side * 16.6)
			stadium.add_child(seat)
	# Floodlights and visible lamps.
	for x in [-25.0, 25.0]:
		for z in [-13.0, 13.0]:
			var pole := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.12
			pm.bottom_radius = 0.20
			pm.height = 13.0
			pole.mesh = pm
			pole.material_override = make_mat(Color("#3c4650"), 0.7)
			pole.position = Vector3(x, 6.5, z)
			stadium.add_child(pole)
			var lamp := OmniLight3D.new()
			lamp.light_color = Color("#fff4d6")
			lamp.light_energy = 4.0
			lamp.omni_range = 18.0
			lamp.position = Vector3(x, 13.0, z)
			stadium.add_child(lamp)
	# Goal nets and frames.
	for x in [-23.25, 23.25]:
		var frame := Node3D.new()
		frame.position = Vector3(x, 0.0, 0.0)
		stadium.add_child(frame)
		for z in [-3.4, 3.4]:
			add_box(frame, Vector3(0.20, 2.8, 0.20), Color.WHITE, Vector3(0, 1.4, z))
		add_box(frame, Vector3(0.20, 0.20, 6.8), Color.WHITE, Vector3(0, 2.8, 0))
		for z in [-3.0, -1.5, 0.0, 1.5, 3.0]:
			add_box(frame, Vector3(0.04, 2.5, 0.04), Color(1, 1, 1, 0.32), Vector3(0.16, 1.35, z))
	# Pakistan-style banners, deliberately original and text-free for clean rendering.
	for side in [-1.0, 1.0]:
		var banner := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(12.0, 2.2, 0.08)
		banner.mesh = bm
		banner.material_override = make_mat(Color("#0b7a45"), 0.75)
		banner.position = Vector3(0.0, 7.2, side * 18.2)
		stadium.add_child(banner)

func add_box(parent: Node3D, size: Vector3, color: Color, pos: Vector3) -> void:
	var n := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	n.mesh = m
	n.material_override = make_mat(color, 0.8)
	n.position = pos
	parent.add_child(n)

func make_mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func refresh_players() -> void:
	if game == null:
		return
	for p in game.home:
		upgrade_player(p, Color("#087c43"), Color("#f3f4ef"))
	for p in game.away:
		upgrade_player(p, Color("#b51f35"), Color("#f1f1f1"))

func upgrade_player(p: Variant, jersey: Color, shorts: Color) -> void:
	if p == null or not is_instance_valid(p.node):
		return
	var root: Node3D = p.node
	root.position = p.pos
	# Hide the original primitive body/head and replace them with a footballer silhouette.
	if root.get_child_count() >= 2:
		root.get_child(0).visible = false
		root.get_child(1).visible = false
	var visual: Node3D = root.get_node_or_null("ProfessionalFootballer")
	if visual == null:
		visual = Node3D.new()
		visual.name = "ProfessionalFootballer"
		root.add_child(visual)
		var torso := MeshInstance3D.new()
		var tm := CapsuleMesh.new()
		tm.radius = 0.43
		tm.height = 1.05
		torso.mesh = tm
		torso.material_override = make_mat(jersey, 0.72)
		torso.position.y = 1.12
		visual.add_child(torso)
		var shorts_mesh := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.82, 0.46, 0.48)
		shorts_mesh.mesh = sm
		shorts_mesh.material_override = make_mat(shorts, 0.8)
		shorts_mesh.position.y = 0.63
		visual.add_child(shorts_mesh)
		for side in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var lm := CapsuleMesh.new()
			lm.radius = 0.14
			lm.height = 0.85
			leg.mesh = lm
			leg.material_override = make_mat(Color("#d49a76"), 0.9)
			leg.position = Vector3(side * 0.21, 0.27, 0.0)
			visual.add_child(leg)
			var sock := MeshInstance3D.new()
			var som := BoxMesh.new()
			som.size = Vector3(0.27, 0.32, 0.27)
			sock.mesh = som
			sock.material_override = make_mat(Color.WHITE, 0.7)
			sock.position = Vector3(side * 0.21, 0.50, 0.0)
			visual.add_child(sock)
			var arm := MeshInstance3D.new()
			var am := CapsuleMesh.new()
			am.radius = 0.105
			am.height = 0.82
			arm.mesh = am
			arm.material_override = make_mat(Color("#d49a76"), 0.9)
			arm.position = Vector3(side * 0.54, 1.08, 0.0)
			arm.rotation_degrees.z = side * -12.0
			visual.add_child(arm)
		var neck := MeshInstance3D.new()
		var nm := CylinderMesh.new()
		nm.top_radius = 0.16
		nm.bottom_radius = 0.16
		nm.height = 0.20
		neck.mesh = nm
		neck.material_override = make_mat(Color("#d49a76"), 0.9)
		neck.position.y = 1.78
		visual.add_child(neck)
		var head := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = 0.31
		hm.height = 0.62
		head.mesh = hm
		head.material_override = make_mat(Color("#d49a76"), 0.85)
		head.position.y = 2.12
		visual.add_child(head)
		var hair := MeshInstance3D.new()
		var hair_mesh := SphereMesh.new()
		hair_mesh.radius = 0.315
		hair_mesh.height = 0.22
		hair.mesh = hair_mesh
		hair.material_override = make_mat(Color("#191513"), 0.95)
		hair.position = Vector3(0.0, 2.34, 0.02)
		visual.add_child(hair)
		var name_tag := Label3D.new()
		name_tag.text = p.pname
		name_tag.font_size = 22
		name_tag.outline_size = 5
		name_tag.modulate = Color(1, 1, 1, 0.0)
		name_tag.position = Vector3(0.0, 2.85, 0.0)
		visual.add_child(name_tag)
	# Keep selected-player indicator visually obvious.
	var ring: MeshInstance3D = root.get_node_or_null("SelectionRing")
	if ring == null:
		ring = MeshInstance3D.new()
		ring.name = "SelectionRing"
		var rm := TorusMesh.new()
		rm.inner_radius = 0.68
		rm.outer_radius = 0.80
		ring.mesh = rm
		ring.material_override = make_mat(Color("#20e08a"), 0.35)
		ring.rotation_degrees.x = 90.0
		ring.position.y = 0.05
		root.add_child(ring)
	ring.visible = (p == game.controlled)

func build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui.add_child(overlay)
	# Top broadcast scoreboard.
	var top := Panel.new()
	top.position = Vector2(390, 12)
	top.size = Vector2(500, 74)
	top.add_theme_stylebox_override("panel", panel(Color(0.015, 0.025, 0.035, 0.94), 18, Color(1, 1, 1, 0.14), 1))
	overlay.add_child(top)
	add_text(top, "PAK", Vector2(24, 11), Vector2(90, 28), 17, Color("#24d47f"))
	add_text(top, "VS", Vector2(220, 12), Vector2(60, 26), 13, Color("#8794a0"), HORIZONTAL_ALIGNMENT_CENTER)
	add_text(top, "STREET XI", Vector2(386, 11), Vector2(90, 28), 15, Color("#ff5662"), HORIZONTAL_ALIGNMENT_RIGHT)
	var score := Label.new()
	score.name = "ProScore"
	score.position = Vector2(125, 7)
	score.size = Vector2(250, 38)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 27)
	score.add_theme_color_override("font_color", Color.WHITE)
	top.add_child(score)
	var timer := Label.new()
	timer.name = "ProTimer"
	timer.position = Vector2(185, 43)
	timer.size = Vector2(130, 22)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer.add_theme_font_size_override("font_size", 12)
	timer.add_theme_color_override("font_color", Color("#aeb8c2"))
	top.add_child(timer)
	# Location badge.
	var badge := Panel.new()
	badge.position = Vector2(22, 18)
	badge.size = Vector2(250, 56)
	badge.add_theme_stylebox_override("panel", panel(Color(0.01, 0.025, 0.035, 0.80), 14, Color(1, 1, 1, 0.10), 1))
	overlay.add_child(badge)
	add_text(badge, "STREET FOOTBALL", Vector2(14, 7), Vector2(220, 20), 12, Color("#e8eef3"))
	add_text(badge, "PAKISTAN  •  MATCH %02d" % game.match_number, Vector2(14, 28), Vector2(220, 18), 10, Color("#20d47f"))
	# Minimap.
	map = MiniMap.new()
	map.game = game
	map.position = Vector2(505, 600)
	map.size = Vector2(270, 108)
	overlay.add_child(map)
	# Controls.
	stick = MobileStick.new()
	stick.position = Vector2(28, 500)
	stick.size = Vector2(170, 170)
	stick.moved.connect(_on_stick)
	overlay.add_child(stick)
	var shoot := make_action("SHOOT", Vector2(1090, 430), Vector2(150, 92), 19, true)
	shoot.pressed.connect(game.shoot_ball)
	var pass_button := make_action("PASS", Vector2(895, 615), Vector2(108, 62), 15, false)
	pass_button.pressed.connect(game.pass_ball)
	var through := make_action("THROUGH", Vector2(1010, 548), Vector2(128, 62), 13, false)
	through.pressed.connect(do_through)
	var dash := make_action("DASH", Vector2(1040, 635), Vector2(108, 55), 14, false)
	dash.button_down.connect(_set_dash.bind(true))
	dash.button_up.connect(_set_dash.bind(false))
	var switch_player := make_action("SWITCH", Vector2(780, 635), Vector2(108, 55), 13, false)
	switch_player.pressed.connect(game.switch_player)
	var press := make_action("PRESS", Vector2(885, 548), Vector2(105, 55), 13, false)
	press.pressed.connect(do_pressure)
	# Small controller hints.
	add_text(overlay, "MOVE", Vector2(75, 672), Vector2(80, 22), 10, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	add_text(overlay, "ACTION", Vector2(1090, 695), Vector2(150, 18), 10, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_CENTER)

func add_text(parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func make_action(text: String, pos: Vector2, button_size: Vector2, font_size: int, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = button_size
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", font_size)
	var bg := Color("#0b5f39") if primary else Color("#111c25")
	var normal := panel(Color(bg.r, bg.g, bg.b, 0.94), 30, Color(1, 1, 1, 0.18), 1)
	var hover := panel(Color(minf(bg.r + 0.08, 1.0), minf(bg.g + 0.08, 1.0), minf(bg.b + 0.08, 1.0), 0.98), 30, Color(1, 1, 1, 0.35), 1)
	var pressed := panel(Color(0.03, 0.10, 0.09, 1.0), 30, Color("#20d47f"), 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	overlay.add_child(b)
	return b

func _on_stick(value: Vector2) -> void:
	game.touch_dir = value

func _set_dash(value: bool) -> void:
	game.sprinting = value

func do_through() -> void:
	if game.finished or game.controlled == null or game.ball_owner != game.controlled:
		return
	var target: Variant = nearest_teammate()
	if target == null:
		return
	var direction: Vector3 = game.controlled.pos.direction_to(target.pos + Vector3(4.0, 0.0, 0.0))
	game.ball_velocity = direction * 18.0
	game.ball_owner = null

func do_pressure() -> void:
	if game.finished or game.controlled == null:
		return
	var nearest: Variant = nearest_opponent()
	if nearest == null:
		return
	var direction: Vector3 = game.controlled.pos.direction_to(nearest.pos)
	game.controlled.pos += direction * 0.65
	if game.ball_owner == nearest and game.controlled.pos.distance_to(nearest.pos) < 1.7:
		game.ball_owner = game.controlled

func nearest_teammate() -> Variant:
	var best: Variant = null
	var best_distance: float = 9999.0
	for p in game.home:
		if p == game.controlled:
			continue
		var d: float = game.controlled.pos.distance_to(p.pos)
		if d < best_distance:
			best_distance = d
			best = p
	return best

func nearest_opponent() -> Variant:
	var best: Variant = null
	var best_distance: float = 9999.0
	for p in game.away:
		var d: float = game.controlled.pos.distance_to(p.pos)
		if d < best_distance:
			best_distance = d
			best = p
	return best
