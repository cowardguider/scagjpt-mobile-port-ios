extends CanvasLayer

var label
var btn
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
    var bg = ColorRect.new()
    bg.color = Color(0, 0, 0, 0.5)
    bg.position = Vector2(0, 40)
    bg.size = Vector2(640, 330)
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
    calls += 1
    var list = _get_scrollers()
    if list.is_empty():
        return
    var sc = list[list.size() - 1]
    sc.scroll_vertical = int(sc.scroll_vertical - dy * 1.5)

func _input(event) -> void:
    if event is InputEventScreenTouch:
        last_event = event.as_text()
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
        drag_events += 1
        touches[event.index] = event.position
        if touches.size() >= 2:
            two_moved += event.relative.length()
            if _in_menu():
                _scroll_by(event.relative.y * 0.5)
        elif _in_menu() and starts.has(event.index):
            if event.position.distance_to(starts[event.index]) > 12.0:
                _scroll_by(event.relative.y)

func _anim_report() -> String:
    var rig = Globals.character.rig
    if rig == null:
        return "no rig"
    var a = rig.animator
    if a == null:
        return "no animator"
    if not a.has_animation("anim/Idle"):
        return "no anim/Idle libs: " + str(a.get_animation_library_list())
    var anim = a.get_animation("anim/Idle")
    var base = a.get_node_or_null(a.root_node)
    var n = anim.get_track_count()
    var ok = 0
    for i in range(n):
        var p = anim.track_get_path(i)
        var node = null
        if base != null:
            node = base.get_node_or_null(NodePath(p.get_concatenated_names()))
        if node != null:
            ok += 1
    var res = "Idle tracks " + str(n) + " nodes ok " + str(ok)
    var sks = rig.find_children("*", "Skeleton3D", true, false)
    if not sks.is_empty():
        var sk = sks[0]
        res += "\nbone: " + str(sk.get_bone_pose_rotation(int(sk.get_bone_count() / 2)))
    return res

func _process(delta) -> void:
    var vs = get_viewport().get_visible_rect().size
    btn.position = Vector2(vs.x - 190, vs.y - 330)
    t += delta
    if t < 1.0:
        return
    t = 0.0
    var text = ""
    var ch = Globals.character
    if ch:
        text += "state: " + str(CharacterWorker.States.find_key(ch.state)) + "  drags: " + str(drag_events) + "\n"
        text += "roam on: " + str(ch.roaming_enabled) + "  off: " + str(ScreenBounds.target_window_position) + "  rot: " + str(snappedf(ch.rotation_degrees.y, 1.0)) + "\n"
        text += "inmenu: " + str(_in_menu()) + "  scrollers: " + str(_get_scrollers().size()) + "  calls: " + str(calls) + "\n"
        var rig = ch.rig
        if rig and rig.animation_tree:
            text += "tree: " + str(rig.animation_tree.get("parameters/state/current_state")) + "  active: " + str(rig.animation_tree.active) + "\n"
            text += _anim_report() + "\n"
    text += "last input: " + last_event + "\n"
    label.text = text
    printerr("[IOSDBG] ", text.replace("\n", " | "))
