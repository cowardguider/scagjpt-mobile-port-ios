extends CanvasLayer

var label: Label
var t := 0.0

func _ready() -> void:
    layer = 128
    process_mode = Node.PROCESS_MODE_ALWAYS
    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.75)
    bg.position = Vector2(0, 40)
    bg.size = Vector2(740, 330)
    add_child(bg)
    label = Label.new()
    label.position = Vector2(8, 44)
    label.add_theme_font_size_override("font_size", 22)
    add_child(label)

func _process(delta: float) -> void:
    t += delta
    if t < 1.0:
        return
    t = 0.0
    var scene := get_tree().current_scene
    var cam := get_viewport().get_camera_3d()
    var text := "scene: %s\n" % (scene.scene_file_path if scene else "none")
    text += "nodes: %d\n" % get_tree().get_node_count()
    text += "viewport: %s\n" % str(get_viewport().get_visible_rect().size)
    text += "window: %s\n" % str(DisplayServer.window_get_size())
    text += "screen: %s\n" % str(DisplayServer.screen_get_size())
    text += "camera: %s\n" % (str(cam.global_position) if cam else "none")
    text += "character: %s\n" % str(Globals.character != null)
    if Globals.character:
        text += "char pos: %s vis: %s\n" % [str(Globals.character.global_position), str(Globals.character.visible)]
    label.text = text
    printerr("[IOSDBG] ", text.replace("\n", " | "))
