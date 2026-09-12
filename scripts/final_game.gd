extends Node3D

const MATCH_TIME := 180.0
const SPEED := 6.0
const SPRINT := 8.5
const BALL := 16.0
const PASS := 13.0
const LEVELS := ["LAHORE STREET", "KARACHI ROOFTOP", "PESHAWAR NIGHT", "ISLAMABAD CUP", "PAKISTAN FINAL"]
const LANDMARKS := ["BADSHAHI MOSQUE • LAHORE", "CLIFTON ROOFTOP • KARACHI", "BALA HISAR • PESHAWAR", "FAISAL MOSQUE • ISLAMABAD", "MINAR-E-PAKISTAN • LAHORE"]

class Player:
	var pos := Vector3.ZERO
	var home := Vector3.ZERO
	var team := 0
	var pname := "Player"
	var node: Node3D
	func _init(p: Vector3, t: int, n: String) -> void:
		pos = p
		home = p
		team = t
		pname = n

var home: Array = []
var away: Array = []
var controlled: Player
var selected := 0
var ball_pos := Vector3.ZERO
var ball_velocity := Vector3.ZERO
var ball_owner: Player
var ball_node: MeshInstance3D
var score := [0, 0]
var time_left := MATCH_TIME
var finished := false
var sprinting := false
var touch_dir := Vector2.ZERO
var switch_lock := 0.0
var world: Node3D
var camera: Camera3D
var ui: Control
var score_label: Label
var time_label: Label
var location_label: Label
var message_label: Label

func _ready() -> void:
	build_world()
	build_ui()
	reset_match()

func mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m

func box(s: Vector3, c: Color, p: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = s
	n.mesh = m
	n.material_override = mat(c)
	n.position = p
	world.add_child(n)
	return n

func cyl(r: float, h: float, c: Color, p: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	n.mesh = m
	n.material_override = mat(c)
	n.position = p
	world.add_child(n)
	return n

func build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#78a7d4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	env_node.environment = env
	world.add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	world.add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0, 27, 29)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	build_pitch()
	build_scenery()

func build_pitch() -> void:
	box(Vector3(60, 0.5, 42), Color("#182018"), Vector3(0, -0.5, 0))
	box(Vector3(46, 0.2, 28), Color("#168044"), Vector3.ZERO)
	box(Vector3(46, 0.06, 0.14), Color.WHITE, Vector3(0, 0.14, -14))
	box(Vector3(46, 0.06, 0.14), Color.WHITE, Vector3(0, 0.14, 14))
	box(Vector3(0.14, 0.06, 28), Color.WHITE, Vector3(-23, 0.14, 0))
	box(Vector3(0.14, 0.06, 28), Color.WHITE, Vector3(23, 0.14, 0))
	box(Vector3(0.12, 0.06, 28), Color.WHITE, Vector3(0, 0.14, 0))
	var circle := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.2
	cm.bottom_radius = 4.2
	cm.height = 0.04
	cm.radial_segments = 48
	circle.mesh = cm
	circle.material_override = mat(Color.WHITE)
	circle.position = Vector3(0, 0.17, 0)
	world.add_child(circle)
	for x in [-23.5, 23.5]:
		box(Vector3(0.3, 2.8, 0.3), Color.WHITE, Vector3(x, 1.4, -3.4))
		box(Vector3(0.3, 2.8, 0.3), Color.WHITE, Vector3(x, 1.4, 3.4))
		box(Vector3(0.3, 0.3, 6.8), Color.WHITE, Vector3(x, 2.8, 0))
	for z in [-17.0, 17.0]:
		box(Vector3(58, 1.8, 2), Color("#303943"), Vector3(0, 0.8, z))
		for x in range(-25, 26, 4):
			box(Vector3(2, 0.7, 0.8), Color("#e1b83e"), Vector3(float(x), 2, z))

func build_scenery() -> void:
	box(Vector3(14, 5, 2), Color("#b88758"), Vector3(0, 2.5, -20))
	for x in [-7.0, 7.0]: cyl(0.8, 9, Color("#b88758"), Vector3(x, 4.5, -20))
	box(Vector3(5, 4, 2), Color("#69757d"), Vector3(-18, 2, -20))
	box(Vector3(5, 6, 2), Color("#955a3b"), Vector3(18, 3, -20))

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var hud := ColorRect.new()
	hud.color = Color(0.02, 0.04, 0.07, 0.86)
	hud.size = Vector2(1280, 82)
	ui.add_child(hud)
	location_label = make_label(Vector2(20, 12), 20, Color.WHITE)
	ui.add_child(location_label)
	var lm := make_label(Vector2(20, 43), 12, Color("#a9bfd5"))
	lm.text = LANDMARKS[0]
	ui.add_child(lm)
	score_label = make_label(Vector2(500, 12), 32, Color.WHITE)
	score_label.size = Vector2(280, 55)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(score_label)
	time_label = make_label(Vector2(1100, 17), 24, Color.WHITE)
	ui.add_child(time_label)
	message_label = make_label(Vector2(390, 300), 32, Color.WHITE)
	message_label.size = Vector2(500, 60)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(message_label)
	add_move_button("▲", Vector2(75, 515), Vector2(0, -1))
	add_move_button("▼", Vector2(75, 635), Vector2(0, 1))
	add_move_button("◀", Vector2(5, 575), Vector2(-1, 0))
	add_move_button("▶", Vector2(145, 575), Vector2(1, 0))
	var sprint := make_button("SPRINT", Vector2(235, 610), Vector2(115, 62))
	sprint.button_down.connect(func(): sprinting = true)
	sprint.button_up.connect(func(): sprinting = false)
	make_button("PASS", Vector2(820, 610), Vector2(110, 65)).pressed.connect(pass_ball)
	make_button("SWITCH", Vector2(940, 610), Vector2(110, 65)).pressed.connect(switch_player)
	make_button("SHOOT", Vector2(1060, 515), Vector2(150, 95)).pressed.connect(shoot_ball)

func make_label(p: Vector2, size: int, c: Color) -> Label:
	var l := Label.new()
	l.position = p
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.size = Vector2(300, 45)
	return l

func make_button(text: String, p: Vector2, s: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = p
	b.size = s
	b.add_theme_font_size_override("font_size", 18)
	ui.add_child(b)
	return b

func add_move_button(text: String, p: Vector2, d: Vector2) -> void:
	var b := make_button(text, p, Vector2(70, 55))
	b.button_down.connect(func(): touch_dir = d)
	b.button_up.connect(func(): touch_dir = Vector2.ZERO)

func reset_match() -> void:
	for p in home:
		if is_instance_valid(p.node): p.node.queue_free()
	for p in away:
		if is_instance_valid(p.node): p.node.queue_free()
	home.clear()
	away.clear()
	score = [0, 0]
	time_left = MATCH_TIME
	finished = false
	selected = 0
	var hp := [Vector3(-12, 0, 0), Vector3(-7, 0, -5), Vector3(-7, 0, 5)]
	var hn := ["Hamza", "Daniyal", "Shahzaib"]
	for i in range(3):
		var p := Player.new(hp[i], 0, hn[i])
		p.node = create_player(p, Color("#10a653"))
		home.append(p)
	var ap := [Vector3(12, 0, 0), Vector3(7, 0, -5), Vector3(7, 0, 5)]
	for i in range(3):
		var p := Player.new(ap[i], 1, "Opponent %d" % (i + 1))
		p.node = create_player(p, Color("#d63232"))
		away.append(p)
	controlled = home[0]
	ball_owner = controlled
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	update_visuals()
	show_message("KICK OFF!", 1.5)

func create_player(p: Player, c: Color) -> Node3D:
	var root := Node3D.new()
	world.add_child(root)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.65
	cm.height = 1.9
	body.mesh = cm
	body.material_override = mat(c)
	body.position.y = 1.0
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.36
	sm.height = 0.72
	head.mesh = sm
	head.material_override = mat(Color("#d99b74"))
	head.position.y = 2.2
	root.add_child(head)
	root.position = p.pos
	return root

func make_ball() -> void:
	if is_instance_valid(ball_node): ball_node.queue_free()
	ball_node = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	ball_node.mesh = sm
	ball_node.material_override = mat(Color.WHITE)
	world.add_child(ball_node)

func _process(delta: float) -> void:
	if finished: return
	time_left = maxf(0.0, time_left - delta)
	switch_lock = maxf(0.0, switch_lock - delta)
	if time_left <= 0:
		finished = true
		show_message("FULL TIME", 999)
		return
	update_human(delta)
	update_ai(delta)
	update_ball(delta)
	check_goal()
	update_visuals()

func move_direction() -> Vector3:
	var x := Input.get_axis("ui_left", "ui_right")
	var z := Input.get_axis("ui_up", "ui_down")
	if touch_dir.length() > 0.05:
		x = touch_dir.x
		z = touch_dir.y
	var d := Vector3(x, 0, z)
	return d.normalized() if d.length() > 0.05 else Vector3.ZERO

func update_human(delta: float) -> void:
	var d := move_direction()
	var speed := SPRINT if sprinting or Input.is_key_pressed(KEY_SHIFT) else SPEED
	if d != Vector3.ZERO:
		controlled.pos += d * speed * delta
		controlled.pos.x = clampf(controlled.pos.x, -21, 21)
		controlled.pos.z = clampf(controlled.pos.z, -12, 12)
	if ball_owner == null and controlled.pos.distance_to(ball_pos) < 1.4: ball_owner = controlled
	if ball_owner == controlled: ball_pos = controlled.pos + (d if d != Vector3.ZERO else Vector3.RIGHT)

func update_ai(delta: float) -> void:
	for p in away:
		var d := p.pos.direction_to(ball_pos)
		p.pos += d * 4.0 * delta
		p.pos.x = clampf(p.pos.x, -21, 21)
		p.pos.z = clampf(p.pos.z, -12, 12)
		if ball_owner == null and p.pos.distance_to(ball_pos) < 1.2: ball_owner = p
		if ball_owner == p:
			var goal := Vector3(-23, 0, 0)
			ball_pos = p.pos + p.pos.direction_to(goal)
			if p.pos.distance_to(goal) < 9:
				ball_velocity = p.pos.direction_to(goal) * BALL
				ball_owner = null
	for p in home:
		if p != controlled: p.pos = p.pos.lerp(p.home, minf(1.0, delta * 1.2))

func update_ball(delta: float) -> void:
	if ball_owner != null: return
	ball_pos += ball_velocity * delta
	ball_velocity = ball_velocity.move_toward(Vector3.ZERO, 15.0 * delta)
	if absf(ball_pos.z) > 13:
		ball_pos.z = clampf(ball_pos.z, -13, 13)
		ball_velocity.z *= -0.7

func shoot_ball() -> void:
	if finished or ball_owner != controlled: return
	var d := move_direction()
	if d == Vector3.ZERO: d = Vector3.RIGHT
	ball_velocity = d * BALL
	ball_owner = null
	show_message("SHOOT!", 0.5)

func pass_ball() -> void:
	if finished or ball_owner != controlled: return
	var target: Player = home[(selected + 1) % home.size()]
	if target == controlled: target = home[(selected + 2) % home.size()]
	ball_velocity = controlled.pos.direction_to(target.pos) * PASS
	ball_owner = null
	show_message("PASS", 0.5)

func switch_player() -> void:
	if finished or switch_lock > 0: return
	selected = (selected + 1) % home.size()
	controlled = home[selected]
	switch_lock = 0.25
	show_message(controlled.pname, 0.6)

func check_goal() -> void:
	if ball_pos.x > 23 and absf(ball_pos.z) < 3.4:
		score[0] += 1
		kickoff("PAKISTAN SCORES!")
	elif ball_pos.x < -23 and absf(ball_pos.z) < 3.4:
		score[1] += 1
		kickoff("OPPONENT SCORES")

func kickoff(msg: String) -> void:
	ball_pos = Vector3.ZERO
	ball_velocity = Vector3.ZERO
	ball_owner = controlled
	show_message(msg, 2.0)

func update_visuals() -> void:
	for p in home:
		if is_instance_valid(p.node): p.node.position = p.pos
	for p in away:
		if is_instance_valid(p.node): p.node.position = p.pos
	if not is_instance_valid(ball_node): make_ball()
	ball_node.position = ball_pos + Vector3(0, 0.48, 0)
	score_label.text = "%d  -  %d" % [score[0], score[1]]
	var t := int(ceil(time_left))
	time_label.text = "%02d:%02d" % [t / 60, t % 60]
	location_label.text = LEVELS[0]

func show_message(text: String, seconds: float) -> void:
	message_label.text = text
	message_label.visible = true
	get_tree().create_timer(seconds).timeout.connect(func():
		if text != "FULL TIME" or not finished: message_label.visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: shoot_ball()
		elif event.keycode == KEY_E or event.keycode == KEY_TAB: switch_player()
		elif event.keycode == KEY_Q: pass_ball()
		elif event.keycode == KEY_R and finished: reset_match()
