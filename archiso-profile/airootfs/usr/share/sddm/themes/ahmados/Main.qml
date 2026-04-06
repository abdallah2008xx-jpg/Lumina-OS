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
    property real widthScale: Math.max(0.8, Math.min(1.0, width / 1600))
    property real heightScale: Math.max(0.82, Math.min(1.0, height / 900))
    property real uiScale: Math.min(widthScale, heightScale)
    property bool compactMode: width < 1440 || height < 900
    property int outerMargin: scalePx(28, 16)
    property int topBarHeight: scalePx(70, 56)
    property int topBarRadius: scalePx(28, 22)
    property int cardRadius: scalePx(28, 22)
    property int cardPadding: scalePx(28, 18)
    property int contentSpacing: scalePx(12, 8)
    property int controlHeight: scalePx(42, 38)
    property int buttonHeight: scalePx(44, 40)
    property int titleSize: scalePx(22, 18)
    property int bodySize: scalePx(13, 11)
    property int smallBodySize: scalePx(12, 10)
    property int tinyBodySize: scalePx(11, 10)

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    function scalePx(value, minimum) {
        return Math.max(minimum, Math.round(value * uiScale))
    }

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
        anchors.margins: root.outerMargin
        height: root.topBarHeight
        radius: root.topBarRadius
        color: "#18111C29"
        border.color: "#2CFFFFFF"
        border.width: 1

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.scalePx(20, 14)
            spacing: root.scalePx(12, 10)

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
                    font.pixelSize: root.titleSize
                    font.bold: true
                }

                Text {
                    text: "Live Session"
                    color: root.secondaryText
                    font.pixelSize: root.smallBodySize
                }
            }
        }

        Item {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: root.scalePx(20, 14)
            width: Math.min(parent.width * 0.34, root.scalePx(300, 220))
            clip: true

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: root.currentTimeText
                    color: root.primaryText
                    font.pixelSize: root.titleSize
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: root.currentDateText
                    color: root.secondaryText
                    font.pixelSize: root.smallBodySize
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
        width: Math.min(parent.width - (root.outerMargin * 2), root.scalePx(560, 440))
        anchors.top: topBar.bottom
        anchors.topMargin: root.scalePx(22, 16)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.scalePx(20, 14)
        anchors.horizontalCenter: parent.horizontalCenter
        radius: root.cardRadius
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
            anchors.margins: root.cardPadding
            clip: true
            contentWidth: width
            contentHeight: contentColumn.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentColumn
                width: parent.width
                spacing: root.contentSpacing

                Rectangle {
                    id: introCard
                    width: parent.width
                    height: introCardContent.implicitHeight + root.scalePx(36, 26)
                    radius: root.scalePx(18, 14)
                    color: "#284D6A8D"
                    border.color: "#44C8E5FF"
                    border.width: 1

                    Column {
                        id: introCardContent
                        width: parent.width - root.scalePx(36, 26)
                        anchors.margins: root.scalePx(18, 13)
                        anchors.fill: parent
                        spacing: root.scalePx(6, 4)

                        Text {
                            width: parent.width
                            text: textConstants.welcomeText.arg(sddm.hostName)
                            color: root.primaryText
                            font.pixelSize: root.scalePx(19, 16)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Focused, calm, and ready for validation.")
                            color: root.secondaryText
                            font.pixelSize: root.bodySize
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Use this screen to validate the real login path for Lumina-OS, especially in login-test builds.")
                            color: root.primaryText
                            font.pixelSize: root.smallBodySize
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Choose a different session entry only when you are intentionally testing another login path.")
                            color: root.secondaryText
                            font.pixelSize: root.tinyBodySize
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Text {
                    text: textConstants.userName
                    color: root.secondaryText
                    font.pixelSize: root.bodySize
                }

                TextBox {
                    id: name
                    width: parent.width
                    height: root.controlHeight
                    text: userModel.lastUser
                    color: "#26F7F3ED"
                    textColor: root.primaryText
                    borderColor: "#20F7F3ED"
                    focusColor: root.accentColor
                    hoverColor: root.accentSecondary
                    font.pixelSize: root.scalePx(16, 14)

                    KeyNavigation.backtab: rebootButton
                    KeyNavigation.tab: password
                }

                Text {
                    text: textConstants.password
                    color: root.secondaryText
                    font.pixelSize: root.bodySize
                }

                PasswordBox {
                    id: password
                    width: parent.width
                    height: root.controlHeight
                    color: "#26F7F3ED"
                    textColor: root.primaryText
                    borderColor: "#20F7F3ED"
                    focusColor: root.accentColor
                    hoverColor: root.accentSecondary
                    font.pixelSize: root.scalePx(16, 14)

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
                    spacing: root.scalePx(10, 8)

                    ComboBox {
                        id: session
                        width: keyboard.enabled && keyboard.layouts.length > 0 ? parent.width * 0.58 : parent.width
                        height: root.scalePx(40, 36)
                        model: sessionModel
                        index: sessionModel.lastIndex
                        color: "#20F7F3ED"
                        textColor: root.primaryText
                        borderColor: "#20F7F3ED"
                        focusColor: root.accentColor
                        hoverColor: root.accentSecondary
                        font.pixelSize: root.scalePx(14, 12)

                        KeyNavigation.backtab: password
                        KeyNavigation.tab: layoutBox.visible ? layoutBox : loginButton
                    }

                    LayoutBox {
                        id: layoutBox
                        visible: keyboard.enabled && keyboard.layouts.length > 0
                        width: parent.width * 0.42 - 10
                        height: root.scalePx(40, 36)
                        color: "#20F7F3ED"
                        textColor: root.primaryText
                        borderColor: "#20F7F3ED"
                        focusColor: root.accentColor
                        hoverColor: root.accentSecondary
                        font.pixelSize: root.scalePx(14, 12)

                        KeyNavigation.backtab: session
                        KeyNavigation.tab: loginButton
                    }
                }

                Text {
                    id: prompt
                    width: parent.width
                    text: textConstants.prompt
                    color: root.secondaryText
                    font.pixelSize: root.smallBodySize
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: root.scalePx(10, 8)

                    Button {
                        id: loginButton
                        width: parent.width * 0.5 - 5
                        height: root.buttonHeight
                        text: textConstants.login
                        color: "#4A4D8FEA"
                        textColor: root.primaryText
                        borderColor: "#74C8E5FF"
                        pressedColor: root.accentWarm
                        activeColor: root.accentSecondary
                        font.pixelSize: root.scalePx(16, 14)

                        onClicked: sddm.login(name.text, password.text, sessionIndex)

                        KeyNavigation.backtab: layoutBox.visible ? layoutBox : session
                        KeyNavigation.tab: shutdownButton
                    }

                    Button {
                        id: shutdownButton
                        width: parent.width * 0.25 - 5
                        height: root.buttonHeight
                        text: textConstants.shutdown
                        color: "#24111C29"
                        textColor: root.primaryText
                        borderColor: "#40FFFFFF"
                        pressedColor: root.dangerColor
                        activeColor: root.accentWarm
                        font.pixelSize: root.scalePx(14, 12)

                        onClicked: sddm.powerOff()

                        KeyNavigation.backtab: loginButton
                        KeyNavigation.tab: rebootButton
                    }

                    Button {
                        id: rebootButton
                        width: parent.width * 0.25 - 5
                        height: root.buttonHeight
                        text: textConstants.reboot
                        color: "#24111C29"
                        textColor: root.primaryText
                        borderColor: "#40FFFFFF"
                        pressedColor: root.accentWarm
                        activeColor: root.accentSecondary
                        font.pixelSize: root.scalePx(14, 12)

                        onClicked: sddm.reboot()

                        KeyNavigation.backtab: shutdownButton
                        KeyNavigation.tab: name
                    }
                }

                Text {
                    width: parent.width
                    text: qsTr("Shutdown and reboot controls are intended for the current device or VM test pass.")
                    color: root.secondaryText
                    font.pixelSize: root.tinyBodySize
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
