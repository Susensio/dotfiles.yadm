import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Scratchpad chip in the workspace indicator's own language: dim while the
// scratchpad is empty, foreground while it holds windows, and the accent while
// it is the thing on screen.
//
// The accent rather than the workspaces widget's focus glyph: Hyprland keeps
// reporting the covered workspace as the active one while a special workspace
// is shown, so the bar already paints that glyph on the workspace underneath,
// and a second one only reads as a second focused workspace. The accent is also
// what the scratchpad window's own border wears.
BarWidget {
  id: root
  moduleName: "susensio.scratchpad"

  readonly property string specialId: "scratchpad"
  readonly property string specialName: "special:" + specialId

  // monitor name -> special workspace shown on it; absent means none is shown.
  property var shownSpecialByMonitor: ({})
  readonly property string focusedMonitor: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
  readonly property string shownSpecial: shownSpecialByMonitor[focusedMonitor] || ""

  function workspaceByName(name) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].name === name) return values[i]
    }

    return null
  }

  readonly property var scratchpad: workspaceByName(specialName)
  readonly property bool occupied: scratchpad !== null && scratchpad.toplevels.values.length > 0
  readonly property bool shown: shownSpecial === specialName

  function setShownSpecial(monitor, name) {
    var next = {}
    for (var key in shownSpecialByMonitor) {
      if (key !== monitor) next[key] = shownSpecialByMonitor[key]
    }
    if (monitor !== "" && name !== "") next[monitor] = name
    shownSpecialByMonitor = next
  }

  function seedShownSpecials(raw) {
    var monitors
    try {
      monitors = JSON.parse(raw)
    } catch (error) {
      return
    }
    if (!monitors || !monitors.length) return

    var next = {}
    for (var i = 0; i < monitors.length; i++) {
      var monitor = monitors[i]
      var name = monitor && monitor.specialWorkspace ? String(monitor.specialWorkspace.name || "") : ""
      if (name !== "") next[String(monitor.name || "")] = name
    }
    shownSpecialByMonitor = next
  }

  function toggle() {
    if (!root.bar) return
    // The quote keeps the lua expression in one argument, as omarchy.workspaces
    // does for its focus dispatches.
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.workspace.toggle_special(\"" + specialId + "\")"))
  }

  Component.onCompleted: seed.running = true

  Process {
    id: seed

    // A shell started while the scratchpad is already open has no event to see.
    // Bounded like the other bar widgets' queries: a wedged compositor must not
    // hold the shell.
    command: ["sh", "-c", "timeout --signal=KILL 2s hyprctl monitors -j | head -c 65536"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.seedShownSpecials(text)
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (!event) return

      var eventName = String(event.name || "")
      if (eventName !== "activespecial" && eventName !== "activespecialv2") return

      // activespecial:   "<special>,<monitor>"
      // activespecialv2: "<workspace-id>,<special>,<monitor>"
      var parts = String(event.data || "").split(",")
      if (eventName === "activespecialv2") root.setShownSpecial(parts[2] || "", parts[1] || "")
      else root.setShownSpecial(parts[1] || "", parts[0] || "")
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent

    bar: root.bar
    text: "S"
    active: root.shown
    activeColor: Color.accent
    opacity: root.occupied || root.shown ? 1 : 0.5
    horizontalMargin: 6
    verticalPadding: 6
    fixedWidth: root.vertical ? root.barSize : Style.space(20)
    fixedHeight: root.barSize
    tooltipText: "Scratchpad"
    onPressed: function() { root.toggle() }
  }
}
