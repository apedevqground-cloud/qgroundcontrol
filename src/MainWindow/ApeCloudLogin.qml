import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    anchors.fill: parent
    color: "#111111"

    property string apiBaseUrl: "https://api.example.invalid"
    property bool loggedIn: false
    property bool online: false
    property string selectedDrone: ""
    property int heartbeatIntervalMs: 30000

    function mockLogin() {
        errorText.text = ""
        if (emailField.text.trim().length === 0 || passwordField.text.length < 8) {
            errorText.text = qsTr("Enter a valid email and a password of at least 8 characters.")
            return
        }
        loggedIn = true
        online = true
        selectedDrone = qsTr("Drone selection will be connected to Ape Cloud.")
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
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 460)
        height: contentColumn.implicitHeight + 64
        radius: 18
        color: "#1d1d1b"
        border.color: "#353535"

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 32
            spacing: 16

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 170
                Layout.preferredHeight: 90
                source: "qrc:/res/ApeLogoDark.svg"
                fillMode: Image.PreserveAspectFit
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.loggedIn ? qsTr("Ape Cloud Connected") : qsTr("Sign in to Ape Cloud")
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            TextField {
                id: emailField
                Layout.fillWidth: true
                visible: !root.loggedIn
                placeholderText: qsTr("Email")
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                visible: !root.loggedIn
                placeholderText: qsTr("Password")
                echoMode: TextInput.Password
                onAccepted: root.mockLogin()
            }

            Button {
                Layout.fillWidth: true
                visible: !root.loggedIn
                text: qsTr("Sign In")
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
                Layout.alignment: Qt.AlignHCenter
                visible: root.loggedIn
                text: root.online ? qsTr("Online") : qsTr("Offline")
                color: root.online ? "#65db8a" : "#aaaaaa"
                font.bold: true
            }

            Label {
                Layout.fillWidth: true
                visible: root.loggedIn
                text: root.selectedDrone
                color: "#cccccc"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                Layout.fillWidth: true
                visible: root.loggedIn
                text: qsTr("Continue to QGroundControl")
                onClicked: root.visible = false
            }
        }
    }
}
