extends Node3D

const MATCH_LENGTH := 180.0
const PLAYER_SPEED := 6.0
const SPRINT_SPEED := 8.5
const BALL_SPEED := 16.0
const PASS_SPEED := 13.0
const SAVE_PATH := "user://street_football_pakistan.save"
const LEVEL_NAMES := ["LAHORE STREET", "KARACHI ROOFTOP", "PESHAWAR NIGHT", "ISLAMABAD CUP", "PAKISTAN FINAL"]
const LANDMARK_NAMES := ["BADSHAHI MOSQUE • LAHORE", "CLIFTON ROOFTOP • KARACHI", "BALA HISAR • PESHAWAR", "FAISAL MOSQUE • ISLAMABAD", "MINAR-E-PAKISTAN • LAHORE"]

class Player:
	var pos := Vector3.ZERO
	var home := Vector3.ZERO
	var team := 0
	var role := 0
	var pname := "Player"
	var node: Node3D
	var cooldown := 0.0
	func _init(start_pos: Vector3, team_id: int, player_role: int, player_name: String) -> void:
		pos = start_pos
		home = start_pos
		team = team_id
		role = player_role
		pname = player_name

var pakistan: Array[Player] = []
var opponents: Array[Player] = []
var controlled: Player = null
var ball_pos := Vector3.ZERO
var ball_velocity := Vector3.ZERO
var ball_owner: Player = null
var ball_node: MeshInstance3D
var score := [0, 0]
var time_left := MATCH_LENGTH
var finished := false
var message := ""
var message_time := 0.0
var current_level := 0
var coins := 500
var selected_player := 0
var game_screen := "menu"
var switch_cooldown := 0.0
var move_vector := Vector2.ZERO
var sprint_pressed := false
var world_root: Node3D
var scenery_root: Node3D
var camera: Camera3D
var ui: CanvasLayer
var screen_root: Control
var menu_root: Control
var match_root: Control
var level_root: Control
var info_root: Control
var score_label: Label
var timer_label: Label
var level_label: Label
var location_label: Label
var message_label: Label
var coins_label: Label

func _ready() -> void:
	load_save()
	create_world()
	show_menu()

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m

func box(size: Vector3, color: Color, parent: Node3D, pos: Vector3, rot_y := 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	return n

func cylinder(radius: float, height: float, color: Color, parent: Node3D, pos: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	return n

func create_world() -> void:
	world_root = Node3D.new()
	add_child(world_root)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#7aa9d6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	env_node.environment = env
	world_root.add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	world_root.add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 25.0, 27.0)
	world_root.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	create_pitch()
	create_scenery()
	create_ui()

func create_pitch() -> void:
	box(Vector3(58.0, 0.35, 40.0), Color("#182019"), world_root, Vector3(0.0, -0.45, 0.0))
	box(Vector3(46.0, 0.20, 28.0), Color("#168044"), world_root, Vector3.ZERO)
	box(Vector3(46.0, 0.06, 0.14), Color.WHITE, world_root, Vector3(0.0, 0.14, -14.0))
	box(Vector3(46.0, 0.06, 0.14), Color.WHITE, world_root, Vector3(0.0, 0.14, 14.0))
	box(Vector3(0.14, 0.06, 28.0), Color.WHITE, world_root, Vector3(-23.0, 0.14, 0.0))
	box(Vector3(0.14, 0.06, 28.0), Color.WHITE, world_root, Vector3(23.0, 0.14, 0.0))
	box(Vector3(0.12, 0.06, 28.0), Color.WHITE, world_root, Vector3(0.0, 0.14, 0.0))
	var circle := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.2
	cm.bottom_radius = 4.2
	cm.height = 0.04
	cm.radial_segments = 48
	circle.mesh = cm
	circle.material_override = material(Color.WHITE)
	circle.position = Vector3(0.0, 0.16, 0.0)
	world_root.add_child(circle)
	var inner := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = 4.0
	im.bottom_radius = 4.0
	im.height = 0.06
	im.radial_segments = 48
	inner.mesh = im
	inner.material_override = material(Color("#168044"))
	inner.position = Vector3(0.0, 0.19, 0.0)
	world_root.add_child(inner)
	create_goal(Vector3(-23.4, 0.0, 0.0))
	create_goal(Vector3(23.4, 0.0, 0.0))
	for z in [-17.0, 17.0]:
		box(Vector3(58.0, 1.8, 2.0), Color("#303943"), world_root, Vector3(0.0, 0.8, z))
		for x in range(-25, 26, 4):
			box(Vector3(2.0, 0.7, 0.8), Color("#e1b83e"), world_root, Vector3(float(x), 2.0, z))

func create_goal(pos: Vector3) -> void:
	var c := Color("#eeeeee")
	box(Vector3(0.25, 2.8, 0.25), c, world_root, pos + Vector3(0.0, 1.4, -3.4))
	box(Vector3(0.25, 2.8, 0.25), c, world_root, pos + Vector3(0.0, 1.4, 3.4))
	box(Vector3(0.25, 0.25, 6.8), c, world_root, pos + Vector3(0.0, 2.8, 0.0))

func create_scenery() -> void:
	scenery_root = Node3D.new()
	world_root.add_child(scenery_root)
	build_scenery(current_level)

func build_scenery(level: int) -> void:
	for child in scenery_root.get_children():
		child.queue_free()
	if level == 0:
		box(Vector3(14, 5, 2), Color("#b88758"), scenery_root, Vector3(0, 2.5, -19))
		for x in [-6.0, 6.0]:
			cylinder(0.7, 9, Color("#b88758"), scenery_root, Vector3(x, 4.5, -19))
	elif level == 1:
		for x in [-18.0, -9.0, 9.0, 18.0]:
			box(Vector3(5, 5, 4), Color("#69757d"), scenery_root, Vector3(x, 2.5, -19))
			cylinder(1.1, 2.0, Color("#d9dde0"), scenery_root, Vector3(x, 6, -19))
	elif level == 2:
		box(Vector3(46, 4, 2), Color("#955a3b"), scenery_root, Vector3(0, 2, -19))
		for x in [-18.0, -9.0, 9.0, 18.0]:
			cylinder(1.5, 7, Color("#955a3b"), scenery_root, Vector3(x, 3.5, -19))
	elif level == 3:
		box(Vector3(14, 5, 2), Color("#e7e3d9"), scenery_root, Vector3(0, 2.5, -19))
		for x in [-8.0, 8.0]:
			cylinder(0.45, 11, Color("#e7e3d9"), scenery_root, Vector3(x, 5.5, -19))
		box(Vector3(3, 1, 20), Color("#e7e3d9"), scenery_root, Vector3(0, 5, -19), 0.35)
	else:
		cylinder(2.0, 12, Color("#c4a06b"), scenery_root, Vector3(0, 6, -19))
		cylinder(3.0, 0.8, Color("#c4a06b"), scenery_root, Vector3(0, 12.4, -19))
		cylinder(1.1, 1.5, Color("#c4a06b"), scenery_root, Vector3(0, 13.5, -19))

func create_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	screen_root = Control.new()
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen_root)
	menu_root = make_screen(Color("#081522"))
	screen_root.add_child(menu_root)
	make_title(menu_root, "STREET FOOTBALL\nPAKISTAN", Vector2(0, 55), 46)
	make_label(menu_root, "REAL PAKISTAN LOCATIONS • 3D • OFFLINE", Vector2(0, 175), 20, Color("#c7d8ff"), true)
	var play := make_button(menu_root, "PLAY", Vector2(470, 230), Vector2(340, 64), 25)
	play.pressed.connect(start_match)
	var championship := make_button(menu_root, "CHAMPIONSHIP", Vector2(470, 305), Vector2(340, 58), 21)
	championship.pressed.connect(show_levels)
	var team := make_button(menu_root, "MY TEAM", Vector2(470, 375), Vector2(160, 54), 18)
	team.pressed.connect(show_team)
	var shop := make_button(menu_root, "SHOP", Vector2(650, 375), Vector2(160, 54), 18)
	shop.pressed.connect(show_shop)
	var settings := make_button(menu_root, "SETTINGS", Vector2(470, 442), Vector2(340, 54), 18)
	settings.pressed.connect(show_settings)
	coins_label = make_label(menu_root, "COINS: %d" % coins, Vector2(0, 520), 20, Color("#ffd45a"), true)
	match_root = Control.new()
	match_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_root.add_child(match_root)
	var hud := ColorRect.new()
	hud.color = Color(0.02, 0.04, 0.07, 0.82)
	hud.size = Vector2(1280, 82)
	match_root.add_child(hud)
	score_label = make_label(match_root, "0  -  0", Vector2(500, 14), 32, Color.WHITE, true)
	timer_label = make_label(match_root, "03:00", Vector2(1080, 18), 25, Color.WHITE, false)
	level_label = make_label(match_root, LEVEL_NAMES[0], Vector2(25, 17), 20, Color.WHITE, false)
	location_label = make_label(match_root, LANDMARK_NAMES[0], Vector2(25, 46), 12, Color("#9fb1c5"), false)
	message_label = make_label(match_root, "", Vector2(390, 300), 34, Color.WHITE, true)
	message_label.size = Vector2(500, 70)
	make_controls()
	match_root.visible = false
	level_root = make_panel()
	screen_root.add_child(level_root)
	make_title(level_root, "CHAMPIONSHIP", Vector2(0, 65), 38)
	for i in range(LEVEL_NAMES.size()):
		var level_button := make_button(level_root, "%d  %s" % [i + 1, LEVEL_NAMES[i]], Vector2(430, 150 + i * 68), Vector2(420, 55), 18)
		level_button.pressed.connect(select_level.bind(i))
	button(level_root, "BACK", Vector2(540, 515), Vector2(200, 52), 18).pressed.connect(show_menu)
	level_root.visible = false
	info_root = make_panel()
	screen_root.add_child(info_root)
	info_root.visible = false

func make_panel() -> Control:
	var panel := Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#081522")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	return panel

func make_title(parent: Control, text: String, pos: Vector2, size: int) -> Label:
	var l := make_label(parent, text, pos, size, Color.WHITE, true)
	l.size = Vector2(1280, 110)
	return l

func make_label(parent: Control, text: String, pos: Vector2, size: int, color: Color, centered: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if centered:
		l.size = Vector2(1280, 60)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

func make_button(parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b

func make_controls() -> void:
	var up := make_button(match_root, "▲", Vector2(75, 515), Vector2(70, 55), 20)
	var down := make_button(match_root, "▼", Vector2(75, 635), Vector2(70, 55), 20)
	var left := make_button(match_root, "◀", Vector2(5, 575), Vector2(70, 55), 20)
	var right := make_button(match_root, "▶", Vector2(145, 575), Vector2(70, 55), 20)
	up.button_down.connect(func(): move_vector = Vector2(0, -1))
	up.button_up.connect(clear_move)
	down.button_down.connect(func(): move_vector = Vector2(0, 1))
	down.button_up.connect(clear_move)
	left.button_down.connect(func(): move_vector = Vector2(-1, 0))
	left.button_up.connect(clear_move)
	right.button_down.connect(func(): move_vector = Vector2(1, 0))
	right.button_up.connect(clear_move)
	var sprint := make_button(match_root, "SPRINT", Vector2(235, 610), Vector2(115, 62), 16)
	sprint.button_down.connect(func(): sprint_pressed = true)
	sprint.button_up.connect(func(): sprint_pressed = false)
	make_button(match_root, "PASS", Vector2(820, 610), Vector2(110, 65), 18).pressed.connect(pass_ball)
	make_button(match_root, "SWITCH", Vector2(940, 610), Vector2(110, 65), 15).pressed.connect(switch_player)
	make_button(match_root, "SHOOT", Vector2(1060, 515), Vector2(150, 95), 22).pressed.connect(shoot_ball)
	make_button(match_root, "MENU", Vector2(1090, 12), Vector2(90, 42), 14).pressed.connect(show_menu)

func clear_move() -> void:
	move_vector = Vector2.ZERO

func show_menu() -> void:
	game_screen = "menu"
	menu_root.visible = true
	match_root.visible = false
	level_root.visible = false
	info_root.visible = false
	if coins_label != null:
		coins_label.text = "COINS: %d" % coins

func show_levels() -> void:
	game_screen = "levels"
	menu_root.visible = false
	match_root.visible = false
	level_root.visible = true
	info_root.visible = false

func select_level(index: int) -> void:
	current_level = clampi(index, 0, LEVEL_NAMES.size() - 1)
	build_location_scenery(current_level)
	start_match()

func start_match() -> void:
	game_screen = "match"
	menu_root.visible = false
	level_root.visible = false
	info_root.visible = false
	match_root.visible = true
	build_location_scenery(current_level)
	reset_match()

func show_team() -> void:
	show_info("MY TEAM", "AYAAN • Captain\nHAMZA • Speedster\nDANIYAL • Sniper\nSHAHZAIB • Playmaker\nAKBAR • Defender\nSAAD • Goalkeeper")

func show_shop() -> void:
	show_info("SHOP", "COINS: %d\n\nGREEN STREET KIT — 250\nGOLDEN BALL — 350\nNIGHT BOOTS — 400\n\nCosmetics only." % coins)

func show_settings() -> void:
	show_info("SETTINGS", "ANDROID PERFORMANCE\n\nCompatibility renderer\nLow-poly procedural 3D\nOffline save\nTouch + keyboard controls")

func show_info(title: String, body: String) -> void:
	game_screen = "info"
	menu_root.visible = false
	match_root.visible = false
	level_root.visible = false
	info_root.visible = true
	for child in info_root.get_children():
		child.queue_free()
	make_title(info_root, title, Vector2(0, 65), 38)
	var body_label := make_label(info_root, body, Vector2(300, 180), 21, Color("#d7e3f0"), true)
	body_label.size = Vector2(680, 300)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	make_button(info_root, "BACK", Vector2(540, 535), Vector2(200, 54), 18).pressed.connect(show_menu)

func reset_match() -> void:
	clear_players()
	score = [0, 0]
	time_left = MATCH_LENGTH
	finished = false
	message = "KICK OFF!"
	message_time = 1.5
	move_vector = Vector2.ZERO
	sprint_pressed = false
	switch_cooldown = 0.0
	var positions := [Vector3(-12, 0, 0), Vector3(-7, 0, -5), Vector3(-7, 0, 5)]
	var names := ["Hamza", "Daniyal", "Shahzaib"]
	for i in range(3):
		var p := Player.new(positions[i], 0, i, names[i])
		pakistan.append(p)
		p.node = create_player(p)
	var enemy_positions := [Vector3(12, 0, 0), Vector3(7, 0, -5), Vector3(7, 0, 5)]
	for i in range(3):
		var e := Player.new(enemy_positions[i], 1, i, "Opponent %d" % (i + 1))
		opponents.append(e)
		e.node = create_player(e)
	selected_player = clampi(selected_player, 0, 2)
	controlled = pakistan[selected_player]
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = controlled
	create_ball()
	update_visuals()
	update_hud()

func create_player(p: Player) -> Node3D:
	var root := Node3D.new()
	world_root.add_child(root)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.65
	capsule.height = 1.9
	capsule.radial_segments = 12
	body.mesh = capsule
	body.material_override = make_material(Color("#11a653") if p.team == 0 else Color("#d63232"))
	body.position.y = 1.0
	root.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.36
	head_mesh.height = 0.72
	head_mesh.radial_segments = 12
	head.mesh = head_mesh
	head.material_override = make_material(Color("#d99b74"))
	head.position.y = 2.2
	root.add_child(head)
	var number := Label3D.new()
	number.text = str(p.role + 1)
	number.font_size = 64
	number.modulate = Color.WHITE
	number.position = Vector3(0, 1.15, 0.68)
	root.add_child(number)
	root.position = p.pos
	return root

func create_ball() -> void:
	if is_instance_valid(ball_node):
		ball_node.queue_free()
	ball_node = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	sphere.radial_segments = 16
	sphere.rings = 8
	ball_node.mesh = sphere
	ball_node.material_override = make_material(Color.WHITE)
	world_root.add_child(ball_node)

func clear_players() -> void:
	for p in pakistan:
		if is_instance_valid(p.node):
			p.node.queue_free()
	for e in opponents:
		if is_instance_valid(e.node):
			e.node.queue_free()
	pakistan.clear()
	opponents.clear()

func _process(delta: float) -> void:
	if game_screen != "match":
		return
	if finished:
		update_hud()
		update_visuals()
		return
	time_left = maxf(0.0, time_left - delta)
	switch_cooldown = maxf(0.0, switch_cooldown - delta)
	if time_left <= 0.0:
		finished = true
		message = "FULL TIME"
		message_time = 999.0
		update_hud()
		return
	update_human(delta)
	update_ai(delta)
	update_ball(delta)
	check_goal()
	message_time = maxf(0.0, message_time - delta)
	update_visuals()
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if game_screen != "match":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			shoot_ball()
		elif event.keycode == KEY_E or event.keycode == KEY_TAB:
			switch_player()
		elif event.keycode == KEY_Q:
			pass_ball()
		elif event.keycode == KEY_R and finished:
			reset_match()

func move_direction() -> Vector3:
	var x := Input.get_axis("ui_left", "ui_right")
	var z := Input.get_axis("ui_up", "ui_down")
	var d := Vector3(x, 0, z)
	if move_vector.length() > 0.05:
		d = Vector3(move_vector.x, 0, move_vector.y)
	return d.normalized() if d.length() > 0.05 else Vector3.ZERO

func update_human(delta: float) -> void:
	if controlled == null or not is_instance_valid(controlled.node):
		return
	var d := move_direction()
	var speed := SPRINT_SPEED if sprint_pressed or Input.is_key_pressed(KEY_SHIFT) else PLAYER_SPEED
	if d != Vector3.ZERO:
		controlled.pos += d * speed * delta
		controlled.pos.x = clampf(controlled.pos.x, -21.0, 21.0)
		controlled.pos.z = clampf(controlled.pos.z, -12.0, 12.0)
	if ball_owner == null and controlled.pos.distance_to(ball_pos) < 1.5:
		ball_owner = controlled
	if ball_owner == controlled:
		ball_pos = controlled.pos + (d if d != Vector3.ZERO else Vector3.RIGHT) * 1.0

func update_ai(delta: float) -> void:
	var all: Array[Player] = pakistan + opponents
	for p in all:
		if p == controlled:
			continue
		p.cooldown = maxf(0.0, p.cooldown - delta)
		var target := p.home
		var nearest := closest_player(p.team)
		if ball_owner == null and nearest == p:
			target = ball_pos
		elif ball_owner != null and ball_owner.team == p.team:
			target = p.home.lerp(ball_owner.pos, 0.3)
		else:
			target = p.home.lerp(ball_pos, 0.15)
		var d := p.pos.direction_to(target)
		if d.length() > 0.08:
			p.pos += d * 4.8 * delta
			p.pos.x = clampf(p.pos.x, -21.0, 21.0)
			p.pos.z = clampf(p.pos.z, -12.0, 12.0)
		if ball_owner == null and p.pos.distance_to(ball_pos) < 1.25:
			ball_owner = p
		if ball_owner == p:
			var goal := Vector3(23, 0, 0) if p.team == 0 else Vector3(-23, 0, 0)
			ball_pos = p.pos + p.pos.direction_to(goal) * 1.0
			if p.pos.distance_to(goal) < 9.0 and p.cooldown <= 0.0:
				ball_velocity = p.pos.direction_to(goal) * BALL_SPEED
				ball_owner = null
				p.cooldown = 1.2

func closest_player(team: int) -> Player:
	var list: Array[Player] = pakistan if team == 0 else opponents
	if list.is_empty():
		return null
	var best := list[0]
	var best_d := best.pos.distance_to(ball_pos)
	for p in list:
		var d := p.pos.distance_to(ball_pos)
		if d < best_d:
			best = p
			best_d = d
	return best

func update_ball(delta: float) -> void:
	if ball_owner != null:
		return
	ball_pos += ball_velocity * delta
	ball_velocity = ball_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	if absf(ball_pos.z) > 13.2:
		ball_pos.z = clampf(ball_pos.z, -13.2, 13.2)
		ball_velocity.z *= -0.7

func check_goal() -> void:
	if ball_pos.x < -23.0 and absf(ball_pos.z) < 3.4:
		score[1] += 1
		coins += 25
		message = "OPPONENT SCORES"
		message_time = 2.0
		kickoff()
	elif ball_pos.x > 23.0 and absf(ball_pos.z) < 3.4:
		score[0] += 1
		coins += 50
		message = "PAKISTAN SCORES!"
		message_time = 2.0
		kickoff()
	elif absf(ball_pos.x) > 23.0:
		ball_pos.x = clampf(ball_pos.x, -22.5, 22.5)
		ball_velocity.x *= -0.75

func kickoff() -> void:
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = controlled
	for p in pakistan:
		p.pos = p.home
	for e in opponents:
		e.pos = e.home

func shoot_ball() -> void:
	if finished or controlled == null or ball_owner != controlled:
		return
	var d := move_direction()
	if d == Vector3.ZERO:
		d = Vector3.RIGHT
	ball_velocity = d * BALL_SPEED
	ball_owner = null
	message = "SHOOT!"
	message_time = 0.5

func pass_ball() -> void:
	if finished or controlled == null or ball_owner != controlled:
		return
	var teammate: Player = null
	var best := 9999.0
	for p in pakistan:
		if p == controlled:
			continue
		var d := controlled.pos.distance_to(p.pos)
		if d < best:
			best = d
			teammate = p
	if teammate == null:
		return
	ball_velocity = controlled.pos.direction_to(teammate.pos) * PASS_SPEED
	ball_owner = null
	message = "PASS"
	message_time = 0.5

func switch_player() -> void:
	if finished or pakistan.is_empty() or switch_cooldown > 0.0:
		return
	selected_player = (selected_player + 1) % pakistan.size()
	controlled = pakistan[selected_player]
	switch_cooldown = 0.25
	message = controlled.pname
	message_time = 0.6

func update_visuals() -> void:
	for p in pakistan:
		if is_instance_valid(p.node):
			p.node.position = p.pos
	for e in opponents:
		if is_instance_valid(e.node):
			e.node.position = e.pos
	if is_instance_valid(ball_node):
		ball_node.position = ball_pos + Vector3(0, 0.48, 0)

func update_hud() -> void:
	if score_label == null:
		return
	score_label.text = "%d  -  %d" % [score[0], score[1]]
	var total := int(ceil(time_left))
	timer_label.text = "%02d:%02d" % [total / 60, total % 60]
	level_label.text = LEVEL_NAMES[current_level]
	location_label.text = LANDMARK_NAMES[current_level]
	message_label.text = message if message_time > 0.0 else ""

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = f.get_var()
	if data is Dictionary:
		coins = int(data.get("coins", 500))
		selected_player = clampi(int(data.get("selected_player", 0)), 0, 2)
	f.close()

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_var({"coins": coins, "selected_player": selected_player})
		f.close()
