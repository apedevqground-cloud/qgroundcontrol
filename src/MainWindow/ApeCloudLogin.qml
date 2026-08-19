// Ape QML shell - flight controls remain isolated
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property var hostWindow
    property string apiBaseUrl: "https://ominous-garbanzo-4g77jggvxjx37xp9-3000.app.github.dev/api"
    property string accessToken: ""
    property string userEmail: ""
    property bool loginBusy: false
    property bool loggedIn: false
    property bool online: false
    property string selectedDrone: qsTr("No drone selected")
    property int heartbeatIntervalMs: 30000
    readonly property color panelColor: "#101416"
    readonly property color panelAltColor: "#171b1d"
    readonly property color accentColor: "#ff8a00"
    readonly property color borderColor: "#34393c"

    function parseResponse(xhr) {
        try {
            return JSON.parse(xhr.responseText)
        } catch (error) {
            return null
        }
    }

    function apiRequest(method, path, body, callback) {
        var xhr = new XMLHttpRequest()
        xhr.open(method, root.apiBaseUrl + path)
        xhr.setRequestHeader("Accept", "application/json")
        if (body !== null)
            xhr.setRequestHeader("Content-Type", "application/json")
        if (root.accessToken.length > 0)
            xhr.setRequestHeader("Authorization", "Bearer " + root.accessToken)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE)
                callback(xhr.status, root.parseResponse(xhr))
        }
        xhr.send(body === null ? null : JSON.stringify(body))
    }

    function signIn() {
        errorText.text = ""
        var email = emailField.text.trim()
        if (email.length === 0 || passwordField.text.length < 8) {
            errorText.text = qsTr("Enter a valid email and a password of at least 8 characters.")
            return
        }

        root.loginBusy = true
        root.apiRequest("POST", "/auth/login", {
            email: email,
            password: passwordField.text
        }, function(status, response) {
            passwordField.text = ""
            if (status !== 200 || !response || !response.access_token) {
                root.loginBusy = false
                errorText.text = status === 401
                    ? qsTr("Email or password is incorrect.")
                    : qsTr("Ape Cloud is unavailable. Make sure the Codespace and port 8000 are running and public.")
                return
            }
            root.accessToken = response.access_token
            root.verifySession()
        })
    }

    function verifySession() {
        root.apiRequest("GET", "/auth/me", null, function(status, response) {
            root.loginBusy = false
            if (status !== 200 || !response || !response.email) {
                root.accessToken = ""
                errorText.text = qsTr("Ape Cloud could not verify this session.")
                return
            }
            root.userEmail = response.email
            root.loggedIn = true
            root.online = true
            root.loadDrones()
            root.sendHeartbeat()
            heartbeatTimer.start()
        })
    }

    function loadDrones() {
        root.apiRequest("GET", "/drones", null, function(status, response) {
            if (status === 200 && response && response.length > 0)
                root.selectedDrone = response[0].name
        })
    }

    function sendHeartbeat() {
        if (root.accessToken.length === 0)
            return
        root.apiRequest("POST", "/auth/heartbeat", {}, function(status, response) {
            root.online = status === 200 && response && response.status === "online"
            if (status === 401)
                root.signOut()
        })
    }

    function signOut() {
        heartbeatTimer.stop()
        root.accessToken = ""
        root.userEmail = ""
        root.online = false
        root.loggedIn = false
        root.selectedDrone = qsTr("No drone selected")
    }

    Timer {
        id: heartbeatTimer
        interval: root.heartbeatIntervalMs
        repeat: true
        running: false
        onTriggered: root.sendHeartbeat()
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
                    onAccepted: root.signIn()
                }
                Button {
                    Layout.fillWidth: true
                    text: root.loginBusy ? qsTr("Connecting…") : qsTr("Sign In")
                    highlighted: true
                    enabled: !root.loginBusy
                    onClicked: root.signIn()
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
                Label {
                    text: root.userEmail
                    color: "#9da4a8"
                    elide: Text.ElideRight
                    Layout.maximumWidth: 220
                }
                Button {
                    text: qsTr("Classic QGC")
                    onClicked: root.visible = false
                }
                Button {
                    text: qsTr("Sign Out")
                    onClicked: root.signOut()
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
