extends Node2D
class_name GameManager

## ==============================================================================
##  NEON SERPENT // FULL ARCADE MENU EDITION (v3.5)
##  Interactive Cyberpunk Start Menu, Briefing Panel, Exit Handler, Touch Swipes,
##  Power-Ups, Combos, Procedural Audio Synthesis & Hit-Stop
## ==============================================================================

const GRID_COLS: int = 24
const GRID_ROWS: int = 24
const CELL_SIZE: int = 30
const BOARD_WIDTH: int = GRID_COLS * CELL_SIZE
const BOARD_HEIGHT: int = GRID_ROWS * CELL_SIZE
const BOARD_SIZE: Vector2 = Vector2(BOARD_WIDTH, BOARD_HEIGHT)

const INITIAL_SNAKE_LENGTH: int = 4
const INITIAL_MOVE_INTERVAL: float = 0.16
const MIN_MOVE_INTERVAL: float = 0.052
const SPEED_DECREMENT: float = 0.010
const FOODS_PER_LEVEL: int = 5

const START_POS: Vector2i = Vector2i(GRID_COLS / 2, GRID_ROWS / 2)
const SAVE_PATH: String = "user://neon_serpent_save_v3.json"
const SETTINGS_PATH: String = "user://neon_serpent_settings.cfg"

const MODE_CLASSIC: String = "CLASSIC GRID"
const MODE_MAZE: String = "CIRCUIT MAZE"
const MODE_ZEN: String = "ZEN WRAP"
const MODE_EXTINCTION: String = "GRID EXTINCTION"

## ===== PALETTE =====
const COLOR_BG: Color = Color("#040711")
const COLOR_BG_CENTER: Color = Color("#091b3b")
const COLOR_GRID: Color = Color(0.20, 0.97, 1.00, 0.09)
const COLOR_GRID_BRIGHT: Color = Color(0.20, 0.97, 1.00, 0.22)

const COLOR_BORDER: Color = Color("#3cf7ff")
const COLOR_VIOLET: Color = Color("#8d5cff")
const COLOR_MAGENTA: Color = Color("#ff39d1")
const COLOR_DANGER: Color = Color("#ff3366")
const COLOR_GOLD: Color = Color("#ffd043")
const COLOR_FIRE: Color = Color("#ff7b25")
const COLOR_EMP: Color = Color("#00f0ff")

const COLOR_SNAKE_HEAD: Color = Color("#b8ffff")
const COLOR_SNAKE_BODY: Color = Color("#2de2e6")
const COLOR_SNAKE_TAIL: Color = Color(0.00, 0.38, 0.52, 1.0)
const COLOR_FOOD_CORE: Color = Color("#ffffff")

const DIR_UP: Vector2i = Vector2i(0, -1)
const DIR_DOWN: Vector2i = Vector2i(0, 1)
const DIR_LEFT: Vector2i = Vector2i(-1, 0)
const DIR_RIGHT: Vector2i = Vector2i(1, 0)

enum GameState { READY, RUNNING, PAUSED, GAME_OVER }
enum PowerUpType { NONE, EMP_SLOW, GHOST_SHIFT, MULTIPLIER_2X, TAIL_PURGE }

## ===== GAME STATE =====
var snake: Array[Vector2i] = []
var direction: Vector2i = DIR_RIGHT
var next_direction: Vector2i = DIR_RIGHT
var food_pos: Vector2i = Vector2i(-1, -1)

var score: int = 0
var high_score: int = 0
var level: int = 1
var foods_eaten_this_level: int = 0
var total_food_eaten: int = 0
var move_interval: float = INITIAL_MOVE_INTERVAL
var game_state: GameState = GameState.READY
var board_position: Vector2 = Vector2.ZERO
var selected_mode: String = MODE_CLASSIC
var screen_shake_enabled: bool = true
var music_volume: float = 0.70
var sfx_volume: float = 0.85

## ===== COMBO & POWER-UPS =====
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 3.2

var active_powerup: PowerUpType = PowerUpType.NONE
var powerup_duration: float = 0.0
var powerup_pos: Vector2i = Vector2i(-1, -1)
var powerup_type_on_board: PowerUpType = PowerUpType.NONE
var powerup_spawn_timer: float = 7.0

## ===== HIT-STOP & JUICE =====
var hit_stop_timer: float = 0.0
var visual_time: float = 0.0
var eat_pulse: float = 0.0
var death_flash: float = 0.0
var screen_shake: float = 0.0

var ambient_particles: Array[Dictionary] = []
var burst_particles: Array[Dictionary] = []
var ghost_trails: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

## ===== TOUCH / SWIPE CONTROLS =====
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_dragging: bool = false
const MIN_SWIPE_DISTANCE: float = 35.0

## ===== TIMERS & AUDIO =====
var move_timer: Timer
var level_up_timer: Timer

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

var sfx_eat: AudioStreamWAV
var sfx_powerup: AudioStreamWAV
var sfx_level_up: AudioStreamWAV
var sfx_die: AudioStreamWAV
var sfx_click: AudioStreamWAV
var sfx_purge: AudioStreamWAV
var bgm_loop: AudioStreamWAV

## ===== SCENE NODES =====
@onready var game_board: Node2D = %GameBoard
@onready var score_label: Label = %ScoreLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var level_label: Label = %LevelLabel
@onready var speed_label: Label = %SpeedLabel
@onready var status_label: Label = %StatusLabel
@onready var combo_label: Label = %ComboLabel
@onready var powerup_status_label: Label = %PowerUpStatusLabel

@onready var start_overlay: Control = %StartOverlay
@onready var pause_overlay: Control = %PauseOverlay
@onready var game_over_overlay: Control = %GameOverOverlay
@onready var briefing_modal: Control = %BriefingModal

@onready var start_button: Button = %StartButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var exit_button: Button = %ExitButton
@onready var close_briefing_button: Button = %CloseBriefingButton

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton

@onready var final_score_label: Label = %FinalScoreLabel
@onready var level_up_label: Label = %LevelUpLabel
@onready var modes_button: Button = %ModesButton
@onready var settings_button: Button = %SettingsButton
@onready var modes_modal: Control = %ModesModal
@onready var settings_modal: Control = %SettingsModal
@onready var mode_classic_button: Button = %ModeClassicBtn
@onready var mode_maze_button: Button = %ModeMazeBtn
@onready var mode_zen_button: Button = %ModeZenBtn
@onready var mode_extinction_button: Button = %ModeExtinctionBtn
@onready var close_modes_button: Button = %CloseModesBtn
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var shake_toggle: CheckBox = %ShakeToggle
@onready var close_settings_button: Button = %CloseSettingsBtn
@onready var quit_confirm_modal: Control = %QuitConfirmModal
@onready var confirm_quit_button: Button = %ConfirmQuitButton
@onready var cancel_quit_button: Button = %CancelQuitButton


## ===== INITIALIZATION =====
func _ready() -> void:
	_load_settings()
	_setup_audio()
	_setup_timers()
	_load_high_score()
	_connect_signals()
	_create_ambient_particles()
	_center_board()
	reset_game()


func _setup_timers() -> void:
	move_timer = Timer.new()
	move_timer.wait_time = INITIAL_MOVE_INTERVAL
	move_timer.one_shot = false
	move_timer.timeout.connect(_on_move_timer_timeout)
	add_child(move_timer)

	level_up_timer = Timer.new()
	level_up_timer.wait_time = 1.8
	level_up_timer.one_shot = true
	level_up_timer.timeout.connect(_on_level_up_timer_timeout)
	add_child(level_up_timer)


func _setup_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -1.5
	add_child(sfx_player)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -9.5
	add_child(bgm_player)

	sfx_eat = _generate_crystal_bell(1.0)
	sfx_powerup = _generate_powerup_chime()
	sfx_level_up = _generate_cyber_fanfare()
	sfx_die = _generate_glitch_impact()
	sfx_click = _generate_ui_pip()
	sfx_purge = _generate_purge_whoosh()
	bgm_loop = _generate_synthwave_bgm()

	bgm_player.stream = bgm_loop
	bgm_player.play()
	_apply_audio_settings()


func _connect_signals() -> void:
	# Menu Buttons
	if start_button and not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if how_to_play_button and not how_to_play_button.pressed.is_connected(_on_how_to_play_button_pressed):
		how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	if exit_button and not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)
	if close_briefing_button and not close_briefing_button.pressed.is_connected(_on_close_briefing_pressed):
		close_briefing_button.pressed.connect(_on_close_briefing_pressed)

	# Overlay Buttons
	if resume_button and not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)
	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)


	if modes_button and not modes_button.pressed.is_connected(_on_modes_button_pressed):
		modes_button.pressed.connect(_on_modes_button_pressed)
	if close_modes_button and not close_modes_button.pressed.is_connected(_on_close_modes_pressed):
		close_modes_button.pressed.connect(_on_close_modes_pressed)
	if mode_classic_button and not mode_classic_button.pressed.is_connected(_on_mode_classic_pressed):
		mode_classic_button.pressed.connect(_on_mode_classic_pressed)
	if mode_maze_button and not mode_maze_button.pressed.is_connected(_on_mode_maze_pressed):
		mode_maze_button.pressed.connect(_on_mode_maze_pressed)
	if mode_zen_button and not mode_zen_button.pressed.is_connected(_on_mode_zen_pressed):
		mode_zen_button.pressed.connect(_on_mode_zen_pressed)
	if mode_extinction_button and not mode_extinction_button.pressed.is_connected(_on_mode_extinction_pressed):
		mode_extinction_button.pressed.connect(_on_mode_extinction_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
	if close_settings_button and not close_settings_button.pressed.is_connected(_on_close_settings_pressed):
		close_settings_button.pressed.connect(_on_close_settings_pressed)
	if music_slider and not music_slider.value_changed.is_connected(_on_music_slider_changed):
		music_slider.value_changed.connect(_on_music_slider_changed)
	if sfx_slider and not sfx_slider.value_changed.is_connected(_on_sfx_slider_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	if shake_toggle and not shake_toggle.toggled.is_connected(_on_shake_toggle_changed):
		shake_toggle.toggled.connect(_on_shake_toggle_changed)
	if confirm_quit_button and not confirm_quit_button.pressed.is_connected(_on_confirm_quit_pressed):
		confirm_quit_button.pressed.connect(_on_confirm_quit_pressed)
	if cancel_quit_button and not cancel_quit_button.pressed.is_connected(_on_cancel_quit_pressed):
		cancel_quit_button.pressed.connect(_on_cancel_quit_pressed)


## ===== MAIN FRAME LOOP =====
func _process(delta: float) -> void:
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		return

	visual_time += delta
	eat_pulse = maxf(0.0, eat_pulse - delta * 2.5)
	death_flash = maxf(0.0, death_flash - delta * 1.5)
	screen_shake = maxf(0.0, screen_shake - delta * 14.0)

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			_update_hud()

	if active_powerup != PowerUpType.NONE:
		powerup_duration -= delta
		if powerup_duration <= 0.0:
			_deactivate_powerup()
		else:
			_update_hud()

	if game_state == GameState.RUNNING and powerup_pos == Vector2i(-1, -1) and active_powerup == PowerUpType.NONE:
		powerup_spawn_timer -= delta
		if powerup_spawn_timer <= 0.0:
			_spawn_powerup()
			powerup_spawn_timer = randf_range(9.0, 15.0)

	_update_board_position()
	_update_particles(delta)
	_update_ghost_trails(delta)
	_update_floating_texts(delta)

	if bgm_player != null and not bgm_player.playing:
		bgm_player.play()

	queue_redraw()


func _update_board_position() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var target_x: float = (vp_size.x - BOARD_WIDTH) * 0.5
	var target_y: float = clampf((vp_size.y - BOARD_HEIGHT) * 0.5 + 32.0, 95.0, vp_size.y - BOARD_HEIGHT - 35.0)
	var target_pos := Vector2(target_x, target_y)

	if target_pos != board_position:
		board_position = target_pos
		game_board.position = board_position


func _center_board() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var target_x: float = (vp_size.x - BOARD_WIDTH) * 0.5
	var target_y: float = clampf((vp_size.y - BOARD_HEIGHT) * 0.5 + 32.0, 95.0, vp_size.y - BOARD_HEIGHT - 35.0)
	board_position = Vector2(target_x, target_y)
	game_board.position = board_position
	queue_redraw()


## ===== PERSISTENCE =====
func _load_high_score() -> void:
	high_score = 0
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_update_hud()
		return

	var content: String = file.get_as_text()
	file.close()
	if content.strip_edges().is_empty():
		_update_hud()
		return

	var json: JSON = JSON.new()
	if json.parse(content) == OK:
		var data: Variant = json.data
		if data is Dictionary and data.has("high_score"):
			var loaded: Variant = data["high_score"]
			if loaded is int or loaded is float:
				high_score = max(0, int(loaded))

	_update_hud()


func _save_high_score() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"high_score": high_score}))
	file.close()


func _update_high_score_if_needed() -> void:
	if score > high_score:
		high_score = score
		_save_high_score()
		_update_hud()


## ===== GAME STATE FLOW =====
func reset_game() -> void:
	snake.clear()
	for i in range(INITIAL_SNAKE_LENGTH):
		snake.append(Vector2i(START_POS.x - i, START_POS.y))

	direction = DIR_RIGHT
	next_direction = DIR_RIGHT
	food_pos = Vector2i(-1, -1)
	powerup_pos = Vector2i(-1, -1)
	powerup_type_on_board = PowerUpType.NONE
	active_powerup = PowerUpType.NONE
	powerup_duration = 0.0

	score = 0
	level = 1
	foods_eaten_this_level = 0
	total_food_eaten = 0
	combo_count = 0
	combo_timer = 0.0
	move_interval = INITIAL_MOVE_INTERVAL
	game_state = GameState.READY

	eat_pulse = 0.0
	death_flash = 0.0
	screen_shake = 0.0
	burst_particles.clear()
	ghost_trails.clear()
	floating_texts.clear()

	move_timer.stop()
	level_up_timer.stop()
	move_timer.wait_time = move_interval

	spawn_food()
	_update_hud()

	if start_overlay:
		start_overlay.visible = true
	if briefing_modal:
		briefing_modal.visible = false
	if modes_modal:
		modes_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
	if quit_confirm_modal:
		quit_confirm_modal.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = false
	if level_up_label:
		level_up_label.visible = false

	queue_redraw()


func spawn_food() -> void:
	var empty_cells: Array[Vector2i] = []
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			var candidate: Vector2i = Vector2i(x, y)
			if not snake.has(candidate) and candidate != powerup_pos:
				empty_cells.append(candidate)

	food_pos = Vector2i(-1, -1) if empty_cells.is_empty() else empty_cells.pick_random()


func _spawn_powerup() -> void:
	var empty_cells: Array[Vector2i] = []
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			var candidate: Vector2i = Vector2i(x, y)
			if not snake.has(candidate) and candidate != food_pos:
				empty_cells.append(candidate)

	if empty_cells.is_empty():
		return

	powerup_pos = empty_cells.pick_random()
	var types: Array = [PowerUpType.EMP_SLOW, PowerUpType.GHOST_SHIFT, PowerUpType.MULTIPLIER_2X, PowerUpType.TAIL_PURGE]
	powerup_type_on_board = types.pick_random()


func start_mission() -> void:
	if game_state != GameState.READY:
		return
	_play_sfx(sfx_click)
	game_state = GameState.RUNNING
	if start_overlay:
		start_overlay.visible = false
	if briefing_modal:
		briefing_modal.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = false
	_update_hud()
	move_timer.start()
	queue_redraw()


func pause_game() -> void:
	if game_state != GameState.RUNNING:
		return
	_play_sfx(sfx_click)
	game_state = GameState.PAUSED
	move_timer.stop()
	if pause_overlay:
		pause_overlay.visible = true
	_update_hud()
	queue_redraw()


func resume_game() -> void:
	if game_state != GameState.PAUSED:
		return
	_play_sfx(sfx_click)
	game_state = GameState.RUNNING
	if pause_overlay:
		pause_overlay.visible = false
	_update_hud()
	move_timer.start()
	queue_redraw()


func _on_move_timer_timeout() -> void:
	if game_state == GameState.RUNNING:
		_move_snake()
		queue_redraw()


## ===== SNAKE MOVEMENT & COLLISIONS =====
func _move_snake() -> void:
	direction = next_direction
	var new_head: Vector2i = snake[0] + direction

	_record_ghost_trail()

	if _hits_wall(new_head):
		_trigger_hit_stop(0.09)
		_game_over()
		return

	var will_eat_food: bool = (new_head == food_pos)
	var will_eat_powerup: bool = (new_head == powerup_pos)

	if active_powerup != PowerUpType.GHOST_SHIFT:
		var body_cells_to_check: int = snake.size() if (will_eat_food or will_eat_powerup) else snake.size() - 1
		for i in range(body_cells_to_check):
			if snake[i] == new_head:
				_trigger_hit_stop(0.09)
				_game_over()
				return

	snake.push_front(new_head)

	if will_eat_food:
		combo_count += 1
		combo_timer = COMBO_WINDOW

		var multiplier: int = (2 if active_powerup == PowerUpType.MULTIPLIER_2X else 1) * clampi(combo_count, 1, 4)
		var points_earned: int = 10 * multiplier
		score += points_earned
		foods_eaten_this_level += 1
		total_food_eaten += 1

		eat_pulse = 1.0
		if screen_shake_enabled:
			screen_shake = maxf(screen_shake, 3.8)
		_play_sfx(sfx_eat, 1.0 + float(combo_count) * 0.08)
		_spawn_eat_particles(_cell_center(new_head))
		_spawn_floating_text(_cell_center(new_head), "+%d" % points_earned, COLOR_GOLD if multiplier > 1 else COLOR_BORDER)

		_update_hud()
		_update_high_score_if_needed()
		spawn_food()

		if foods_eaten_this_level >= FOODS_PER_LEVEL:
			_level_up()
	elif will_eat_powerup:
		_activate_powerup(powerup_type_on_board, _cell_center(new_head))
		powerup_pos = Vector2i(-1, -1)
		powerup_type_on_board = PowerUpType.NONE
	else:
		snake.pop_back()


func _hits_wall(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.x >= GRID_COLS or cell.y < 0 or cell.y >= GRID_ROWS


## ===== POWER-UP ACTIVATION =====
func _activate_powerup(type: PowerUpType, center: Vector2) -> void:
	active_powerup = type
	_spawn_eat_particles(center, 30)

	match type:
		PowerUpType.EMP_SLOW:
			powerup_duration = 6.0
			move_timer.wait_time = move_interval * 1.6
			_play_sfx(sfx_powerup)
			_spawn_floating_text(center, "EMP // OVERCLOCK SLOW", COLOR_EMP)
		PowerUpType.GHOST_SHIFT:
			powerup_duration = 5.5
			_play_sfx(sfx_powerup)
			_spawn_floating_text(center, "PHASE SHIFT // GHOST", COLOR_VIOLET)
		PowerUpType.MULTIPLIER_2X:
			powerup_duration = 7.0
			_play_sfx(sfx_powerup)
			_spawn_floating_text(center, "DATA STREAM 2X BOOST", COLOR_GOLD)
		PowerUpType.TAIL_PURGE:
			active_powerup = PowerUpType.NONE
			var purge_count: int = mini(3, snake.size() - 2)
			for p in range(purge_count):
				var removed_tail: Vector2i = snake.pop_back()
				_spawn_eat_particles(_cell_center(removed_tail), 12)
			_play_sfx(sfx_purge)
			if screen_shake_enabled:
				screen_shake = 6.0
			_spawn_floating_text(center, "PURGE // -3 SEGMENTS", COLOR_FIRE)

	_update_hud()


func _deactivate_powerup() -> void:
	active_powerup = PowerUpType.NONE
	move_timer.wait_time = move_interval
	_update_hud()


func _level_up() -> void:
	level += 1
	foods_eaten_this_level = 0
	move_interval = maxf(MIN_MOVE_INTERVAL, move_interval - SPEED_DECREMENT)

	if active_powerup == PowerUpType.EMP_SLOW:
		move_timer.wait_time = move_interval * 1.6
	else:
		move_timer.wait_time = move_interval

	_update_hud()
	_play_sfx(sfx_level_up)
	_trigger_hit_stop(0.06)

	if level_up_label:
		level_up_label.text = "TIER %02d OVERCLOCK ACTIVE" % level
		level_up_label.visible = true
	level_up_timer.start()


func _on_level_up_timer_timeout() -> void:
	if level_up_label:
		level_up_label.visible = false


func _trigger_hit_stop(duration: float) -> void:
	hit_stop_timer = duration


func _game_over() -> void:
	game_state = GameState.GAME_OVER
	move_timer.stop()

	death_flash = 1.0
	if screen_shake_enabled:
		screen_shake = maxf(screen_shake, 16.0)
	_play_sfx(sfx_die)

	if not snake.is_empty():
		_spawn_death_particles(_cell_center(snake[0]))

	_update_high_score_if_needed()

	if start_overlay:
		start_overlay.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = true
	if final_score_label:
		final_score_label.text = "FINAL SCORE // %04d" % score

	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	if score_label:
		score_label.text = "%04d" % score
	if high_score_label:
		high_score_label.text = "%04d" % high_score
	if level_label:
		level_label.text = "%02d" % level
	if speed_label:
		speed_label.text = "%.1fx" % (INITIAL_MOVE_INTERVAL / move_interval)

	if combo_label:
		if combo_count > 1:
			combo_label.text = "COMBO: x%d" % combo_count
			combo_label.visible = true
		else:
			combo_label.visible = false

	if powerup_status_label:
		if active_powerup != PowerUpType.NONE:
			match active_powerup:
				PowerUpType.EMP_SLOW:
					powerup_status_label.text = "⚡ EMP SLOW [%.1fs]" % powerup_duration
					powerup_status_label.add_theme_color_override("font_color", COLOR_EMP)
				PowerUpType.GHOST_SHIFT:
					powerup_status_label.text = "👻 GHOST PHASE [%.1fs]" % powerup_duration
					powerup_status_label.add_theme_color_override("font_color", COLOR_VIOLET)
				PowerUpType.MULTIPLIER_2X:
					powerup_status_label.text = "★ 2X DATA STREAM [%.1fs]" % powerup_duration
					powerup_status_label.add_theme_color_override("font_color", COLOR_GOLD)
			powerup_status_label.visible = true
		else:
			powerup_status_label.visible = false

	if status_label:
		match game_state:
			GameState.READY:
				status_label.text = "READY"
				status_label.add_theme_color_override("font_color", Color("#7dd3fc"))
			GameState.RUNNING:
				status_label.text = "ACTIVE"
				status_label.add_theme_color_override("font_color", COLOR_BORDER)
			GameState.PAUSED:
				status_label.text = "SUSPENDED"
				status_label.add_theme_color_override("font_color", COLOR_GOLD)
			GameState.GAME_OVER:
				status_label.text = "CRITICAL"
				status_label.add_theme_color_override("font_color", COLOR_DANGER)


## ===== DUAL INPUT: KEYBOARD + TOUCH/SWIPE =====
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			_toggle_fullscreen()
			return

	if event is InputEventScreenTouch:
		if event.is_pressed():
			touch_start_pos = event.position
			touch_dragging = true
			if game_state == GameState.READY and start_overlay and not start_overlay.visible:
				start_mission()
		else:
			if touch_dragging:
				_handle_swipe(event.position - touch_start_pos)
				touch_dragging = false
		return

	if event is InputEventScreenDrag and touch_dragging:
		var delta_drag: Vector2 = event.position - touch_start_pos
		if delta_drag.length() >= MIN_SWIPE_DISTANCE:
			_handle_swipe(delta_drag)
			touch_start_pos = event.position
		return

	if game_state == GameState.GAME_OVER:
		if Input.is_action_just_pressed("restart"):
			reset_game()
			start_mission()
		return

	if game_state == GameState.READY:
		if event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_ESCAPE:
			if quit_confirm_modal and quit_confirm_modal.visible:
				_close_menu_modals()
			elif (briefing_modal and briefing_modal.visible) or (modes_modal and modes_modal.visible) or (settings_modal and settings_modal.visible):
				_close_menu_modals()
			else:
				_show_only_modal(quit_confirm_modal)
			return
		var is_menu_modal_open: bool = (briefing_modal != null and briefing_modal.visible) or (modes_modal != null and modes_modal.visible) or (settings_modal != null and settings_modal.visible) or (quit_confirm_modal != null and quit_confirm_modal.visible)
		if Input.is_action_just_pressed("start_mission") and not is_menu_modal_open:
			start_mission()
		return

	if Input.is_action_just_pressed("pause"):
		if game_state == GameState.RUNNING:
			pause_game()
		elif game_state == GameState.PAUSED:
			resume_game()
		return

	if game_state != GameState.RUNNING:
		return

	if Input.is_action_just_pressed("move_up"):
		_set_direction(DIR_UP)
	elif Input.is_action_just_pressed("move_down"):
		_set_direction(DIR_DOWN)
	elif Input.is_action_just_pressed("move_left"):
		_set_direction(DIR_LEFT)
	elif Input.is_action_just_pressed("move_right"):
		_set_direction(DIR_RIGHT)


func _handle_swipe(diff: Vector2) -> void:
	if diff.length() < MIN_SWIPE_DISTANCE or game_state != GameState.RUNNING:
		return

	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			_set_direction(DIR_RIGHT)
		else:
			_set_direction(DIR_LEFT)
	else:
		if diff.y > 0:
			_set_direction(DIR_DOWN)
		else:
			_set_direction(DIR_UP)


func _set_direction(new_dir: Vector2i) -> void:
	if new_dir == DIR_UP and direction != DIR_DOWN:
		next_direction = DIR_UP
	elif new_dir == DIR_DOWN and direction != DIR_UP:
		next_direction = DIR_DOWN
	elif new_dir == DIR_LEFT and direction != DIR_RIGHT:
		next_direction = DIR_LEFT
	elif new_dir == DIR_RIGHT and direction != DIR_LEFT:
		next_direction = DIR_RIGHT


func _toggle_fullscreen() -> void:
	var mode: int = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## ===== MENU PROTOCOLS, SETTINGS & BUTTON CALLBACKS =====
func _show_only_modal(target_modal: Control) -> void:
	if briefing_modal:
		briefing_modal.visible = false
	if modes_modal:
		modes_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
	if quit_confirm_modal:
		quit_confirm_modal.visible = false
	if target_modal:
		target_modal.visible = true


func _close_menu_modals() -> void:
	if briefing_modal:
		briefing_modal.visible = false
	if modes_modal:
		modes_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
	if quit_confirm_modal:
		quit_confirm_modal.visible = false


func _set_locked_protocol(protocol_name: String, reason: String) -> void:
	_play_sfx(sfx_click)
	if status_label:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", COLOR_DANGER)
	if modes_button:
		modes_button.text = "MAP & MODE: [ %s // LOCKED ]" % protocol_name
	_spawn_floating_text(board_position + Vector2(BOARD_WIDTH * 0.5, BOARD_HEIGHT * 0.5), "%s // LOCKED" % protocol_name, COLOR_DANGER)
	print("NEON SERPENT: %s is locked. %s" % [protocol_name, reason])


func _select_classic_mode() -> void:
	selected_mode = MODE_CLASSIC
	if modes_button:
		modes_button.text = "MAP & MODE: [ CLASSIC GRID ]"
	if status_label and game_state == GameState.READY:
		status_label.text = "READY"
		status_label.add_theme_color_override("font_color", COLOR_BORDER)
	_play_sfx(sfx_click)
	_close_menu_modals()


func _sync_settings_controls() -> void:
	if music_slider:
		music_slider.value = music_volume
	if sfx_slider:
		sfx_slider.value = sfx_volume
	if shake_toggle:
		shake_toggle.button_pressed = screen_shake_enabled


func _apply_audio_settings() -> void:
	if bgm_player:
		bgm_player.volume_db = linear_to_db(maxf(music_volume, 0.001))
	if sfx_player:
		sfx_player.volume_db = linear_to_db(maxf(sfx_volume, 0.001))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = clampf(float(config.get_value("audio", "music_volume", 0.70)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 0.85)), 0.0, 1.0)
	screen_shake_enabled = bool(config.get_value("display", "screen_shake_enabled", true))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "screen_shake_enabled", screen_shake_enabled)
	config.save(SETTINGS_PATH)


func _on_start_button_pressed() -> void:
	start_mission()


func _on_how_to_play_button_pressed() -> void:
	_play_sfx(sfx_click)
	_show_only_modal(briefing_modal)


func _on_close_briefing_pressed() -> void:
	_play_sfx(sfx_click)
	_close_menu_modals()


func _on_modes_button_pressed() -> void:
	_play_sfx(sfx_click)
	_show_only_modal(modes_modal)


func _on_close_modes_pressed() -> void:
	_play_sfx(sfx_click)
	_close_menu_modals()


func _on_mode_classic_pressed() -> void:
	_select_classic_mode()


func _on_mode_maze_pressed() -> void:
	_set_locked_protocol(MODE_MAZE, "MAZE SYSTEMS NOT DEPLOYED.")


func _on_mode_zen_pressed() -> void:
	_set_locked_protocol(MODE_ZEN, "WARP GATE SYSTEMS NOT DEPLOYED.")


func _on_mode_extinction_pressed() -> void:
	_set_locked_protocol(MODE_EXTINCTION, "ARENA COLLAPSE SYSTEMS NOT DEPLOYED.")


func _on_settings_button_pressed() -> void:
	_play_sfx(sfx_click)
	_sync_settings_controls()
	_show_only_modal(settings_modal)


func _on_close_settings_pressed() -> void:
	_play_sfx(sfx_click)
	_save_settings()
	_close_menu_modals()


func _on_music_slider_changed(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()


func _on_sfx_slider_changed(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()


func _on_shake_toggle_changed(enabled: bool) -> void:
	screen_shake_enabled = enabled


func _on_exit_button_pressed() -> void:
	_play_sfx(sfx_click)
	_show_only_modal(quit_confirm_modal)


func _on_confirm_quit_pressed() -> void:
	_play_sfx(sfx_click)
	get_tree().quit()


func _on_cancel_quit_pressed() -> void:
	_play_sfx(sfx_click)
	_close_menu_modals()


func _on_resume_button_pressed() -> void:
	resume_game()


func _on_restart_button_pressed() -> void:
	reset_game()
	start_mission()


## ===== PARTICLES, TRAILS & DRAWING =====
func _create_ambient_particles() -> void:
	ambient_particles.clear()
	for i in range(34):
		var p_color: Color = COLOR_BORDER if i % 2 == 0 else COLOR_VIOLET
		ambient_particles.append({
			"position": Vector2(randf() * BOARD_WIDTH, randf() * BOARD_HEIGHT),
			"velocity": Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)),
			"size": randf_range(0.8, 2.0),
			"phase": randf() * TAU,
			"color": p_color
		})


func _update_particles(delta: float) -> void:
	for particle in ambient_particles:
		particle["position"] += particle["velocity"] * delta
		if particle["position"].x < 0.0 or particle["position"].x > BOARD_WIDTH:
			particle["velocity"].x *= -1.0
		if particle["position"].y < 0.0 or particle["position"].y > BOARD_HEIGHT:
			particle["velocity"].y *= -1.0

	for i in range(burst_particles.size() - 1, -1, -1):
		var particle: Dictionary = burst_particles[i]
		particle["position"] += particle["velocity"] * delta
		particle["velocity"] *= 0.93
		particle["life"] -= delta
		burst_particles[i] = particle

		if particle["life"] <= 0.0:
			burst_particles.remove_at(i)


func _record_ghost_trail() -> void:
	if snake.is_empty():
		return
	ghost_trails.append({
		"cell": snake[0],
		"alpha": 0.40,
		"color": COLOR_VIOLET if active_powerup == PowerUpType.GHOST_SHIFT else COLOR_BORDER
	})


func _update_ghost_trails(delta: float) -> void:
	for i in range(ghost_trails.size() - 1, -1, -1):
		var trail: Dictionary = ghost_trails[i]
		trail["alpha"] -= delta * 2.8
		ghost_trails[i] = trail
		if trail["alpha"] <= 0.0:
			ghost_trails.remove_at(i)


func _spawn_floating_text(pos: Vector2, text: String, color: Color) -> void:
	floating_texts.append({
		"position": pos,
		"text": text,
		"color": color,
		"alpha": 1.0,
		"life": 1.1
	})


func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		var item: Dictionary = floating_texts[i]
		item["position"].y -= delta * 38.0
		item["life"] -= delta
		item["alpha"] = clampf(item["life"] / 1.1, 0.0, 1.0)
		floating_texts[i] = item
		if item["life"] <= 0.0:
			floating_texts.remove_at(i)


func _spawn_eat_particles(center: Vector2, count: int = 24) -> void:
	for i in range(count):
		var angle: float = randf() * TAU
		var speed: float = randf_range(90.0, 240.0)
		var p_color: Color = COLOR_BORDER if i % 2 == 0 else COLOR_MAGENTA

		burst_particles.append({
			"position": center,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.35, 0.75),
			"max_life": 0.75,
			"size": randf_range(1.6, 4.0),
			"color": p_color
		})


func _spawn_death_particles(center: Vector2) -> void:
	for i in range(45):
		var angle: float = randf() * TAU
		var speed: float = randf_range(140.0, 340.0)
		var p_color: Color = COLOR_MAGENTA if i % 2 == 0 else COLOR_DANGER

		burst_particles.append({
			"position": center,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.5, 1.2),
			"max_life": 1.2,
			"size": randf_range(2.0, 5.5),
			"color": p_color
		})


## ===== DRAWING =====
func _draw() -> void:
	var shake_offset: Vector2 = Vector2.ZERO
	if screen_shake > 0.0:
		shake_offset = Vector2(
			randf_range(-screen_shake, screen_shake),
			randf_range(-screen_shake, screen_shake)
		)

	draw_set_transform(shake_offset, 0.0, Vector2.ONE)

	_draw_board()
	_draw_ambient_particles()
	_draw_ghost_trails()
	_draw_food()
	_draw_powerup()
	_draw_snake()
	_draw_burst_particles()
	_draw_floating_texts()
	_draw_flash()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_board() -> void:
	var board_rect: Rect2 = Rect2(board_position, BOARD_SIZE)

	draw_rect(board_rect, COLOR_BG)
	var center_pos: Vector2 = board_rect.get_center()
	draw_circle(center_pos, BOARD_WIDTH * 0.44, Color(COLOR_BG_CENTER, 0.50))
	draw_circle(center_pos, BOARD_WIDTH * 0.24, Color(COLOR_BG_CENTER, 0.75))

	var grid_pulse: float = 0.5 + 0.5 * sin(visual_time * 1.8)

	for x in range(GRID_COLS + 1):
		var line_x: float = board_position.x + float(x * CELL_SIZE)
		var line_color: Color = COLOR_GRID_BRIGHT if x % 4 == 0 else COLOR_GRID
		line_color.a *= 0.8 + grid_pulse * 0.2
		draw_line(Vector2(line_x, board_position.y), Vector2(line_x, board_position.y + BOARD_HEIGHT), line_color, 1.0)

	for y in range(GRID_ROWS + 1):
		var line_y: float = board_position.y + float(y * CELL_SIZE)
		var line_color: Color = COLOR_GRID_BRIGHT if y % 4 == 0 else COLOR_GRID
		line_color.a *= 0.8 + grid_pulse * 0.2
		draw_line(Vector2(board_position.x, line_y), Vector2(board_position.x + BOARD_WIDTH, line_y), line_color, 1.0)

	draw_rect(board_rect.grow(3.0), Color(COLOR_VIOLET, 0.25 + grid_pulse * 0.15), false, 4.0)
	draw_rect(board_rect.grow(1.0), Color(COLOR_BORDER, 0.70 + grid_pulse * 0.25), false, 2.0)
	draw_rect(board_rect, COLOR_BORDER, false, 1.0)

	var notch: float = 14.0
	draw_line(board_position, board_position + Vector2(notch, 0), Color.WHITE, 2.0)
	draw_line(board_position, board_position + Vector2(0, notch), Color.WHITE, 2.0)
	draw_line(board_position + Vector2(BOARD_WIDTH, 0), board_position + Vector2(BOARD_WIDTH - notch, 0), Color.WHITE, 2.0)
	draw_line(board_position + Vector2(BOARD_WIDTH, 0), board_position + Vector2(BOARD_WIDTH, notch), Color.WHITE, 2.0)
	draw_line(board_position + Vector2(0, BOARD_HEIGHT), board_position + Vector2(notch, BOARD_HEIGHT), Color.WHITE, 2.0)
	draw_line(board_position + Vector2(0, BOARD_HEIGHT), board_position + Vector2(0, BOARD_HEIGHT - notch), Color.WHITE, 2.0)
	draw_line(board_position + BOARD_SIZE, board_position + BOARD_SIZE - Vector2(notch, 0), Color.WHITE, 2.0)
	draw_line(board_position + BOARD_SIZE, board_position + BOARD_SIZE - Vector2(0, notch), Color.WHITE, 2.0)


func _draw_ambient_particles() -> void:
	for particle in ambient_particles:
		var pos: Vector2 = board_position + particle["position"]
		var alpha: float = 0.16 + 0.16 * sin(visual_time * 2.0 + particle["phase"])
		draw_circle(pos, particle["size"], Color(particle["color"], alpha))


func _draw_ghost_trails() -> void:
	for trail in ghost_trails:
		var rect: Rect2 = _cell_rect(trail["cell"]).grow(-3.0)
		draw_rect(rect, Color(trail["color"], trail["alpha"] * 0.35), false, 1.5)


func _draw_food() -> void:
	if food_pos == Vector2i(-1, -1):
		return

	var food_center: Vector2 = _cell_center(food_pos)
	var food_pulse: float = 0.88 + 0.12 * sin(visual_time * 6.0)

	draw_circle(food_center, CELL_SIZE * 0.65 * food_pulse, Color(COLOR_MAGENTA, 0.10 + eat_pulse * 0.12))
	draw_circle(food_center, CELL_SIZE * 0.42 * food_pulse, Color(COLOR_VIOLET, 0.38))
	draw_circle(food_center, CELL_SIZE * 0.28 * food_pulse, COLOR_MAGENTA)
	draw_circle(food_center, CELL_SIZE * 0.13 * food_pulse, COLOR_FOOD_CORE)

	for i in range(4):
		var orbit_angle: float = visual_time * 3.0 + float(i) * TAU / 4.0
		var orbit_pos: Vector2 = food_center + Vector2(cos(orbit_angle), sin(orbit_angle)) * CELL_SIZE * 0.44
		var spark_color: Color = COLOR_BORDER if i % 2 == 0 else COLOR_MAGENTA
		draw_circle(orbit_pos, 1.7, spark_color)


func _draw_powerup() -> void:
	if powerup_pos == Vector2i(-1, -1):
		return

	var center: Vector2 = _cell_center(powerup_pos)
	var pulse: float = 0.85 + 0.15 * sin(visual_time * 7.5)
	var p_color: Color = COLOR_EMP

	match powerup_type_on_board:
		PowerUpType.EMP_SLOW:
			p_color = COLOR_EMP
		PowerUpType.GHOST_SHIFT:
			p_color = COLOR_VIOLET
		PowerUpType.MULTIPLIER_2X:
			p_color = COLOR_GOLD
		PowerUpType.TAIL_PURGE:
			p_color = COLOR_FIRE

	draw_circle(center, CELL_SIZE * 0.60 * pulse, Color(p_color, 0.22))
	var diamond: PackedVector2Array = [
		center + Vector2(0, -CELL_SIZE * 0.38 * pulse),
		center + Vector2(CELL_SIZE * 0.38 * pulse, 0),
		center + Vector2(0, CELL_SIZE * 0.38 * pulse),
		center + Vector2(-CELL_SIZE * 0.38 * pulse, 0)
	]
	draw_colored_polygon(diamond, p_color)
	draw_circle(center, CELL_SIZE * 0.14 * pulse, Color.WHITE)


func _draw_snake() -> void:
	var is_ghost: bool = (active_powerup == PowerUpType.GHOST_SHIFT)

	for i in range(snake.size() - 1, -1, -1):
		var segment: Vector2i = snake[i]
		var progress: float = float(i) / maxf(1.0, float(snake.size() - 1))
		var segment_rect: Rect2 = _cell_rect(segment).grow(-2.4)

		var base_color: Color = COLOR_SNAKE_HEAD if i == 0 else COLOR_SNAKE_BODY.lerp(COLOR_SNAKE_TAIL, progress)
		if is_ghost:
			base_color = Color(COLOR_VIOLET, 0.55 + 0.3 * sin(visual_time * 8.0 + float(i)))

		draw_rect(segment_rect.grow(1.5), Color(COLOR_BORDER, 0.15 * (1.0 - progress)), true)
		draw_style_box(_create_rounded_box(base_color, 6.0), segment_rect)

		if i == 0:
			_draw_head_eyes(segment_rect)


func _draw_head_eyes(head_rect: Rect2) -> void:
	var eye_offset: float = head_rect.size.x * 0.22
	var eye_a: Vector2 = head_rect.get_center()
	var eye_b: Vector2 = head_rect.get_center()

	if direction == DIR_RIGHT:
		eye_a = Vector2(head_rect.end.x - eye_offset, head_rect.position.y + head_rect.size.y * 0.32)
		eye_b = Vector2(head_rect.end.x - eye_offset, head_rect.position.y + head_rect.size.y * 0.68)
	elif direction == DIR_LEFT:
		eye_a = Vector2(head_rect.position.x + eye_offset, head_rect.position.y + head_rect.size.y * 0.32)
		eye_b = Vector2(head_rect.position.x + eye_offset, head_rect.position.y + head_rect.size.y * 0.68)
	elif direction == DIR_UP:
		eye_a = Vector2(head_rect.position.x + head_rect.size.x * 0.32, head_rect.position.y + eye_offset)
		eye_b = Vector2(head_rect.position.x + head_rect.size.x * 0.68, head_rect.position.y + eye_offset)
	else:
		eye_a = Vector2(head_rect.position.x + head_rect.size.x * 0.32, head_rect.end.y - eye_offset)
		eye_b = Vector2(head_rect.position.x + head_rect.size.x * 0.68, head_rect.end.y - eye_offset)

	var blink_scale: float = 0.35 if sin(visual_time * 3.0) > 0.985 else 1.0
	draw_circle(eye_a, 2.4 * blink_scale, Color.WHITE)
	draw_circle(eye_b, 2.4 * blink_scale, Color.WHITE)


func _create_rounded_box(box_color: Color, radius: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = box_color
	box.corner_radius_top_left = int(radius)
	box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius)
	box.corner_radius_bottom_right = int(radius)
	return box


func _draw_burst_particles() -> void:
	for particle in burst_particles:
		var particle_alpha: float = clampf(particle["life"] / particle["max_life"], 0.0, 1.0)
		draw_circle(
			particle["position"],
			particle["size"] * particle_alpha,
			Color(particle["color"], particle_alpha)
		)


func _draw_floating_texts() -> void:
	var font := ThemeDB.fallback_font
	for item in floating_texts:
		var pos: Vector2 = item["position"] - Vector2(30.0, 0.0)
		draw_string(font, pos, item["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(item["color"], item["alpha"]))


func _draw_flash() -> void:
	var board_rect: Rect2 = Rect2(board_position, BOARD_SIZE)
	if eat_pulse > 0.0:
		draw_rect(board_rect, Color(COLOR_BORDER, eat_pulse * 0.08), true)
	if death_flash > 0.0:
		draw_rect(board_rect, Color(COLOR_DANGER, death_flash * 0.14), true)


## ===== PROCEDURAL AUDIO SYNTHESIZERS (16-BIT 44.1 KHZ) =====
func _play_sfx(stream: AudioStreamWAV, pitch_multiplier: float = 1.0) -> void:
	if stream == null or sfx_player == null:
		return
	sfx_player.stream = stream
	sfx_player.pitch_scale = clampf(pitch_multiplier, 0.5, 2.0)
	sfx_player.play()


func _generate_crystal_bell(pitch_scale: float = 1.0) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.24
	var total_samples: int = int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var p1: float = 0.0
	var p2: float = 0.0
	var p3: float = 0.0

	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var f1: float = lerpf(880.0, 1760.0, pow(t, 0.5)) * pitch_scale
		var f2: float = f1 * 1.50
		var f3: float = f1 * 2.00

		p1 += (f1 * TAU) / float(sample_rate)
		p2 += (f2 * TAU) / float(sample_rate)
		p3 += (f3 * TAU) / float(sample_rate)

		var env: float = exp(-t * 11.0) * (1.0 - t)
		var s: float = (sin(p1) * 0.60 + sin(p2) * 0.28 + sin(p3) * 0.12) * env * 0.85
		var sample_val: int = clampi(int(s * 32767.0), -32768, 32767)

		var idx: int = i * 2
		data[idx] = sample_val & 0xFF
		data[idx + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_powerup_chime() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var notes: Array[float] = [440.0, 554.37, 659.25, 880.0, 1108.73]
	var note_dur: float = 0.045
	var total_samples: int = int(note_dur * float(notes.size()) * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var write_sample: int = 0
	for n in range(notes.size()):
		var freq: float = notes[n]
		var count: int = int(note_dur * float(sample_rate))
		var phase: float = 0.0
		for i in range(count):
			var t: float = float(i) / float(count)
			phase += (freq * TAU) / float(sample_rate)
			var osc: float = sin(phase) + 0.4 * sin(phase * 3.0)
			var env: float = (1.0 - t * 0.2) * 0.8
			var sample_val: int = clampi(int(osc * env * 32767.0), -32768, 32767)

			var idx: int = write_sample * 2
			data[idx] = sample_val & 0xFF
			data[idx + 1] = (sample_val >> 8) & 0xFF
			write_sample += 1

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_purge_whoosh() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.35
	var total_samples: int = int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(1200.0, 160.0, pow(t, 2.0))
		phase += (freq * TAU) / float(sample_rate)
		var noise: float = randf_range(-0.5, 0.5)
		var s: float = (sin(phase) * 0.6 + noise * 0.4) * exp(-t * 6.0)
		var sample_val: int = clampi(int(s * 32767.0), -32768, 32767)

		var idx: int = i * 2
		data[idx] = sample_val & 0xFF
		data[idx + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_cyber_fanfare() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50, 1318.51]
	var note_dur: float = 0.075
	var total_samples: int = int(note_dur * float(notes.size()) * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var write_sample: int = 0
	for n in range(notes.size()):
		var freq: float = notes[n]
		var count: int = int(note_dur * float(sample_rate))
		var phase: float = 0.0
		for i in range(count):
			var t: float = float(i) / float(count)
			phase += (freq * TAU) / float(sample_rate)
			var osc: float = sin(phase) + 0.35 * sin(phase * 2.0)
			var env: float = (1.0 - t * 0.25) * 0.75
			var sample_val: int = clampi(int(osc * env * 32767.0), -32768, 32767)

			var idx: int = write_sample * 2
			data[idx] = sample_val & 0xFF
			data[idx + 1] = (sample_val >> 8) & 0xFF
			write_sample += 1

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_glitch_impact() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.45
	var total_samples: int = int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var sub_phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var sub_f: float = lerpf(140.0, 32.0, t)
		sub_phase += (sub_f * TAU) / float(sample_rate)

		var sub_boom: float = sin(sub_phase) * exp(-t * 7.0)
		var crunch: float = randf_range(-1.0, 1.0) * exp(-t * 14.0) * 0.65
		var sample: float = (sub_boom * 0.75 + crunch * 0.35) * (1.0 - t)

		var sample_val: int = clampi(int(sample * 32767.0), -32768, 32767)
		var idx: int = i * 2
		data[idx] = sample_val & 0xFF
		data[idx + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_ui_pip() -> AudioStreamWAV:
	var sample_rate: int = 44100
	var duration: float = 0.04
	var total_samples: int = int(duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(400.0, 880.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var osc: float = sin(phase) * (1.0 - t) * 0.6
		var sample_val: int = clampi(int(osc * 32767.0), -32768, 32767)

		var idx: int = i * 2
		data[idx] = sample_val & 0xFF
		data[idx + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_synthwave_bgm() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var bpm: float = 120.0
	var beat_duration: float = 60.0 / bpm
	var bar_duration: float = beat_duration * 4.0
	var total_duration: float = bar_duration * 4.0
	var total_samples: int = int(total_duration * float(sample_rate))
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var bass_notes: Array[float] = [55.0, 55.0, 65.41, 48.99]
	var lead_arp: Array[float] = [220.0, 261.63, 329.63, 392.0, 440.0, 523.25, 659.25, 523.25]

	var bass_phase: float = 0.0
	var lead_phase: float = 0.0
	var pad_phase: float = 0.0

	for i in range(total_samples):
		var t_sec: float = float(i) / float(sample_rate)
		var bar_idx: int = int(t_sec / bar_duration) % bass_notes.size()
		var beat_progress: float = fmod(t_sec, beat_duration) / beat_duration

		var bass_freq: float = bass_notes[bar_idx]
		var sub_16th_step: float = fmod(t_sec, beat_duration * 0.25) / (beat_duration * 0.25)
		bass_phase += (bass_freq * TAU) / float(sample_rate)
		var bass_wave: float = (sin(bass_phase) + 0.4 * sin(bass_phase * 2.0)) * exp(-sub_16th_step * 3.5)

		var arp_idx: int = int(fmod(t_sec * 8.0, float(lead_arp.size())))
		var lead_freq: float = lead_arp[arp_idx]
		lead_phase += (lead_freq * TAU) / float(sample_rate)
		var lead_wave: float = sin(lead_phase) * exp(-fmod(t_sec * 8.0, 1.0) * 4.0) * 0.35

		pad_phase += ((bass_freq * 4.0) * TAU) / float(sample_rate)
		var pad_wave: float = sin(pad_phase) * 0.18

		var kick_sample: float = sin(pow(1.0 - beat_progress, 3.0) * 140.0) * exp(-beat_progress * 12.0) * 0.55
		var snare_hit: float = 0.0
		var beat_num: int = int(t_sec / beat_duration) % 4
		if beat_num == 1 or beat_num == 3:
			snare_hit = randf_range(-1.0, 1.0) * exp(-beat_progress * 9.0) * 0.25

		var mixed: float = (bass_wave * 0.45 + lead_wave * 0.30 + pad_wave + kick_sample + snare_hit) * 0.70
		var sample_val: int = clampi(int(mixed * 32767.0), -32768, 32767)

		var idx: int = i * 2
		data[idx] = sample_val & 0xFF
		data[idx + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


## ===== GRID HELPERS =====
func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(
		board_position.x + float(cell.x * CELL_SIZE),
		board_position.y + float(cell.y * CELL_SIZE),
		CELL_SIZE,
		CELL_SIZE
	)


func _cell_center(cell: Vector2i) -> Vector2:
	return _cell_rect(cell).get_center()
