extends CanvasLayer

var label: Label
var btn: Button
var t := 0.0
var last_event := ""

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
    btn = Button.new()
    btn.text = "MENU"
    btn.size = Vector2(170, 90)
    btn.pressed.connect(_press_menu)
    add_child(btn)

func _press_menu() -> void:
    Input.action_press("right_click")
    await get_tree().process_frame
    await get_tree().process_frame
    Input.action_release("right_click")

func _find_scrollers(node: Node, out: Array) -> void:
    if node is ScrollContainer and node.is_visible_in_tree():
        var bar = node.get_v_scroll_bar()
        if bar.max_value - bar.page > 1.0:
            out.append(node)
    for c in node.get_children():
        _find_scrollers(c, out)

func _get_scrollers() -> Array:
    var list := []
    if Globals.gui_3d and Globals.gui_3d.viewport:
        _find_scrollers(Globals.gui_3d.viewport, list)
    return list

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        last_event = event.as_text()
    if event is InputEventScreenTouch and event.pressed and event.index == 1:
        _press_menu()
    if event is InputEventScreenDrag and event.index == 0 and Globals.character:
        if Globals.character.state == CharacterWorker.States.MENU_MODE:
            var list := _get_scrollers()
            if not list.is_empty():
                var sc: ScrollContainer = list[list.size() - 1]
                sc.scroll_vertical = int(sc.scroll_vertical - event.relative.y * 1.5)

func _process(delta: float) -> void:
    var vs := get_viewport().get_visible_rect().size
    btn.position = Vector2(vs.x - 190, vs.y - 330)
    t += delta
    if t < 1.0:
        return
    t = 0.0
    var text := ""
    if Globals.character:
        text += "state: %s\n" % str(CharacterWorker.States.find_key(Globals.character.state))
        text += "scrollers: %d\n" % _get_scrollers().size()
    text += "last input: %s\n" % last_event
    label.text = text
    printerr("[IOSDBG] ", text.replace("\n", " | "))
