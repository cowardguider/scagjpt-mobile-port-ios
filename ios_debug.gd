extends CanvasLayer

var label: Label
var t := 0.0
var last_event := ""
var scroll_accum := 0.0

func _ready() -> void:
    layer = 128
    process_mode = Node.PROCESS_MODE_ALWAYS
    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.5)
    bg.position = Vector2(0, 40)
    bg.size = Vector2(560, 150)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    label = Label.new()
    label.position = Vector2(8, 44)
    label.add_theme_font_size_override("font_size", 20)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)
    var btn := Button.new()
    btn.text = "MENU"
    var vs := get_viewport().get_visible_rect().size
    btn.size = Vector2(170, 90)
    btn.position = Vector2(vs.x - 190, vs.y - 330)
    btn.pressed.connect(_press_menu)
    add_child(btn)

func _press_menu() -> void:
    Input.action_press("right_click")
    await get_tree().process_frame
    await get_tree().process_frame
    Input.action_release("right_click")

func _wheel(up: bool, pos: Vector2) -> void:
    var w := InputEventMouseButton.new()
    w.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
    w.position = pos
    w.global_position = pos
    w.pressed = true
    Input.parse_input_event(w)
    var r := InputEventMouseButton.new()
    r.button_index = w.button_index
    r.position = pos
    r.global_position = pos
    r.pressed = false
    Input.parse_input_event(r)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        last_event = event.as_text()
    if event is InputEventScreenTouch and event.pressed and event.index == 1:
        _press_menu()
    if event is InputEventScreenDrag and event.index == 0 and Globals.character:
        if Globals.character.state == CharacterWorker.States.MENU_MODE:
            scroll_accum += event.relative.y
            while absf(scroll_accum) > 24.0:
                _wheel(scroll_accum > 0.0, event.position)
                scroll_accum -= 24.0 * signf(scroll_accum)

func _process(delta: float) -> void:
    t += delta
    if t < 1.0:
        return
    t = 0.0
    var text := ""
    if Globals.character:
        text += "state: %s\n" % str(CharacterWorker.States.find_key(Globals.character.state))
    text += "last input: %s\n" % last_event
    label.text = text
    printerr("[IOSDBG] ", text.replace("\n", " | "))
