import QtQuick
import QtQuick.Window
import Quickshell
import "./LockPlugin" as LockPlugin

ShellRoot {
  Window {
    id: window
    width: 800
    height: 600
    visible: true

    LockPlugin.LockView {
      anchors.fill: parent
      inputEnabled: true
      loadBackground: false
    }

    TextInput {
      id: focusSink
      visible: false
    }

    Timer {
      interval: 50
      repeat: true
      running: true
      property int attempts: 0
      onTriggered: {
        attempts += 1
        if (!window.activeFocusItem || window.activeFocusItem.echoMode !== TextInput.Password) {
          if (attempts < 40) return
          stop()
          console.error("LOCK_FOCUS_TEST_FAIL: password input was not initially focused")
          Qt.quit()
          return
        }

        stop()
        focusSink.forceActiveFocus()
        if (!focusSink.activeFocus) {
          console.error("LOCK_FOCUS_TEST_FAIL: competing input could not take focus")
          Qt.quit()
          return
        }

        focusRecoveryCheck.start()
      }
    }

    Timer {
      id: focusRecoveryCheck
      interval: 250
      onTriggered: {
        if (!window.activeFocusItem || window.activeFocusItem.echoMode !== TextInput.Password)
          console.error("LOCK_FOCUS_TEST_FAIL: password input did not reclaim focus")
        else
          console.log("LOCK_FOCUS_TEST_PASS: password input reclaimed focus")
        Qt.quit()
      }
    }
  }
}
