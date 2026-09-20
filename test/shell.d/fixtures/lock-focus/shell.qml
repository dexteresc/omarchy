import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

ShellRoot {
  id: root

  readonly property string resultPath: Quickshell.env("OMARCHY_QML_TEST_RESULT")
  readonly property string rootPath: Quickshell.env("OMARCHY_PATH")
  property var failures: []
  property var lockView: null

  function fail(message) {
    failures.push(String(message))
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function writeResult() {
    var payload = JSON.stringify({
      ok: failures.length === 0,
      failures: failures
    })

    if (resultPath) {
      Quickshell.execDetached(["bash", "-lc", "printf '%s' " + shellQuote(payload) + " > " + shellQuote(resultPath)])
    }
  }

  PanelWindow {
    id: lockWindow
    visible: false
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-lock-focus-test"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors {
      top: true
      right: true
      bottom: true
      left: true
    }

    TextInput {
      id: focusSink
      visible: false
    }
  }

  Timer {
    interval: 1
    running: true
    repeat: false
    onTriggered: {
      try {
        var component = Qt.createComponent("file://" + root.rootPath + "/shell/plugins/lock/LockView.qml", Component.PreferSynchronous)
        if (component.status !== Component.Ready) {
          root.fail("LockView failed to load: " + component.errorString())
          root.writeResult()
          return
        }

        root.lockView = component.createObject(lockWindow.contentItem, {
          width: 800,
          height: 600,
          inputEnabled: true,
          loadBackground: false
        })
        if (!root.lockView) {
          root.fail("LockView failed to instantiate: " + component.errorString())
          root.writeResult()
          return
        }

        lockWindow.visible = true
        focusCheck.start()
      } catch (error) {
        root.fail("lock focus fixture threw: " + error)
        root.writeResult()
      }
    }
  }

  Timer {
    id: focusCheck
    interval: 50
    repeat: true
    property int attempts: 0
    onTriggered: {
      try {
        attempts += 1
        var window = root.lockView ? root.lockView.Window.window : null
        if (!window || !window.active) {
          if (attempts < 40) return
          stop()
          root.fail("lock window did not become active")
          root.writeResult()
          return
        }

        stop()
        var focused = window.activeFocusItem
        if (!focused || focused.echoMode !== TextInput.Password)
          root.fail("password input was not initially focused after mapping")

        focusSink.forceActiveFocus()
        if (!focusSink.activeFocus)
          root.fail("focus sink could not take focus from the password input")
        focusRecoveryCheck.start()
      } catch (error) {
        root.fail("lock focus check threw: " + error)
        root.writeResult()
      }
    }
  }

  Timer {
    id: focusRecoveryCheck
    interval: 250
    repeat: false
    onTriggered: {
      try {
        var window = root.lockView ? root.lockView.Window.window : null
        var focused = window ? window.activeFocusItem : null
        if (!focused || focused.echoMode !== TextInput.Password)
          root.fail("password input did not reclaim focus")
      } catch (error) {
        root.fail("lock focus recovery check threw: " + error)
      } finally {
        lockWindow.visible = false
        if (root.lockView) root.lockView.destroy()
        root.writeResult()
      }
    }
  }
}
