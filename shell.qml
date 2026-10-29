import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Layer-shell overlay (not a normal app/terminal window).
PanelWindow {
    id: root
    focusable: true
    // Start shown so the first Super+Alt+N launch is visible; later presses toggle.
    visible: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Keep this distinct in hyprctl layers.
    WlrLayershell.namespace: "quick-note"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool previewMode: false
    property bool noteLoaded: false
    property string saveStatus: "LOADING"
    property bool closeWhenSaved: false
    property string currentTab: "scratch"
    property string searchQuery: ""
    property bool searchActive: false
    property bool commandPaletteActive: false
    property bool settingsActive: false
    property bool showLineNumbers: true
    property bool wordWrapEnabled: true

    function switchTab(tabName) {
        if (root.noteLoaded && root.saveStatus === "UNSAVED") {
            noteFile.setText(editor.text)
        }
        root.noteLoaded = false
        root.saveStatus = "LOADING"
        root.currentTab = tabName
        noteFile.path = "/home/raven/.local/share/quick-note/" + tabName + ".md"
    }

    // FileView.setText() does not emit onSaved when content is unchanged, so a
    // close that only waits on that signal gets stuck with visible:true forever.
    // Further toggles keep taking the "close" path and appear to do nothing.
    function requestClose() {
        saveTimer.stop()
        closeFallbackTimer.stop()

        if (!root.noteLoaded) {
            root.visible = false
            return
        }

        const nextText = editor.text
        if (nextText === noteFile.text()) {
            root.saveStatus = "SAVED"
            root.closeWhenSaved = false
            root.visible = false
            return
        }

        root.closeWhenSaved = true
        root.saveStatus = "SAVING"
        noteFile.setText(nextText)
        closeFallbackTimer.start()
    }

    function showNote() {
        closeFallbackTimer.stop()
        root.closeWhenSaved = false
        root.visible = true
    }

    IpcHandler {
        target: "quick-note"

        function toggle() {
            if (root.visible)
                root.requestClose()
            else
                root.showNote()
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            if (root.searchActive) {
                root.searchActive = false
                root.searchQuery = ""
            } else if (root.commandPaletteActive) {
                root.commandPaletteActive = false
            } else {
                root.requestClose()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.WindowShortcut
        onActivated: {
            root.searchActive = !root.searchActive
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+P"
        context: Qt.WindowShortcut
        onActivated: {
            root.commandPaletteActive = !root.commandPaletteActive
        }
    }

    Timer {
        id: closeFallbackTimer
        interval: 750
        repeat: false
        onTriggered: {
            if (root.closeWhenSaved) {
                root.closeWhenSaved = false
                root.visible = false
            }
        }
    }

    color: "transparent"

    FileView {
        id: noteFile
        path: "/home/raven/.local/share/quick-note/scratch.md"
        blockLoading: true

        onLoaded: {
            editor.text = text()
            root.noteLoaded = true
            root.saveStatus = "SAVED"
        }

        onSaved: {
            root.saveStatus = "SAVED"
            if (root.closeWhenSaved) {
                closeFallbackTimer.stop()
                root.closeWhenSaved = false
                root.visible = false
            }
        }

        onSaveFailed: error => {
            root.saveStatus = "SAVE FAILED"
            closeFallbackTimer.stop()
            root.closeWhenSaved = false
            root.visible = false
            console.warn("Quick-Note: could not save notes:", error)
        }

        onLoadFailed: error => {
            root.saveStatus = "LOAD FAILED"
            console.warn("Quick-Note: could not load notes:", error)
        }
    }

    Timer {
        id: saveTimer
        interval: 450
        repeat: false

        onTriggered: {
            if (root.noteLoaded) {
                root.saveStatus = "SAVING"
                noteFile.setText(editor.text)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 980)
            height: Math.min(parent.height - 48, 720)
            radius: 12
            color: "#17181D"
            border.color: "#41414F"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: 9
                        height: 9
                        radius: 5
                        color: "#A855F7"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "quick-note"
                        color: "#F3F0FA"
                        font.family: "monospace"
                        font.pixelSize: 19
                        font.bold: true
                    }

                    Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: ["scratch", "code", "ideas"]
                            delegate: Button {
                                text: modelData
                                onClicked: root.switchTab(modelData)

                                contentItem: Text {
                                    text: parent.text
                                    color: root.currentTab === modelData ? "#22D3EE" : "#9CA3AF"
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: root.currentTab === modelData ? "#272830" : "#1B1C22"
                                    border.color: root.currentTab === modelData ? "#22D3EE" : "#383944"
                                    radius: 4
                                }
                            }
                        }
                    }

                    Item {
                        width: 1
                        height: 1
                    }

                    Button {
                        text: "SETTINGS"
                        onClicked: root.settingsActive = !root.settingsActive

                        contentItem: Text {
                            text: parent.text
                            color: "#A855F7"
                            font.family: "monospace"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: "#272830"
                            border.color: "#65408A"
                            radius: 5
                        }
                    }

                    Button {
                        text: root.previewMode ? "WRITE" : "PREVIEW"
                        onClicked: root.previewMode = !root.previewMode

                        contentItem: Text {
                            text: parent.text
                            color: "#22D3EE"
                            font.family: "monospace"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: "#272830"
                            border.color: "#65408A"
                            radius: 5
                        }
                    }

                    Text {
                        text: root.saveStatus
                        color: root.saveStatus === "SAVED"
                               ? "#22D3EE" : "#C084FC"
                        font.family: "monospace"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#383944"
                }

                Row {
                    width: parent.width
                    spacing: 8
                    visible: root.settingsActive

                    Rectangle {
                        width: parent.width
                        height: 90
                        color: "#202127"
                        border.color: "#65408A"
                        radius: 6

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            width: parent.width - 20

                            Text {
                                text: "EDITOR PREFERENCES (KATE / MOUSEPAD STYLE)"
                                color: "#C084FC"
                                font.family: "monospace"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Row {
                                spacing: 12

                                Button {
                                    text: (root.showLineNumbers ? "Hide" : "Show") + " Lines"
                                    onClicked: root.showLineNumbers = !root.showLineNumbers
                                    contentItem: Text { text: parent.text; color: "#22D3EE"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }

                                Button {
                                    text: "Wrap: " + (editor.wrapMode === TextArea.Wrap ? "On" : "Off")
                                    onClicked: {
                                        editor.wrapMode = (editor.wrapMode === TextArea.Wrap ? TextArea.NoWrap : TextArea.Wrap)
                                    }
                                    contentItem: Text { text: parent.text; color: "#22D3EE"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }

                                Button {
                                    text: "Font -"
                                    onClicked: {
                                        if (editor.font.pixelSize > 10) editor.font.pixelSize -= 2
                                    }
                                    contentItem: Text { text: parent.text; color: "#C084FC"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }

                                Button {
                                    text: "Font + (" + editor.font.pixelSize + ")"
                                    onClicked: {
                                        if (editor.font.pixelSize < 24) editor.font.pixelSize += 2
                                        else editor.font.pixelSize = 12
                                    }
                                    contentItem: Text { text: parent.text; color: "#C084FC"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }

                                Button {
                                    text: "Select All"
                                    onClicked: editor.selectAll()
                                    contentItem: Text { text: parent.text; color: "#A855F7"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }

                                Button {
                                    text: "Clear Text"
                                    onClicked: editor.text = ""
                                    contentItem: Text { text: parent.text; color: "#EF4444"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }

                                Button {
                                    text: "Close Settings"
                                    onClicked: root.settingsActive = false
                                    contentItem: Text { text: parent.text; color: "#9CA3AF"; font.family: "monospace"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { color: "#272830"; border.color: "#383944"; radius: 4 }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8
                    visible: root.searchActive

                    TextField {
                        id: searchInput
                        width: parent.width - 80
                        height: 28
                        color: "#E5E7EB"
                        placeholderText: "Search in note..."
                        placeholderTextColor: "#777987"
                        font.family: "monospace"
                        font.pixelSize: 12
                        background: Rectangle {
                            color: "#202127"
                            border.color: "#65408A"
                            radius: 4
                        }
                        onTextChanged: {
                            root.searchQuery = text
                        }
                    }

                    Button {
                        width: 72
                        height: 28
                        text: "CLOSE"
                        onClicked: {
                            root.searchActive = false
                            root.searchQuery = ""
                            searchInput.text = ""
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#C084FC"
                            font.family: "monospace"
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: "#272830"
                            border.color: "#383944"
                            radius: 4
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(100, parent.height - 92)
                    radius: 8
                    color: "#202127"
                    border.color: "#383944"
                    border.width: 1

                    TextEdit {
                        anchors.fill: parent
                        anchors.margins: root.showLineNumbers ? 14 : 14
                        anchors.leftMargin: root.showLineNumbers ? 55 : 14
                        visible: root.previewMode
                        readOnly: true
                        text: editor.text
                        textFormat: TextEdit.MarkdownText
                        color: "#E5E7EB"
                        selectionColor: "#65408A"
                        selectedTextColor: "#FFFFFF"
                        font.family: "monospace"
                        font.pixelSize: 14
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                    }

                    Text {
                        id: lineNumbers
                        visible: !root.previewMode && root.showLineNumbers
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.topMargin: 14
                        anchors.leftMargin: 14
                        width: 35
                        color: "#555661"
                        font.family: "monospace"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignRight
                        lineHeight: editor.lineHeight
                        text: {
                            let count = editor.text.split('\n').length;
                            let res = "";
                            for (let i = 1; i <= count; i++) res += i + "\n";
                            return res;
                        }
                    }

                    TextArea {
                        id: editor
                        focus: !root.previewMode

                        anchors.fill: parent
                        anchors.margins: 14
                        anchors.leftMargin: root.showLineNumbers ? 55 : 14

                        color: "#E5E7EB"
                        selectionColor: "#65408A"
                        selectedTextColor: "#FFFFFF"
                        placeholderText: "# Quick notes\n\nType anything here..."
                        placeholderTextColor: "#777987"

                        font.family: "monospace"
                        font.pixelSize: 14
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        persistentSelection: true

                        background: Rectangle {
                            color: "transparent"
                        }

                        enabled: root.noteLoaded

                        onTextChanged: {
                            if (root.noteLoaded) {
                                root.saveStatus = "UNSAVED"
                                saveTimer.restart()
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: "#22D3EE"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "LOCAL MARKDOWN"
                        color: "#22D3EE"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }

                    Text {
                        text: "/"
                        color: "#555661"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }

                    Text {
                        text: "AUTOSAVE"
                        color: "#C084FC"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }

                    Item {
                        width: 1
                        height: 1
                    }

                    Text {
                        text: root.commandPaletteActive ? "SHORTCUTS: Ctrl+Shift+P (Palette), Ctrl+F (Search), Esc (Close)" : "Ctrl+Shift+P for Actions"
                        color: "#777987"
                        font.family: "monospace"
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
