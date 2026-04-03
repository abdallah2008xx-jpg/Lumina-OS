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
    property color glassBorder: "#58F7F3ED"
    property color cardHighlight: "#26FFFFFF"
    property int sessionIndex: session.index
    property string currentTimeText: ""
    property string currentDateText: ""

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    function refreshClockText() {
        var now = new Date()
        currentTimeText = Qt.formatTime(now, "hh:mm")
        currentDateText = Qt.formatDate(now, "dddd, MMMM d, yyyy")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refreshClockText()
    }

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#04090E" }
        GradientStop { position: 0.24; color: root.backgroundBase }
        GradientStop { position: 0.58; color: root.backgroundMid }
        GradientStop { position: 1.0; color: root.backgroundEdge }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#10000000" }
            GradientStop { position: 0.35; color: "#0409131A" }
            GradientStop { position: 1.0; color: "#220F3B47" }
        }
    }

    Rectangle {
        x: width * 0.66
        y: height * 0.06
        width: 330
        height: 330
        radius: 165
        color: "#245D8AF2"
    }

    Rectangle {
        x: width * 0.52
        y: height * 0.22
        width: 360
        height: 360
        radius: 180
        color: "#2650D6C9"
    }

    Rectangle {
        x: -140
        y: height - 360
        width: 520
        height: 520
        radius: 260
        color: "#22E4A57C"
    }

    Rectangle {
        anchors.fill: parent
        color: "#1209131A"
        border.color: "#14FFFFFF"
        border.width: 1
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
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28
        height: 70
        radius: 28
        color: "#18111C29"
        border.color: "#2CFFFFFF"
        border.width: 1

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
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

        Item {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20
            width: Math.min(parent.width * 0.34, 300)
            clip: true

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: root.currentTimeText
                    color: root.primaryText
                    font.pixelSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: root.currentDateText
                    color: root.secondaryText
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }

    Rectangle {
        id: card
        width: Math.min(parent.width - 72, 560)
        anchors.top: topBar.bottom
        anchors.topMargin: 22
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 28
        color: "transparent"
        border.color: root.glassBorder
        border.width: 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#B9132437" }
            GradientStop { position: 0.44; color: "#A5101F2F" }
            GradientStop { position: 1.0; color: "#92162E42" }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: parent.height * 0.26
            radius: parent.radius
            color: root.cardHighlight
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 28
            clip: true
            contentWidth: width
            contentHeight: contentColumn.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentColumn
                width: parent.width
                spacing: 12

                Text {
                    text: textConstants.welcomeText.arg(sddm.hostName)
                    color: root.primaryText
                    font.pixelSize: 22
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Text {
                    text: qsTr("Focused, calm, and ready for validation.")
                    color: root.secondaryText
                    font.pixelSize: 13
                }

                Rectangle {
                    width: parent.width
                    radius: 18
                    color: "#325A86D8"
                    border.color: "#54C8E5FF"
                    border.width: 1

                    Column {
                        width: parent.width
                        anchors.margins: 14
                        anchors.fill: parent
                        spacing: 4

                        Text {
                            width: parent.width
                            text: qsTr("Use this screen to validate the real login path for Lumina-OS, especially in login-test builds.")
                            color: root.primaryText
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Choose a different session entry only when you are intentionally testing another login path.")
                            color: root.secondaryText
                            font.pixelSize: 11
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
                        color: "#4A4D8FEA"
                        textColor: root.primaryText
                        borderColor: "#74C8E5FF"
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
                        color: "#24111C29"
                        textColor: root.primaryText
                        borderColor: "#40FFFFFF"
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
                        color: "#24111C29"
                        textColor: root.primaryText
                        borderColor: "#40FFFFFF"
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
    }

    Component.onCompleted: {
        refreshClockText()
        if (name.text === "") {
            name.focus = true
        } else {
            password.focus = true
        }
    }
}
