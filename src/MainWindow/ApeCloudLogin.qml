// Ape QML shell - flight controls remain isolated
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property var hostWindow
    property string apiBaseUrl: "https://api.example.invalid"
    property bool loggedIn: false
    property bool online: false
    property string selectedDrone: qsTr("No drone selected")
    property int heartbeatIntervalMs: 30000
    readonly property color panelColor: "#101416"
    readonly property color panelAltColor: "#171b1d"
    readonly property color accentColor: "#ff8a00"
    readonly property color borderColor: "#34393c"

    function mockLogin() {
        errorText.text = ""
        if (emailField.text.trim().length === 0 || passwordField.text.length < 8) {
            errorText.text = qsTr("Enter a valid email and a password of at least 8 characters.")
            return
        }
        loggedIn = true
        online = true
        heartbeatTimer.start()
    }

    Timer {
        id: heartbeatTimer
        interval: root.heartbeatIntervalMs
        repeat: true
        running: false
        onTriggered: root.online = true
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.loggedIn
        color: "#0b0d0e"

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 460)
            height: loginColumn.implicitHeight + 64
            radius: 18
            color: root.panelAltColor
            border.color: root.borderColor

            ColumnLayout {
                id: loginColumn
                anchors.fill: parent
                anchors.margins: 32
                spacing: 16

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 100
                    source: "qrc:/res/ApeLogoDark.svg"
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Sign in to Ape Cloud")
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }
                TextField {
                    id: emailField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Email")
                    inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                }
                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    onAccepted: root.mockLogin()
                }
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Sign In")
                    highlighted: true
                    onClicked: root.mockLogin()
                }
                Label {
                    id: errorText
                    Layout.fillWidth: true
                    visible: text.length > 0
                    color: "#ff6b6b"
                    wrapMode: Text.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Account registration is available on the Ape Cloud website.")
                    color: "#9da4a8"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.loggedIn

        Rectangle {
            id: topBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 64
            color: root.panelColor
            border.color: root.borderColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 22

                Label {
                    text: qsTr("Ape Ground Control")
                    color: root.accentColor
                    font.pixelSize: 22
                    font.bold: true
                }
                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.borderColor }
                ColumnLayout {
                    spacing: 0
                    Label { text: qsTr("CLOUD"); color: "#889095"; font.pixelSize: 10 }
                    Label { text: root.online ? qsTr("Connected") : qsTr("Offline"); color: root.online ? "#48d597" : "#ff6b6b"; font.bold: true }
                }
                ColumnLayout {
                    spacing: 0
                    Label { text: qsTr("VEHICLE"); color: "#889095"; font.pixelSize: 10 }
                    Label { text: root.selectedDrone; color: "white"; font.bold: true }
                }
                Item { Layout.fillWidth: true }
                Label { text: Qt.formatTime(new Date(), "hh:mm:ss"); color: "white"; font.pixelSize: 16 }
                Button {
                    text: qsTr("Classic QGC")
                    onClicked: root.visible = false
                }
            }
        }

        Rectangle {
            id: sideBar
            anchors.left: parent.left
            anchors.top: topBar.bottom
            anchors.bottom: bottomBar.top
            width: parent.width < 800 ? 76 : 190
            color: root.panelColor
            border.color: root.borderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: [
                        { label: qsTr("FLY"), action: "fly" },
                        { label: qsTr("PLAN"), action: "plan" },
                        { label: qsTr("VEHICLES"), action: "vehicles" },
                        { label: qsTr("SETTINGS"), action: "settings" }
                    ]
                    delegate: Button {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        text: sideBar.width < 100 ? modelData.label.charAt(0) : modelData.label
                        highlighted: modelData.action === "fly"
                        onClicked: {
                            if (!root.hostWindow) return
                            if (modelData.action === "fly") root.hostWindow.showFlyView()
                            else if (modelData.action === "plan") root.hostWindow.showPlanView()
                            else if (modelData.action === "settings") root.hostWindow.showSettingsTool()
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: sideBar.width < 100 ? 44 : 110
                    Layout.preferredHeight: 54
                    source: "qrc:/res/ApeLogoDark.svg"
                    fillMode: Image.PreserveAspectFit
                }
            }
        }

        Rectangle {
            id: telemetryPanel
            visible: parent.width >= 1100
            anchors.right: parent.right
            anchors.top: topBar.bottom
            anchors.bottom: bottomBar.top
            width: 300
            color: root.panelColor
            border.color: root.borderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14
                Label { text: qsTr("STATUS"); color: root.accentColor; font.bold: true; font.pixelSize: 18 }
                Repeater {
                    model: [
                        { title: qsTr("Cloud"), value: root.online ? qsTr("Online") : qsTr("Offline") },
                        { title: qsTr("Drone"), value: root.selectedDrone },
                        { title: qsTr("Telemetry"), value: qsTr("Not connected") },
                        { title: qsTr("Battery"), value: "—" },
                        { title: qsTr("GPS"), value: "—" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 66
                        color: root.panelAltColor
                        radius: 8
                        border.color: root.borderColor
                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            Label { text: modelData.title; color: "#8d9599"; font.pixelSize: 11 }
                            Label { text: modelData.value; color: "white"; font.pixelSize: 17; font.bold: true }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            id: bottomBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 76
            color: root.panelColor
            border.color: root.borderColor

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Repeater {
                    model: [qsTr("ARM"), qsTr("TAKEOFF"), qsTr("RTL"), qsTr("LAND"), qsTr("START MISSION"), qsTr("EMERGENCY STOP")]
                    delegate: Button {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData
                        enabled: false
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Disabled until flight controls are explicitly integrated.")
                    }
                }
            }
        }
    }
}
