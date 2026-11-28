extends CanvasLayer

var btn
var touches := {}
var starts := {}
var two_start := 0.0
var two_moved := 0.0

func _ready() -> void:
    layer = 128
    process_mode = Node.PROCESS_MODE_ALWAYS
    OS.low_processor_usage_mode = false
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

func _find_scrollers(node, out) -> void:
    if node is ScrollContainer and node.is_visible_in_tree():
        var bar = node.get_v_scroll_bar()
        if bar.max_value - bar.page > 1.0:
            out.append(node)
    for c in node.get_children():
        _find_scrollers(c, out)

func _get_scrollers() -> Array:
    var list = []
    if Globals.gui_3d and Globals.gui_3d.viewport:
        _find_scrollers(Globals.gui_3d.viewport, list)
    return list

func _in_menu() -> bool:
    return Globals.character != null and Globals.character.state == CharacterWorker.States.MENU_MODE

func _scroll_by(dy) -> void:
    var list = _get_scrollers()
    if list.is_empty():
        return
    var sc = list[list.size() - 1]
    sc.scroll_vertical = int(sc.scroll_vertical - dy * 1.5)

func _input(event) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touches[event.index] = event.position
            starts[event.index] = event.position
            if touches.size() == 2:
                two_start = Time.get_ticks_msec() / 1000.0
                two_moved = 0.0
        else:
            var quick = Time.get_ticks_msec() / 1000.0 - two_start < 0.4
            if touches.size() == 2 and two_moved < 40.0 and quick:
                _press_menu()
            touches.erase(event.index)
            starts.erase(event.index)
    elif event is InputEventScreenDrag:
        touches[event.index] = event.position
        if touches.size() >= 2:
            two_moved += event.relative.length()
            if _in_menu():
                _scroll_by(event.relative.y * 0.5)
        elif _in_menu() and starts.has(event.index):
            if event.position.distance_to(starts[event.index]) > 12.0:
                _scroll_by(event.relative.y)

func _process(delta) -> void:
    var vs = get_viewport().get_visible_rect().size
    btn.position = Vector2(vs.x - 190, vs.y - 330)
