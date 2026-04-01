import QtCore
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1280
    height: 820
    visible: true
    title: qsTr("Welcome to AhmadOS")
    color: "#09131A"

    property int currentStep: 0
    property string selectedLanguage: "ar"
    property string selectedAppearance: "light"
    property string selectedLayout: "balanced"
    property string selectedWallpaper: "/usr/share/ahmados/wallpapers/ahmados-lagoon.svg"
    property string selectedChannel: "stable"

    readonly property var pages: [
        {
            "eyebrow": qsTr("Welcome"),
            "title": qsTr("A calmer Linux desktop, ready from the first minute."),
            "body": qsTr("AhmadOS now saves real first-run choices for appearance, layout, wallpaper, and update direction instead of treating Welcome as a static tour."),
            "sideTitle": qsTr("What this pass now controls"),
            "items": [
                qsTr("Language preference for AhmadOS surfaces"),
                qsTr("Light and dark AhmadOS color directions"),
                qsTr("Balanced, Classic, or Minimal Plasma layouts"),
                qsTr("Wallpaper and release-channel defaults")
            ]
        },
        {
            "eyebrow": qsTr("Language"),
            "title": qsTr("Arabic and English should both feel intentional."),
            "body": qsTr("This choice is now saved as your AhmadOS preference so future first-party surfaces can honor it consistently."),
            "sideTitle": qsTr("Choose the preferred AhmadOS language"),
            "items": []
        },
        {
            "eyebrow": qsTr("Appearance"),
            "title": qsTr("Pick the surface tone and wallpaper direction."),
            "body": qsTr("The live session can now switch between the main AhmadOS palette and a dedicated night variant, alongside the branded wallpaper set."),
            "sideTitle": qsTr("Choose your visual baseline"),
            "items": []
        },
        {
            "eyebrow": qsTr("Desktop Layout"),
            "title": qsTr("Choose how Plasma should feel when the session settles."),
            "body": qsTr("You can now pick between the existing centered layout, a wider classic layout, or a tighter minimal layout for the panel baseline."),
            "sideTitle": qsTr("Choose your panel structure"),
            "items": []
        },
        {
            "eyebrow": qsTr("Updates"),
            "title": qsTr("Choose the release track you want AhmadOS to emphasize."),
            "body": qsTr("The Update Center now reads metadata from cacheable JSON, and this selection defines the release channel it should foreground."),
            "sideTitle": qsTr("Choose your release preference"),
            "items": []
        },
        {
            "eyebrow": qsTr("Ready"),
            "title": qsTr("Your AhmadOS session choices are ready to apply."),
            "body": qsTr("Closing Welcome now writes your selections to AhmadOS config and reapplies the live-session defaults on top of the current Plasma session."),
            "sideTitle": qsTr("What will happen next"),
            "items": [
                qsTr("The selected Plasma layout is applied"),
                qsTr("The selected AhmadOS color scheme is applied"),
                qsTr("The selected wallpaper becomes active"),
                qsTr("Update Center foregrounds the chosen release channel")
            ]
        }
    ]

    readonly property var languageChoices: [
        {
            "id": "ar",
            "label": qsTr("Arabic"),
            "body": qsTr("RTL-aware AhmadOS surfaces should prioritize Arabic-first reading comfort.")
        },
        {
            "id": "en",
            "label": qsTr("English"),
            "body": qsTr("Keep English as the preferred language for AhmadOS-first surfaces and onboarding copy.")
        }
    ]

    readonly property var appearanceChoices: [
        {
            "id": "light",
            "label": qsTr("Light"),
            "body": qsTr("Use the current AhmadOS palette with soft light surfaces and restrained blue accents.")
        },
        {
            "id": "dark",
            "label": qsTr("Night"),
            "body": qsTr("Use the new AhmadOSNight scheme for darker surfaces, brighter text, and calmer nighttime contrast.")
        }
    ]

    readonly property var wallpaperChoices: [
        {
            "id": "lagoon",
            "label": qsTr("Lagoon"),
            "body": qsTr("Balanced blue-green depth for the default AhmadOS direction."),
            "path": "/usr/share/ahmados/wallpapers/ahmados-lagoon.svg"
        },
        {
            "id": "horizon",
            "label": qsTr("Horizon"),
            "body": qsTr("Warmer morning tones with a lighter AhmadOS atmosphere."),
            "path": "/usr/share/ahmados/wallpapers/ahmados-horizon.svg"
        },
        {
            "id": "nocturne",
            "label": qsTr("Nocturne"),
            "body": qsTr("Darker evening composition tuned for the night palette."),
            "path": "/usr/share/ahmados/wallpapers/ahmados-nocturne.svg"
        }
    ]

    readonly property var layoutChoices: [
        {
            "id": "balanced",
            "label": qsTr("Balanced"),
            "body": qsTr("Centered and calm, with room for launcher, running apps, tray, and clock.")
        },
        {
            "id": "classic",
            "label": qsTr("Classic"),
            "body": qsTr("A wider bottom panel for a more traditional desktop stance.")
        },
        {
            "id": "minimal",
            "label": qsTr("Minimal"),
            "body": qsTr("A tighter centered panel with less width and a more focused silhouette.")
        }
    ]

    readonly property var channelChoices: [
        {
            "id": "stable",
            "label": qsTr("Stable"),
            "body": qsTr("Foreground the most normal-user-ready AhmadOS release path.")
        },
        {
            "id": "beta",
            "label": qsTr("Beta"),
            "body": qsTr("Track near-release AhmadOS builds that still need broader validation.")
        },
        {
            "id": "alpha",
            "label": qsTr("Alpha"),
            "body": qsTr("Follow earlier feature previews with visible rough edges.")
        },
        {
            "id": "dev",
            "label": qsTr("Dev"),
            "body": qsTr("Surface the earliest AhmadOS work where change is fastest and risk is highest.")
        }
    ]

    readonly property color ink: "#09131A"
    readonly property color mist: "#C8D3DA"
    readonly property color cloud: "#EDF2F4"
    readonly property color ivory: "#F7F3ED"
    readonly property color brand: "#2D6C8A"
    readonly property color lagoon: "#3F8F95"
    readonly property color copper: "#C9895B"
    readonly property color lineSoft: "#22F7F3ED"

    Settings {
        id: welcomeSettings
        location: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/ahmados/welcome.conf"
        property alias preferredLanguage: root.selectedLanguage
        property alias appearance: root.selectedAppearance
        property alias layout: root.selectedLayout
        property alias wallpaper: root.selectedWallpaper
        property alias channel: root.selectedChannel
    }

    function choiceLabel(choices, value, fallbackText) {
        for (var index = 0; index < choices.length; index++) {
            if (choices[index].id === value || choices[index].path === value) {
                return choices[index].label
            }
        }

        return fallbackText
    }

    function resolvedColorScheme() {
        return selectedAppearance === "dark" ? "AhmadOSNight" : "AhmadOS"
    }

    function resolvedLookAndFeel() {
        if (selectedLayout === "classic") {
            return "com.ahmados.desktop.classic"
        }

        if (selectedLayout === "minimal") {
            return "com.ahmados.desktop.minimal"
        }

        return "com.ahmados.desktop"
    }

    function currentNotice() {
        if (currentStep === 1) {
            return qsTr("Language preference is stored now for AhmadOS-owned surfaces. System-wide locale switching is still a later build step.")
        }

        if (currentStep === 2) {
            return qsTr("Appearance and wallpaper choices are applied to the live session after Welcome closes.")
        }

        if (currentStep === 3) {
            return qsTr("Layout selection maps to real Plasma look-and-feel packages added to the live image.")
        }

        if (currentStep === 4) {
            return qsTr("Update Center will use this channel as the foreground track when showing available release metadata.")
        }

        if (currentStep === 5) {
            return qsTr("Finish will save the config and reapply AhmadOS session defaults immediately.")
        }

        return qsTr("The Welcome app now behaves as a first-run settings writer, not only a visual tour.")
    }

    function currentContentComponent() {
        if (currentStep === 1) {
            return languageComponent
        }

        if (currentStep === 2) {
            return appearanceComponent
        }

        if (currentStep === 3) {
            return layoutComponent
        }

        if (currentStep === 4) {
            return channelComponent
        }

        if (currentStep === 5) {
            return readyComponent
        }

        return overviewComponent
    }

    function finishWelcome() {
        welcomeSettings.sync()
        root.close()
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#09131A" }
            GradientStop { position: 0.55; color: "#10212D" }
            GradientStop { position: 1.0; color: "#214455" }
        }
    }

    Rectangle {
        width: 420
        height: 420
        radius: 210
        x: root.width - 340
        y: -110
        color: "#14F7F3ED"
    }

    Rectangle {
        width: 520
        height: 520
        radius: 260
        x: -180
        y: root.height - 300
        color: "#163F8F95"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            radius: 30
            color: "#D6F7F3ED"
            border.color: lineSoft
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 22

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: "AhmadOS"
                            color: ink
                            font.pixelSize: 24
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Live orientation")
                            color: "#5B7180"
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: brand

                        Label {
                            anchors.centerIn: parent
                            text: "A"
                            color: ivory
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: pages.length

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: index <= root.currentStep ? brand : "#1809131A"
                        }
                    }
                }

                Label {
                    text: pages[currentStep].eyebrow
                    color: brand
                    font.pixelSize: 12
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: pages[currentStep].title
                    color: ink
                    wrapMode: Text.WordWrap
                    font.pixelSize: 38
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: pages[currentStep].body
                    color: "#4D6271"
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                    font.pixelSize: 17
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 24
                    color: "#AAEDF2F4"
                    border.color: "#1409131A"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 14

                        Label {
                            text: pages[currentStep].sideTitle
                            color: ink
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Loader {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: root.currentContentComponent()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        text: qsTr("Back")
                        enabled: root.currentStep > 0
                        onClicked: root.currentStep--
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        visible: root.currentStep < pages.length - 1
                        text: qsTr("Next")
                        onClicked: root.currentStep++
                    }

                    Button {
                        visible: root.currentStep === pages.length - 1
                        text: qsTr("Finish and Apply")
                        onClicked: root.finishWelcome()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 360
            radius: 30
            color: "#CC10212D"
            border.color: "#22F7F3ED"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Label {
                    text: qsTr("Session Preview")
                    color: ivory
                    font.pixelSize: 22
                    font.bold: true
                }

                Label {
                    text: qsTr("These choices are now written to AhmadOS config so the session can reuse them after Welcome closes.")
                    color: mist
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 22
                    color: "#142D6C8A"
                    border.color: "#222D6C8A"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Label {
                            text: qsTr("Current selection")
                            color: ivory
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Language") + ": " + root.choiceLabel(root.languageChoices, root.selectedLanguage, qsTr("Arabic"))
                            color: mist
                            font.pixelSize: 13
                        }

                        Label {
                            text: qsTr("Appearance") + ": " + root.choiceLabel(root.appearanceChoices, root.selectedAppearance, qsTr("Light"))
                            color: mist
                            font.pixelSize: 13
                        }

                        Label {
                            text: qsTr("Color scheme") + ": " + root.resolvedColorScheme()
                            color: mist
                            font.pixelSize: 13
                        }

                        Label {
                            text: qsTr("Layout") + ": " + root.choiceLabel(root.layoutChoices, root.selectedLayout, qsTr("Balanced"))
                            color: mist
                            font.pixelSize: 13
                        }

                        Label {
                            text: qsTr("Look-and-feel") + ": " + root.resolvedLookAndFeel()
                            color: mist
                            font.pixelSize: 13
                            wrapMode: Text.WrapAnywhere
                        }

                        Label {
                            text: qsTr("Wallpaper") + ": " + root.choiceLabel(root.wallpaperChoices, root.selectedWallpaper, qsTr("Lagoon"))
                            color: mist
                            font.pixelSize: 13
                        }

                        Label {
                            text: qsTr("Release channel") + ": " + root.choiceLabel(root.channelChoices, root.selectedChannel, qsTr("Stable"))
                            color: mist
                            font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 22
                    color: "#163F8F95"
                    border.color: "#203F8F95"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 8

                        Label {
                            text: qsTr("Live note")
                            color: ivory
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: root.currentNotice()
                            color: mist
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Close Welcome")
                    onClicked: root.close()
                }
            }
        }
    }

    Component {
        id: overviewComponent

        ColumnLayout {
            spacing: 12

            Repeater {
                model: pages[0].items

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: 18
                    color: "#CCFFFFFF"
                    border.color: "#1209131A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: index % 2 === 0 ? brand : lagoon
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData
                            color: ink
                            wrapMode: Text.WordWrap
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }

    Component {
        id: languageComponent

        ColumnLayout {
            spacing: 12

            Repeater {
                model: root.languageChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 88
                    radius: 20
                    color: modelData.id === root.selectedLanguage ? "#142D6C8A" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedLanguage ? "#2D6C8A" : "#1209131A"
                    border.width: modelData.id === root.selectedLanguage ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedLanguage = modelData.id
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.id === root.selectedLanguage ? ivory : ink
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedLanguage ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appearanceComponent

        ColumnLayout {
            spacing: 12

            Label {
                text: qsTr("Color direction")
                color: ink
                font.pixelSize: 16
                font.bold: true
            }

            Repeater {
                model: root.appearanceChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 88
                    radius: 20
                    color: modelData.id === root.selectedAppearance ? "#142D6C8A" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedAppearance ? "#2D6C8A" : "#1209131A"
                    border.width: modelData.id === root.selectedAppearance ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedAppearance = modelData.id
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.id === root.selectedAppearance ? ivory : ink
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedAppearance ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }
            }

            Label {
                text: qsTr("Wallpaper")
                color: ink
                font.pixelSize: 16
                font.bold: true
                topPadding: 6
            }

            Repeater {
                model: root.wallpaperChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 84
                    radius: 20
                    color: modelData.path === root.selectedWallpaper ? "#163F8F95" : "#CCFFFFFF"
                    border.color: modelData.path === root.selectedWallpaper ? "#203F8F95" : "#1209131A"
                    border.width: modelData.path === root.selectedWallpaper ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedWallpaper = modelData.path
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.path === root.selectedWallpaper ? ivory : ink
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Label {
                            text: modelData.body
                            color: modelData.path === root.selectedWallpaper ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    Component {
        id: layoutComponent

        ColumnLayout {
            spacing: 12

            Repeater {
                model: root.layoutChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 88
                    radius: 20
                    color: modelData.id === root.selectedLayout ? "#142D6C8A" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedLayout ? "#2D6C8A" : "#1209131A"
                    border.width: modelData.id === root.selectedLayout ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedLayout = modelData.id
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.id === root.selectedLayout ? ivory : ink
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedLayout ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    Component {
        id: channelComponent

        ColumnLayout {
            spacing: 12

            Repeater {
                model: root.channelChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 84
                    radius: 20
                    color: modelData.id === root.selectedChannel ? "#163F8F95" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedChannel ? "#203F8F95" : "#1209131A"
                    border.width: modelData.id === root.selectedChannel ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedChannel = modelData.id
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.id === root.selectedChannel ? ivory : ink
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedChannel ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    Component {
        id: readyComponent

        ColumnLayout {
            spacing: 12

            Repeater {
                model: pages[5].items

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: 18
                    color: "#CCFFFFFF"
                    border.color: "#1209131A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: index % 2 === 0 ? brand : copper
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData
                            color: ink
                            wrapMode: Text.WordWrap
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }
}
