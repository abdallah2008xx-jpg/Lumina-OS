import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080

    property color backgroundBase: config.backgroundBase ? config.backgroundBase : "#09131A"
    property color backgroundMid: config.backgroundMid ? config.backgroundMid : "#10212D"
    property color backgroundEdge: config.backgroundEdge ? config.backgroundEdge : "#214455"
    property color cardColor: config.cardColor ? config.cardColor : "#CC10212D"
    property color cardBorder: config.cardBorder ? config.cardBorder : "#33F7F3ED"
    property color primaryText: config.primaryText ? config.primaryText : "#F7F3ED"
    property color secondaryText: config.secondaryText ? config.secondaryText : "#C8D3DA"
    property color accentColor: config.accentColor ? config.accentColor : "#2D6C8A"
    property color accentSecondary: config.accentSecondary ? config.accentSecondary : "#3F8F95"
    property color accentWarm: config.accentWarm ? config.accentWarm : "#C9895B"
    property color dangerColor: config.dangerColor ? config.dangerColor : "#BC6454"
    property color infoColor: config.infoColor ? config.infoColor : "#3F8F95"
    property int sessionIndex: session.index

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    gradient: Gradient {
        GradientStop { position: 0.0; color: root.backgroundBase }
        GradientStop { position: 0.55; color: root.backgroundMid }
        GradientStop { position: 1.0; color: root.backgroundEdge }
    }

    Rectangle {
        x: width * 0.68
        y: height * 0.10
        width: 260
        height: 260
        radius: 130
        color: "#18F7F3ED"
    }

    Rectangle {
        x: -140
        y: height - 360
        width: 520
        height: 520
        radius: 260
        color: "#143F8F95"
    }

    Rectangle {
        anchors.fill: parent
        color: "#1209131A"
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            prompt.text = textConstants.loginSucceeded
            prompt.color = root.accentSecondary
        }

        function onLoginFailed() {
            password.text = ""
            prompt.text = textConstants.loginFailed
            prompt.color = root.dangerColor
        }

        function onInformationMessage(message) {
            prompt.text = message
            prompt.color = root.infoColor
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28
        height: 64
        color: "transparent"

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: root.accentSecondary
            }

            Column {
                spacing: 2

                Text {
                    text: "Lumina-OS"
                    color: root.primaryText
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    text: "Live Session"
                    color: root.secondaryText
                    font.pixelSize: 12
                }
            }
        }

        Clock {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.primaryText
            timeFont.pixelSize: 22
        }
    }

    Rectangle {
        id: card
        width: Math.min(parent.width * 0.32, 520)
        height: 560
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        radius: 28
        color: root.cardColor
        border.color: root.cardBorder
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            Text {
                text: textConstants.welcomeText.arg(sddm.hostName)
                color: root.primaryText
                font.pixelSize: 26
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Text {
                text: qsTr("Focused, calm, and ready for validation.")
                color: root.secondaryText
                font.pixelSize: 14
            }

            Rectangle {
                width: parent.width
                radius: 18
                color: "#142D6C8A"
                border.color: "#202D6C8A"

                Column {
                    width: parent.width
                    anchors.margins: 16
                    anchors.fill: parent
                    spacing: 6

                    Text {
                        width: parent.width
                        text: qsTr("Use this screen to validate the real login path for Lumina-OS, especially in login-test builds.")
                        color: root.primaryText
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Choose a different session entry only when you are intentionally testing another login path.")
                        color: root.secondaryText
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Text {
                text: textConstants.userName
                color: root.secondaryText
                font.pixelSize: 13
            }

            TextBox {
                id: name
                width: parent.width
                height: 42
                text: userModel.lastUser
                color: "#26F7F3ED"
                textColor: root.primaryText
                borderColor: "#20F7F3ED"
                focusColor: root.accentColor
                hoverColor: root.accentSecondary
                font.pixelSize: 16

                KeyNavigation.backtab: rebootButton
                KeyNavigation.tab: password
            }

            Text {
                text: textConstants.password
                color: root.secondaryText
                font.pixelSize: 13
            }

            PasswordBox {
                id: password
                width: parent.width
                height: 42
                color: "#26F7F3ED"
                textColor: root.primaryText
                borderColor: "#20F7F3ED"
                focusColor: root.accentColor
                hoverColor: root.accentSecondary
                font.pixelSize: 16

                KeyNavigation.backtab: name
                KeyNavigation.tab: session

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(name.text, password.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 10

                ComboBox {
                    id: session
                    width: keyboard.enabled && keyboard.layouts.length > 0 ? parent.width * 0.58 : parent.width
                    height: 40
                    model: sessionModel
                    index: sessionModel.lastIndex
                    color: "#20F7F3ED"
                    textColor: root.primaryText
                    borderColor: "#20F7F3ED"
                    focusColor: root.accentColor
                    hoverColor: root.accentSecondary
                    font.pixelSize: 14

                    KeyNavigation.backtab: password
                    KeyNavigation.tab: layoutBox.visible ? layoutBox : loginButton
                }

                LayoutBox {
                    id: layoutBox
                    visible: keyboard.enabled && keyboard.layouts.length > 0
                    width: parent.width * 0.42 - 10
                    height: 40
                    color: "#20F7F3ED"
                    textColor: root.primaryText
                    borderColor: "#20F7F3ED"
                    focusColor: root.accentColor
                    hoverColor: root.accentSecondary
                    font.pixelSize: 14

                    KeyNavigation.backtab: session
                    KeyNavigation.tab: loginButton
                }
            }

            Text {
                id: prompt
                width: parent.width
                text: textConstants.prompt
                color: root.secondaryText
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: 10

                Button {
                    id: loginButton
                    width: parent.width * 0.5 - 5
                    height: 44
                    text: textConstants.login
                    color: root.accentColor
                    textColor: root.primaryText
                    borderColor: root.accentSecondary
                    pressedColor: root.accentWarm
                    activeColor: root.accentSecondary
                    font.pixelSize: 16

                    onClicked: sddm.login(name.text, password.text, sessionIndex)

                    KeyNavigation.backtab: layoutBox.visible ? layoutBox : session
                    KeyNavigation.tab: shutdownButton
                }

                Button {
                    id: shutdownButton
                    width: parent.width * 0.25 - 5
                    height: 44
                    text: textConstants.shutdown
                    color: "#19F7F3ED"
                    textColor: root.primaryText
                    borderColor: "#20F7F3ED"
                    pressedColor: root.dangerColor
                    activeColor: root.accentWarm
                    font.pixelSize: 14

                    onClicked: sddm.powerOff()

                    KeyNavigation.backtab: loginButton
                    KeyNavigation.tab: rebootButton
                }

                Button {
                    id: rebootButton
                    width: parent.width * 0.25 - 5
                    height: 44
                    text: textConstants.reboot
                    color: "#19F7F3ED"
                    textColor: root.primaryText
                    borderColor: "#20F7F3ED"
                    pressedColor: root.accentWarm
                    activeColor: root.accentSecondary
                    font.pixelSize: 14

                    onClicked: sddm.reboot()

                    KeyNavigation.backtab: shutdownButton
                    KeyNavigation.tab: name
                }
            }

            Text {
                width: parent.width
                text: qsTr("Shutdown and reboot controls are intended for the current device or VM test pass.")
                color: root.secondaryText
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }
    }

    Component.onCompleted: {
        if (name.text === "") {
            name.focus = true
        } else {
            password.focus = true
        }
    }
}
