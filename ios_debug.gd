extends CanvasLayer

var label: Label
var btn: Button
var t := 0.0
var last_event := ""
var touches := {}
var starts := {}
var two_start := 0.0
var two_moved := 0.0
var drag_events := 0
var calls := 0

func _ready() -> void:
    layer = 128
    process_mode = Node.PROCESS_MODE_ALWAYS
    OS.low_processor_usage_mode = false
    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.5)
    bg.position = Vector2(0, 40)
    bg.size = Vector2(620, 290)
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

func _in_menu() -> bool:
    return Globals.character != null and Globals.character.state == CharacterWorker.States.MENU_MODE

func _scroll_by(dy: float) -> void:
    calls += 1
    var list := _get_scrollers()
    if list.is_empty():
        return
    var sc: ScrollContainer = list[list.size() - 1]
    sc.scroll_vertical = int(sc.scroll_vertical - dy * 1.5)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        last_event = event.as_text()
        if event.pressed:
            touches[event.index] = event.position
            starts[event.index] = event.position
            if touches.size() == 2:
                two_start = Time.get_ticks_msec() / 1000.0
                two_moved = 0.0
        else:
            var quick := Time.get_ticks_msec() / 1000.0 - two_start < 0.4
            if touches.size() == 2 and two_moved < 40.0 and quick:
                _press_menu()
            touches.erase(event.index)
            starts.erase(event.index)
    elif event is InputEventScreenDrag:
        drag_events += 1
        touches[event.index] = event.position
        if touches.size() >= 2:
            two_moved += event.relative.length()
            if _in_menu():
                _scroll_by(event.relative.y * 0.5)
        elif _in_menu() and starts.has(event.index):
            if event.position.distance_to(starts[event.index]) > 12.0:
                _scroll_by(event.relative.y)

func _process(delta: float) -> void:
    var vs := get_viewport().get_visible_rect().size
    btn.position = Vector2(vs.x - 190, vs.y - 330)
    t += delta
    if t < 1.0:
        return
    t = 0.0
    var text := ""
    if Globals.character:
        text += "state: %s  drags: %d\n" % [str(CharacterWorker.States.find_key(Globals.character.state)), drag_events]
        text += "calls: %d  inmenu: %s\n" % [calls, str(_in_menu())]
        var info := "none"
        var list := _get_scrollers()
        if not list.is_empty():
            var sc: ScrollContainer = list[list.size() - 1]
            var bar = sc.get_v_scroll_bar()
            info = "v=%d max=%d page=%d" % [sc.scroll_vertical, int(bar.max_value), int(bar.page)]
        text += "scroller: %s\n" % info
        var rig = Globals.character.rig
        if rig and rig.animation_tree:
            var tree = rig.animation_tree
            if not tree.active:
                tree.active = true
            text += "tree active: %s\n" % str(tree.active)
            text += "tree state: %s\n" % str(tree.get("parameters/state/current_state"))
            text += "player: %s\n" % (rig.animator.current_animation if rig.animator else "no player")
    text += "last input: %s\n" % last_event
    label.text = text
    printerr("[IOSDBG] ", text.replace("\n", " | "))
