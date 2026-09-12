extends Node3D

const MATCH_LENGTH := 180.0
const PLAYER_SPEED := 6.0
const SPRINT_SPEED := 8.5
const BALL_SPEED := 15.0
const PASS_SPEED := 12.0
const SAVE_PATH := "user://street_football_pakistan.save"
const LEVEL_NAMES := ["LAHORE STREET", "KARACHI ROOFTOP", "PESHAWAR NIGHT", "ISLAMABAD CUP", "PAKISTAN FINAL"]
const LANDMARK_NAMES := ["BADSHAHI MOSQUE • LAHORE", "KARACHI ROOFTOP • CLIFTON", "BALA HISAR • PESHAWAR", "FAISAL MOSQUE • ISLAMABAD", "MINAR-E-PAKISTAN • LAHORE"]

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

var camera: Camera3D
var world_root: Node3D
var scenery_root: Node3D
var ui: CanvasLayer
var screen_root: Control
var menu_root: Control
var match_root: Control
var level_root: Control
var info_root: Control
var score_label: Label
var timer_label: Label
var message_label: Label
var level_label: Label
var coins_label: Label
var location_label: Label
var move_vector := Vector2.ZERO
var sprint_pressed := false
var switch_cooldown := 0.0

func _ready() -> void:
	load_save()
	create_world()
	show_menu()

func make_material(color: Color, metallic := 0.0, roughness := 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat

func make_box(size: Vector3, color: Color, parent: Node3D, pos: Vector3, y_rot := 0.0) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = make_material(color)
	item.position = pos
	item.rotation.y = y_rot
	parent.add_child(item)
	return item

func make_cylinder(radius: float, height: float, color: Color, parent: Node3D, pos: Vector3) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	item.mesh = mesh
	item.material_override = make_material(color)
	item.position = pos
	parent.add_child(item)
	return item

func create_world() -> void:
	world_root = Node3D.new()
	add_child(world_root)
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#081522")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c8dcff")
	env.ambient_light_energy = 0.85
	world_env.environment = env
	world_root.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -25.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	world_root.add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 20.0, 22.0)
	camera.current = true
	world_root.add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	create_field()
	create_stands()
	create_scenery()
	create_ui()

func create_field() -> void:
	make_box(Vector3(52.0, 0.3, 34.0), Color("#0b1511"), world_root, Vector3(0.0, -0.35, 0.0))
	make_box(Vector3(42.0, 0.18, 24.0), Color("#176b3b"), world_root, Vector3.ZERO)
	make_box(Vector3(42.0, 0.05, 0.12), Color.WHITE, world_root, Vector3(0.0, 0.12, -12.0))
	make_box(Vector3(42.0, 0.05, 0.12), Color.WHITE, world_root, Vector3(0.0, 0.12, 12.0))
	make_box(Vector3(0.12, 0.05, 24.0), Color.WHITE, world_root, Vector3(-21.0, 0.12, 0.0))
	make_box(Vector3(0.12, 0.05, 24.0), Color.WHITE, world_root, Vector3(21.0, 0.12, 0.0))
	make_box(Vector3(0.10, 0.05, 24.0), Color.WHITE, world_root, Vector3(0.0, 0.12, 0.0))
	make_box(Vector3(7.0, 0.05, 0.10), Color.WHITE, world_root, Vector3(-17.5, 0.12, -3.2))
	make_box(Vector3(7.0, 0.05, 0.10), Color.WHITE, world_root, Vector3(-17.5, 0.12, 3.2))
	make_box(Vector3(7.0, 0.05, 0.10), Color.WHITE, world_root, Vector3(17.5, 0.12, -3.2))
	make_box(Vector3(7.0, 0.05, 0.10), Color.WHITE, world_root, Vector3(17.5, 0.12, 3.2))
	make_box(Vector3(0.10, 0.05, 6.4), Color.WHITE, world_root, Vector3(-14.0, 0.12, 0.0))
	make_box(Vector3(0.10, 0.05, 6.4), Color.WHITE, world_root, Vector3(14.0, 0.12, 0.0))
	var circle_outer := MeshInstance3D.new()
	var outer := CylinderMesh.new()
	outer.top_radius = 4.0
	outer.bottom_radius = 4.0
	outer.height = 0.04
	outer.radial_segments = 32
	circle_outer.mesh = outer
	circle_outer.material_override = make_material(Color.WHITE)
	circle_outer.position = Vector3(0.0, 0.10, 0.0)
	world_root.add_child(circle_outer)
	var circle_inner := MeshInstance3D.new()
	var inner := CylinderMesh.new()
	inner.top_radius = 3.82
	inner.bottom_radius = 3.82
	inner.height = 0.06
	inner.radial_segments = 32
	circle_inner.mesh = inner
	circle_inner.material_override = make_material(Color("#176b3b"))
	circle_inner.position = Vector3(0.0, 0.13, 0.0)
	world_root.add_child(circle_inner)
	create_goal(Vector3(-21.7, 0.0, 0.0))
	create_goal(Vector3(21.7, 0.0, 0.0))

func create_goal(pos: Vector3) -> void:
	var goal_color := Color("#e8e8e8")
	make_box(Vector3(0.25, 2.4, 0.25), goal_color, world_root, pos + Vector3(0.0, 1.2, -3.2))
	make_box(Vector3(0.25, 2.4, 0.25), goal_color, world_root, pos + Vector3(0.0, 1.2, 3.2))
	make_box(Vector3(0.25, 0.25, 6.5), goal_color, world_root, pos + Vector3(0.0, 2.4, 0.0))

func create_stands() -> void:
	for z in [-15.0, 15.0]:
		make_box(Vector3(48.0, 1.4, 2.0), Color("#252b34"), world_root, Vector3(0.0, 0.5, z))
		for x in range(-20, 21, 4):
			make_box(Vector3(2.2, 0.8, 0.8), Color("#d7a62b"), world_root, Vector3(float(x), 1.5, z))

func create_scenery() -> void:
	scenery_root = Node3D.new()
	world_root.add_child(scenery_root)
	build_location_scenery(current_level)

func clear_scenery() -> void:
	if is_instance_valid(scenery_root):
		for child in scenery_root.get_children():
			child.queue_free()

func build_location_scenery(level: int) -> void:
	clear_scenery()
	if level == 0:
		build_lahore_badshahi()
	elif level == 1:
		build_karachi_rooftop()
	elif level == 2:
		build_peshawar_balahisar()
	elif level == 3:
		build_islamabad_faisal()
	else:
		build_lahore_minar()

func build_lahore_badshahi() -> void:
	var stone := Color("#b8895b")
	make_box(Vector3(12.0, 4.0, 2.0), stone, scenery_root, Vector3(0.0, 2.0, -17.0))
	for x in [-5.0, 5.0]:
		make_cylinder(0.65, 8.0, stone, scenery_root, Vector3(x, 4.0, -18.0))
		make_cylinder(1.0, 0.7, Color("#d6ad6b"), scenery_root, Vector3(x, 8.2, -18.0))
	make_box(Vector3(16.0, 0.5, 2.5), Color("#6e452e"), scenery_root, Vector3(0.0, 0.25, -19.0))
	make_box(Vector3(48.0, 3.0, 0.8), Color("#8f6c48"), scenery_root, Vector3(0.0, 1.5, 17.0))

func build_karachi_rooftop() -> void:
	var concrete := Color("#65727c")
	for x in [-19.0, -10.0, 10.0, 19.0]:
		make_box(Vector3(6.0, 5.0, 4.0), concrete, scenery_root, Vector3(x, 2.5, -17.0))
		make_cylinder(1.2, 2.2, Color("#d8dce0"), scenery_root, Vector3(x, 6.0, -17.0))
	make_box(Vector3(48.0, 2.0, 0.8), Color("#d08a48"), scenery_root, Vector3(0.0, 1.0, 17.0))
	for x in range(-20, 21, 5):
		make_box(Vector3(0.18, 2.2, 0.18), Color("#1e252c"), scenery_root, Vector3(float(x), 2.1, 16.4))

func build_peshawar_balahisar() -> void:
	var brick := Color("#9a5d3b")
	make_box(Vector3(42.0, 3.5, 1.5), brick, scenery_root, Vector3(0.0, 1.75, -17.0))
	for x in [-16.0, -8.0, 8.0, 16.0]:
		make_cylinder(1.7, 6.5, brick, scenery_root, Vector3(x, 3.25, -17.0))
	make_box(Vector3(12.0, 5.0, 2.0), Color("#6f432d"), scenery_root, Vector3(0.0, 2.5, 17.0))
	make_box(Vector3(5.0, 2.2, 0.8), Color("#d0a45e"), scenery_root, Vector3(0.0, 5.8, 17.0))

func build_islamabad_faisal() -> void:
	var white := Color("#e8e5dc")
	make_box(Vector3(13.0, 4.0, 2.0), white, scenery_root, Vector3(0.0, 2.0, -18.0))
	for x in [-8.0, 8.0]:
		make_cylinder(0.45, 10.0, white, scenery_root, Vector3(x, 5.0, -18.0))
	for x in [-5.5, 5.5]:
		make_box(Vector3(1.0, 9.0, 1.0), white, scenery_root, Vector3(x, 4.5, -18.0), 0.55)
	make_box(Vector3(48.0, 1.0, 1.0), Color("#385c39"), scenery_root, Vector3(0.0, 0.5, 17.0))

func build_lahore_minar() -> void:
	var sand := Color("#c5a16c")
	make_cylinder(1.8, 11.0, sand, scenery_root, Vector3(0.0, 5.5, -18.0))
	make_cylinder(2.8, 0.8, sand, scenery_root, Vector3(0.0, 10.8, -18.0))
	make_cylinder(1.0, 1.5, sand, scenery_root, Vector3(0.0, 12.0, -18.0))
	make_box(Vector3(30.0, 1.2, 1.5), Color("#7b5d3a"), scenery_root, Vector3(0.0, 0.6, 17.0))

func create_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	screen_root = Control.new()
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen_root)
	menu_root = make_panel()
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
	make_label(menu_root, "5 real-city-inspired arenas • 3v3 • 3-minute matches", Vector2(0, 575), 16, Color("#9fb1c5"), true)
	match_root = make_panel()
	screen_root.add_child(match_root)
	var top := ColorRect.new()
	top.color = Color(0.02, 0.04, 0.07, 0.90)
	top.size = Vector2(1280, 82)
	match_root.add_child(top)
	score_label = make_label(match_root, "0  -  0", Vector2(0, 15), 32, Color.WHITE, true)
	timer_label = make_label(match_root, "03:00", Vector2(1060, 15), 27, Color.WHITE, false)
	level_label = make_label(match_root, LEVEL_NAMES[current_level], Vector2(28, 20), 21, Color("#dce9f8"), false)
	location_label = make_label(match_root, LANDMARK_NAMES[current_level], Vector2(28, 47), 13, Color("#9fb1c5"), false)
	message_label = make_label(match_root, "", Vector2(390, 285), 34, Color.WHITE, true)
	message_label.size = Vector2(500, 120)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	make_touch_controls()
	match_root.visible = false
	level_root = make_panel()
	screen_root.add_child(level_root)
	make_title(level_root, "CHAMPIONSHIP", Vector2(0, 65), 38)
	for i in range(LEVEL_NAMES.size()):
		var level_button := make_button(level_root, "%d  %s" % [i + 1, LEVEL_NAMES[i]], Vector2(430, 150 + i * 68), Vector2(420, 55), 19)
		level_button.pressed.connect(select_level.bind(i))
	var back := make_button(level_root, "BACK", Vector2(540, 515), Vector2(200, 52), 18)
	back.pressed.connect(show_menu)
	level_root.visible = false
	info_root = make_panel()
	screen_root.add_child(info_root)
	info_root.visible = false

func make_panel() -> Control:
	var panel := Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#0b1622")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	return panel

func make_title(parent: Control, text: String, pos: Vector2, size: int) -> Label:
	var label := make_label(parent, text, pos, size, Color.WHITE, true)
	label.size = Vector2(1280, 110)
	return label

func make_label(parent: Control, text: String, pos: Vector2, size: int, color: Color, centered: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if centered:
		label.size = Vector2(1280, 55)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func make_button(parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", font_size)
	parent.add_child(button)
	return button

func make_touch_controls() -> void:
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
	var pass_button := make_button(match_root, "PASS", Vector2(820, 610), Vector2(110, 65), 18)
	pass_button.pressed.connect(pass_ball)
	var switcher := make_button(match_root, "SWITCH", Vector2(940, 610), Vector2(110, 65), 16)
	switcher.pressed.connect(switch_player)
	var shoot := make_button(match_root, "SHOOT", Vector2(1060, 515), Vector2(150, 95), 22)
	shoot.pressed.connect(shoot_ball)
	var exit := make_button(match_root, "MENU", Vector2(1090, 12), Vector2(90, 42), 14)
	exit.pressed.connect(show_menu)

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
	save_game()

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
	show_info("MY TEAM", "AYAAN • Captain\nHAMZA • Speedster\nDANIYAL • Sniper\nSHAHZAIB • Playmaker\nAKBAR • Defender\nSAAD • Goalkeeper\n\nOffline roster with cosmetic progression.")

func show_shop() -> void:
	show_info("SHOP", "COINS: %d\n\nGREEN STREET KIT — 250\nGOLDEN BALL — 350\nNIGHT BOOTS — 400\n\nCosmetics only. No pay-to-win stats." % coins)

func show_settings() -> void:
	show_info("SETTINGS", "PERFORMANCE\n\nCompatibility renderer is selected for broad Android support.\nLow-poly procedural 3D keeps draw cost small.\nProgress saves locally on the device.\nTouch + keyboard input enabled.")

func show_info(title: String, body: String) -> void:
	game_screen = "info"
	menu_root.visible = false
	match_root.visible = false
	level_root.visible = false
	info_root.visible = true
	for child in info_root.get_children():
		if child is Label or child is Button:
			child.queue_free()
	make_title(info_root, title, Vector2(0, 65), 38)
	var body_label := make_label(info_root, body, Vector2(300, 170), 21, Color("#d7e3f0"), true)
	body_label.size = Vector2(680, 300)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var back := make_button(info_root, "BACK", Vector2(540, 535), Vector2(200, 54), 18)
	back.pressed.connect(show_menu)

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
	var positions := [Vector3(-12.0, 0.0, 0.0), Vector3(-7.0, 0.0, -5.0), Vector3(-7.0, 0.0, 5.0)]
	var names := ["Hamza", "Daniyal", "Shahzaib"]
	for i in range(3):
		var player := Player.new(positions[i], 0, i, names[i])
		pakistan.append(player)
		player.node = create_player_visual(player)
	var enemy_positions := [Vector3(12.0, 0.0, 0.0), Vector3(7.0, 0.0, -5.0), Vector3(7.0, 0.0, 5.0)]
	for i in range(3):
		var enemy := Player.new(enemy_positions[i], 1, i, "Opponent %d" % (i + 1))
		opponents.append(enemy)
		enemy.node = create_player_visual(enemy)
	selected_player = clampi(selected_player, 0, 2)
	controlled = pakistan[selected_player]
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = null
	create_ball()
	update_hud()
	update_visuals()

func create_ball() -> void:
	if is_instance_valid(ball_node):
		ball_node.queue_free()
	ball_node = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	sphere.height = 0.84
	sphere.radial_segments = 12
	sphere.rings = 6
	ball_node.mesh = sphere
	ball_node.material_override = make_material(Color("#f4f4f4"), 0.05, 0.3)
	world_root.add_child(ball_node)

func clear_players() -> void:
	for player in pakistan:
		if is_instance_valid(player.node):
			player.node.queue_free()
	for enemy in opponents:
		if is_instance_valid(enemy.node):
			enemy.node.queue_free()
	pakistan.clear()
	opponents.clear()

func create_player_visual(player: Player) -> Node3D:
	var root := Node3D.new()
	world_root.add_child(root)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.55
	capsule.height = 1.6
	capsule.radial_segments = 10
	body.mesh = capsule
	body.material_override = make_material(Color("#178a4a") if player.team == 0 else Color("#c73838"))
	body.position.y = 0.9
	root.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.64
	head_mesh.radial_segments = 10
	head.mesh = head_mesh
	head.material_override = make_material(Color("#d99a72"))
	head.position.y = 1.95
	root.add_child(head)
	var shirt_number := Label3D.new()
	shirt_number.text = str(player.role + 1)
	shirt_number.font_size = 48
	shirt_number.modulate = Color.WHITE
	shirt_number.position = Vector3(0.0, 1.0, 0.57)
	root.add_child(shirt_number)
	root.position = player.pos
	return root

func _process(delta: float) -> void:
	if game_screen != "match":
		return
	if finished:
		update_hud()
		update_visuals()
		return
	time_left = max(0.0, time_left - delta)
	switch_cooldown = max(0.0, switch_cooldown - delta)
	if time_left <= 0.0:
		finished = true
		message = "FULL TIME"
		message_time = 999.0
	else:
		update_human(delta)
		update_ai(delta)
		update_ball(delta)
		check_goal()
	message_time = max(0.0, message_time - delta)
	update_hud()
	update_visuals()

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

func get_move_direction() -> Vector3:
	var x := Input.get_axis("ui_left", "ui_right")
	var z := Input.get_axis("ui_up", "ui_down")
	var direction := Vector3(x, 0.0, z)
	if move_vector.length() > 0.05:
		direction = Vector3(move_vector.x, 0.0, move_vector.y)
	return direction.normalized() if direction.length() > 0.05 else Vector3.ZERO

func update_human(delta: float) -> void:
	if controlled == null:
		return
	var direction := get_move_direction()
	var sprinting := sprint_pressed or Input.is_key_pressed(KEY_SHIFT)
	var speed := SPRINT_SPEED if sprinting else PLAYER_SPEED
	if direction != Vector3.ZERO:
		controlled.pos += direction * speed * delta
		controlled.pos.x = clamp(controlled.pos.x, -20.0, 20.0)
		controlled.pos.z = clamp(controlled.pos.z, -10.5, 10.5)
		controlled.node.rotation.y = lerp_angle(controlled.node.rotation.y, atan2(direction.x, direction.z), min(1.0, delta * 10.0))
		if ball_owner == controlled:
			ball_pos = controlled.pos + direction * 1.15
	if ball_owner == null and controlled.pos.distance_to(ball_pos) < 1.35:
		ball_owner = controlled

func update_ai(delta: float) -> void:
	var all_players: Array[Player] = pakistan + opponents
	for player in all_players:
		if player == controlled:
			continue
		player.cooldown = max(0.0, player.cooldown - delta)
		var target := player.home
		var nearest := closest_player(player.team)
		if ball_owner != null and ball_owner.team == player.team:
			if player != ball_owner:
				target = player.home.lerp(ball_owner.pos, 0.25)
		elif nearest == player:
			target = ball_pos
		else:
			target = player.home.lerp(ball_pos, 0.16 + float(player.role) * 0.03)
		var direction := player.pos.direction_to(target)
		if direction.length() > 0.05:
			player.pos += direction * (5.0 if player.team == 0 else 5.3) * delta
			player.pos.x = clamp(player.pos.x, -20.0, 20.0)
			player.pos.z = clamp(player.pos.z, -10.5, 10.5)
			player.node.rotation.y = atan2(direction.x, direction.z)
		if ball_owner == null and player.pos.distance_to(ball_pos) < 1.1:
			ball_owner = player
		if ball_owner == player:
			var target_goal := Vector3(21.5, 0.0, 0.0) if player.team == 0 else Vector3(-21.5, 0.0, 0.0)
			ball_pos = player.pos + player.pos.direction_to(target_goal) * 1.05
			if player.pos.distance_to(target_goal) < 8.5 and player.cooldown <= 0.0:
				ball_velocity = player.pos.direction_to(target_goal) * BALL_SPEED
				ball_owner = null
				player.cooldown = 1.3

func closest_player(team_id: int) -> Player:
	var list: Array[Player] = pakistan if team_id == 0 else opponents
	if list.is_empty():
		return null
	var best: Player = list[0]
	var best_distance := best.pos.distance_to(ball_pos)
	for player in list:
		var distance := player.pos.distance_to(ball_pos)
		if distance < best_distance:
			best_distance = distance
			best = player
	return best

func nearest_teammate() -> Player:
	var best: Player = null
	var best_distance := 9999.0
	for player in pakistan:
		if player == controlled:
			continue
		var distance := controlled.pos.distance_to(player.pos)
		if distance < best_distance:
			best_distance = distance
			best = player
	return best

func update_ball(delta: float) -> void:
	if ball_owner != null:
		return
	ball_pos += ball_velocity * delta
	ball_velocity = ball_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
	if abs(ball_pos.z) > 11.6:
		ball_pos.z = clamp(ball_pos.z, -11.6, 11.6)
		ball_velocity.z *= -0.7
	if abs(ball_pos.x) > 23.5:
		ball_pos.x = clamp(ball_pos.x, -23.5, 23.5)
		ball_velocity.x *= -0.75

func check_goal() -> void:
	if ball_pos.x < -22.0 and abs(ball_pos.z) < 3.25:
		score[1] += 1
		coins += 25
		message = "OPPONENT SCORES"
		message_time = 2.0
		kickoff()
	elif ball_pos.x > 22.0 and abs(ball_pos.z) < 3.25:
		score[0] += 1
		coins += 50
		message = "PAKISTAN SCORES!"
		message_time = 2.0
		kickoff()
	elif abs(ball_pos.x) > 22.0:
		ball_pos.x = clamp(ball_pos.x, -22.0, 22.0)
		ball_velocity.x *= -0.8

func kickoff() -> void:
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = null
	for player in pakistan:
		player.pos = player.home
	for enemy in opponents:
		enemy.pos = enemy.home
	save_game()

func shoot_ball() -> void:
	if game_screen != "match" or finished or controlled == null or ball_owner != controlled:
		return
	var direction := get_move_direction()
	if direction == Vector3.ZERO:
		direction = Vector3.RIGHT
	ball_velocity = direction * BALL_SPEED
	ball_owner = null
	message = "SHOOT!"
	message_time = 0.45

func pass_ball() -> void:
	if game_screen != "match" or finished or controlled == null or ball_owner != controlled:
		return
	var teammate := nearest_teammate()
	if teammate == null:
		return
	var direction := controlled.pos.direction_to(teammate.pos)
	ball_velocity = direction * PASS_SPEED
	ball_owner = null
	message = "PASS"
	message_time = 0.45

func switch_player() -> void:
	if game_screen != "match" or finished or pakistan.is_empty() or switch_cooldown > 0.0:
		return
	selected_player = (selected_player + 1) % pakistan.size()
	controlled = pakistan[selected_player]
	switch_cooldown = 0.25
	message = controlled.pname
	message_time = 0.55

func update_visuals() -> void:
	for player in pakistan:
		if is_instance_valid(player.node):
			player.node.position = player.pos
	for enemy in opponents:
		if is_instance_valid(enemy.node):
			enemy.node.position = enemy.pos
	if is_instance_valid(ball_node):
		ball_node.position = ball_pos + Vector3(0.0, 0.42, 0.0)

func update_hud() -> void:
	if score_label == null:
		return
	score_label.text = "%d  -  %d" % [score[0], score[1]]
	var total_seconds := int(ceil(time_left))
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	level_label.text = LEVEL_NAMES[current_level]
	location_label.text = LANDMARK_NAMES[current_level]
	message_label.text = message if message_time > 0.0 else ""

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = file.get_var()
	if data is Dictionary:
		coins = int(data.get("coins", 500))
		selected_player = clampi(int(data.get("selected_player", 0)), 0, 2)
	file.close()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_var({"coins": coins, "selected_player": selected_player})
	file.close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
