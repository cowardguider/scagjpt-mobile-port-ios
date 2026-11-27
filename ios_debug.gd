extends CanvasLayer

var label: Label
var t := 0.0
var last_event := ""

func _ready() -> void:
    layer = 128
    process_mode = Node.PROCESS_MODE_ALWAYS
    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.6)
    bg.position = Vector2(0, 40)
    bg.size = Vector2(740, 270)
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

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        last_event = event.as_text()
    if event is InputEventScreenTouch and event.pressed and event.index == 1:
        _press_menu()

func _process(delta: float) -> void:
    t += delta
    if t < 1.0:
        return
    t = 0.0
    var scene := get_tree().current_scene
    var cam := get_viewport().get_camera_3d()
    var text := "scene: %s\n" % (scene.scene_file_path if scene else "none")
    text += "viewport: %s\n" % str(get_viewport().get_visible_rect().size)
    text += "camera: %s\n" % (str(cam.global_position) if cam else "none")
    text += "character: %s\n" % str(Globals.character != null)
    if Globals.character:
        text += "state: %s\n" % str(CharacterWorker.States.find_key(Globals.character.state))
    text += "last input: %s\n" % last_event
    label.text = text
    printerr("[IOSDBG] ", text.replace("\n", " | "))
