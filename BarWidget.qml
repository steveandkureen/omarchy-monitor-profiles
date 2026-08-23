import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

// Bar-icon quick-switcher: styled after Omarchy's own first-party bar
// widgets (Display/SUPER+CTRL+D, Bluetooth) rather than this plugin's own
// custom-drawn Panel.qml -- built on the shared qs.Ui components those use
// (Panel/BarIconButton/KeyboardPanel/PanelKeyCatcher/CursorSurface) so it
// looks and behaves like a native part of the bar: hjkl/arrows move a
// cursor, Enter/click applies, Tab cycles to the next bar widget's panel.
//
// This is a second, faster way to switch profiles -- the full switcher/
// editor in Panel.qml (kind: "panel", reached via the Omarchy menu or a
// keybind) is unchanged and still where profiles get created/edited.
Panel {
  id: root
  // Distinct from the plugin id itself: the shell's own plugin host already
  // auto-registers an IpcHandler under "dev.shantzware.monitor-profiles" to
  // wire up Panel.qml's open()/close() (the kind:"panel" summon contract).
  // Reusing that exact string here would collide with it -- only one
  // handler can own a given target, so whichever one loses would go silently
  // inert. This bar-widget doesn't need to be summon-able by id anyway; its
  // own icon plus Tab-cycling between bar-widget panels is how it's reached.
  moduleName: "dev.shantzware.monitor-profiles.bar"
  ipcTarget: "dev.shantzware.monitor-profiles.bar"

  // The Panel base is a plain Item, which doesn't auto-size to a child
  // anchored to fill it -- without these, Bar.qml's ModuleSlot reads this
  // root's implicitWidth/Height as 0 and never gives the icon any space at
  // all. Matches Display's and Bluetooth's own Panel.qml (easy to miss,
  // since it's declared here with the other root properties, not next to
  // the button it mirrors).
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property string home: Quickshell.env("HOME")
  readonly property string profilesDir: root.home + "/.config/hypr/profiles"
  readonly property string hyprScreenLuaPath: root.home + "/.config/hypr/hypr_screen.lua"
  readonly property string icon: "▦"

  property var profileNames: []
  property string activeProfileName: ""
  property string applyTarget: ""
  property int selectedIndex: 0
  property bool cursorActive: false

  function refresh() {
    listProc.running = false
    listProc.running = true
    activeProc.running = false
    activeProc.running = true
  }

  onOpenedChanged: {
    if (!opened) return
    cursorActive = false
    refresh()
  }

  onProfileNamesChanged: {
    if (selectedIndex >= profileNames.length) selectedIndex = Math.max(0, profileNames.length - 1)
    if (selectedIndex < 0) selectedIndex = 0
  }

  function moveCursor(delta) {
    if (profileNames.length === 0) return
    if (!cursorActive) { cursorActive = true; return }
    var next = selectedIndex + delta
    if (next < 0) next = 0
    if (next >= profileNames.length) next = profileNames.length - 1
    selectedIndex = next
  }

  function activateSelected() {
    if (selectedIndex < 0 || selectedIndex >= profileNames.length) return
    applyProfile(profileNames[selectedIndex])
  }

  // Same validate-then-build-path pattern as Panel.qml's applyProfileByName
  // and EditorView.qml's saveProfile/deleteProfile -- profileNames always
  // comes from a directory listing (never free-typed text) here, but this
  // stays the authoritative gate regardless of where a name came from.
  function applyProfile(name) {
    if (!Model.isValidProfileName(name)) return
    applyTarget = name
    applyFile.path = root.profilesDir + "/" + name + ".conf"
    applyFile.reload()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(280))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(420))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) { if (dy !== 0) root.moveCursor(dy) }
      onActivateRequested: root.activateSelected()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: panelColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

        Column {
          id: panelColumn
          width: scrollArea.availableWidth
          spacing: Style.space(14)

          // ---------- Hero: icon · title/active profile ----------
          Item {
            width: parent.width
            implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

            Text {
              id: heroIcon
              textFormat: Text.PlainText
              text: root.icon
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              id: heroLabels
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(14)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                textFormat: Text.PlainText
                text: "Monitor Profiles"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                textFormat: Text.PlainText
                text: root.activeProfileName !== "" ? root.activeProfileName.toUpperCase() : "NO ACTIVE PROFILE"
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
                elide: Text.ElideRight
                width: parent.width
              }
            }
          }

          PanelSeparator {
            foreground: root.bar.foreground
          }

          // ---------- Profiles ----------
          Text {
            textFormat: Text.PlainText
            visible: root.profileNames.length === 0
            text: "No profiles saved yet — use the full editor to create one."
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.Wrap
            width: parent.width
          }

          Repeater {
            model: root.profileNames

            ProfileRow {
              required property string modelData
              required property int index
              width: panelColumn.width
              name: modelData
              rowIndex: index
            }
          }
        }
      }
    }
  }

  component ProfileRow: CursorSurface {
    id: profileRow
    required property string name
    required property int rowIndex

    readonly property bool isActive: name === root.activeProfileName

    hasCursor: root.cursorActive && root.selectedIndex === rowIndex
    current: isActive
    foreground: root.bar.foreground
    fill: Style.hoverFillFor(root.bar.foreground, Color.accent)
    currentFill: Style.selectedFillFor(root.bar.foreground, Color.accent)
    implicitHeight: rowInner.implicitHeight + Style.spacing.xl

    Row {
      id: rowInner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: "•"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.title
        width: Style.space(22)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        text: profileRow.name
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
        width: parent.width - Style.space(22) - Style.space(14) - Style.space(16)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        text: profileRow.isActive ? "󰄬" : ""
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.subtitle
        width: Style.space(14)
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onContainsMouseChanged: if (containsMouse) {
        root.cursorActive = true
        root.selectedIndex = profileRow.rowIndex
      }
      onClicked: root.applyProfile(profileRow.name)
    }
  }

  // ---- process/file plumbing -------------------------------------------

  Process {
    id: listProc
    command: ["bash", "-lc", "ls -1 \"" + root.profilesDir + "\" 2>/dev/null | grep '\\.conf$'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n").filter(function(l) { return l.trim() !== "" })
        root.profileNames = lines.map(function(l) { return l.replace(/\.conf$/, "") }).sort()
      }
    }
  }

  Process {
    id: activeProc
    command: ["bash", "-lc", "cat \"" + root.hyprScreenLuaPath + "\" 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.activeProfileName = Model.activeProfileNameFromLua(String(text || ""))
      }
    }
  }

  FileView {
    id: applyFile
    watchChanges: false
    printErrors: false
    onLoaded: {
      var monitors = Model.parseProfileText(text())
      if (monitors.length === 0) return
      applyLuaFile.path = root.hyprScreenLuaPath
      applyLuaFile.setText(Model.profileToLua(monitors, root.applyTarget))
      reloadProc.running = true
    }
  }

  FileView {
    id: applyLuaFile
    watchChanges: false
    printErrors: false
  }

  Process {
    id: reloadProc
    command: ["hyprctl", "reload"]
    onExited: {
      root.activeProfileName = root.applyTarget
      root.close()
    }
  }
}
