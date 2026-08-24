import QtQuick
import qs.Commons

// Three independent first-run checklist items:
//  - hyprland.lua loading what this plugin writes on Apply/Save. Without
//    this, Apply/Save still work fine (they're just file writes), but
//    nothing ever reaches the screen, which reads as the plugin doing
//    nothing. Genuinely blocks functionality, so this banner shows
//    whenever it's outstanding.
//  - an Omarchy menu entry. This is the idiomatic way a panel-kind plugin
//    with no bar icon becomes keyboard-reachable — first-party equivalents
//    (wifiqr, speedtest, disk-speedtest) all work this way, not via a
//    dedicated Hyprland keybind. Deliberately not suggesting one of those
//    either (an earlier version of this did): picking a key risks
//    colliding with an existing default the way this plugin's own
//    suggestion, SUPER+SHIFT+P, collided with one of Omarchy's own —
//    better left for anyone who wants one to bind by hand.
//  - taking over Omarchy's Display bar widget (SUPER+CTRL+D). Purely
//    opt-in preference, not a functionality gap — plenty of people are
//    happy with the stock Display widget.
// None of the three block each other; only the first gates functionality.
Item {
  id: root

  property bool configReady: false
  property bool menuEntryReady: false
  property bool displayTakeoverReady: false

  signal wireUpConfigRequested()
  signal wireUpMenuEntryRequested()
  signal wireUpDisplayTakeoverRequested()
  signal dismissed()

  Column {
    anchors.centerIn: parent
    width: Math.min(parent.width - Style.space(48), Style.space(440))
    spacing: Style.space(14)

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.configReady ? "Suggested setup" : "Setup required"
      font.family: Style.font.family
      font.bold: true
      font.pixelSize: Style.font.heading
      color: Color.foreground
    }

    SetupItem {
      width: parent.width
      done: root.configReady
      title: "Apply monitor layouts"
      body: "Hyprland's config doesn't load this plugin's monitor layouts yet. Add one line to ~/.config/hypr/hyprland.lua, right after require(\"hypr.monitors\"):"
      snippet: 'pcall(require, "hypr.hypr_screen")'
      doneText: "hyprland.lua already loads it"
      onAddRequested: root.wireUpConfigRequested()
    }

    SetupItem {
      width: parent.width
      done: root.menuEntryReady
      title: "Add to the Omarchy menu"
      body: "Not searchable from the Omarchy menu yet. Add a row to ~/.config/omarchy/extensions/omarchy-menu.jsonc:"
      snippet: '"trigger.monitor-profiles": { "action": "omarchy-shell shell summon …" }'
      doneText: "already registered — search “monitors”"
      onAddRequested: root.wireUpMenuEntryRequested()
    }

    SetupItem {
      width: parent.width
      done: root.displayTakeoverReady
      title: "Take over the Display widget (optional)"
      body: "Replace Omarchy's Display bar widget (SUPER+CTRL+D) with one that keeps its brightness/text-size/scale controls but swaps its per-display list for Monitor Profiles. Installs as a separate plugin (dev.shantzware.monitor-profiles-display) alongside this one — that's what makes the keybind route correctly."
      snippet: "omarchy plugin enable dev.shantzware.monitor-profiles-display"
      doneText: "already taking over Display — try SUPER+CTRL+D"
      onAddRequested: root.wireUpDisplayTakeoverRequested()
    }

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      text: "Skip for now — browse and edit profiles without applying"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.underline: true

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: root.dismissed()
      }
    }
  }
}
