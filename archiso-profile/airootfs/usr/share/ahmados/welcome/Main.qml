import QtCore
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    readonly property int availableScreenWidth: Screen.desktopAvailableWidth > 0 ? Screen.desktopAvailableWidth : Screen.width
    readonly property int availableScreenHeight: Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : Screen.height
    readonly property bool compact: availableScreenWidth > 0 && availableScreenWidth < 1180 || availableScreenHeight > 0 && availableScreenHeight < 820
    readonly property bool narrow: availableScreenWidth > 0 && availableScreenWidth < 1050 || availableScreenHeight > 0 && availableScreenHeight < 760
    readonly property real uiScale: narrow ? 0.82 : compact ? 0.9 : 1.0
    readonly property int edgeMargin: Math.max(16, Math.round(24 * uiScale))
    readonly property int panelSpacing: Math.max(12, Math.round(20 * uiScale))
    readonly property int shellRadius: Math.max(24, Math.round(30 * uiScale))
    readonly property int shellPadding: Math.max(18, Math.round(28 * uiScale))
    readonly property int sectionSpacing: Math.max(14, Math.round(22 * uiScale))
    readonly property int optionSpacing: Math.max(8, Math.round(12 * uiScale))
    readonly property int heroTitleSize: narrow ? 28 : compact ? 32 : 38
    readonly property int heroBodySize: narrow ? 14 : compact ? 15 : 17
    readonly property int headingSize: narrow ? 20 : 22
    readonly property int cardTitleSize: narrow ? 15 : 18
    readonly property int labelSize: narrow ? 12 : 13
    readonly property int choiceTitleSize: narrow ? 16 : 18
    readonly property int chipTextSize: 11
    width: availableScreenWidth > 0 ? Math.min(1280, Math.max(920, availableScreenWidth - 40)) : 1280
    height: availableScreenHeight > 0 ? Math.min(820, Math.max(680, availableScreenHeight - 56)) : 820
    visible: true
    visibility: compact ? Window.Maximized : Window.Windowed
    title: qsTr("Welcome to Lumina-OS")
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
            "body": qsTr("Lumina-OS now saves real first-run choices for appearance, layout, wallpaper, and update direction instead of treating Welcome as a static tour."),
            "sideTitle": qsTr("What this pass now controls"),
            "items": [
                qsTr("Language preference for Lumina-OS surfaces"),
                qsTr("Light and dark Lumina-OS color directions"),
                qsTr("Balanced, Classic, or Minimal Plasma layouts"),
                qsTr("Wallpaper and release-channel defaults")
            ]
        },
        {
            "eyebrow": qsTr("Language"),
            "title": qsTr("Arabic and English should both feel intentional."),
            "body": qsTr("This choice is now saved as your Lumina-OS preference so future first-party surfaces can honor it consistently."),
            "sideTitle": qsTr("Choose the preferred Lumina-OS language"),
            "items": []
        },
        {
            "eyebrow": qsTr("Appearance"),
            "title": qsTr("Pick the surface tone and wallpaper direction."),
            "body": qsTr("The live session can now switch between the main Lumina-OS palette and a dedicated night variant, alongside the branded wallpaper set."),
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
            "title": qsTr("Choose the release track you want Lumina-OS to emphasize."),
            "body": qsTr("The Update Center now reads metadata from cacheable JSON, and this selection defines the release channel it should foreground."),
            "sideTitle": qsTr("Choose your release preference"),
            "items": []
        },
        {
            "eyebrow": qsTr("Ready"),
            "title": qsTr("Your Lumina-OS session choices are ready to apply."),
            "body": qsTr("Closing Welcome now writes your selections to Lumina-OS config and reapplies the live-session defaults on top of the current Plasma session."),
            "sideTitle": qsTr("What will happen next"),
            "items": [
                qsTr("The selected Plasma layout is applied"),
                qsTr("The selected Lumina-OS color scheme is applied"),
                qsTr("The selected wallpaper becomes active"),
                qsTr("Update Center foregrounds the chosen release channel")
            ]
        }
    ]

    readonly property var languageChoices: [
        {
            "id": "ar",
            "label": qsTr("Arabic"),
            "body": qsTr("RTL-aware Lumina-OS surfaces should prioritize Arabic-first reading comfort.")
        },
        {
            "id": "en",
            "label": qsTr("English"),
            "body": qsTr("Keep English as the preferred language for Lumina-OS-first surfaces and onboarding copy.")
        }
    ]

    readonly property var appearanceChoices: [
        {
            "id": "light",
            "label": qsTr("Light"),
            "body": qsTr("Use the current Lumina-OS palette with soft light surfaces and restrained blue accents."),
            "recommended": true,
            "swatches": ["#F7F3ED", "#2D6C8A", "#C9895B"]
        },
        {
            "id": "dark",
            "label": qsTr("Night"),
            "body": qsTr("Use the new Lumina-OS Night scheme for darker surfaces, brighter text, and calmer nighttime contrast."),
            "swatches": ["#09131A", "#3F8F95", "#C8D3DA"]
        }
    ]

    readonly property var wallpaperChoices: [
        {
            "id": "lagoon",
            "label": qsTr("Lagoon"),
            "body": qsTr("Balanced blue-green depth for the default Lumina-OS direction."),
            "path": "/usr/share/ahmados/wallpapers/ahmados-lagoon.svg",
            "recommended": true,
            "swatches": ["#2D6C8A", "#3F8F95", "#EDF2F4"]
        },
        {
            "id": "horizon",
            "label": qsTr("Horizon"),
            "body": qsTr("Warmer morning tones with a lighter Lumina-OS atmosphere."),
            "path": "/usr/share/ahmados/wallpapers/ahmados-horizon.svg",
            "swatches": ["#C9895B", "#E8C8AE", "#F7F3ED"]
        },
        {
            "id": "nocturne",
            "label": qsTr("Nocturne"),
            "body": qsTr("Darker evening composition tuned for the night palette."),
            "path": "/usr/share/ahmados/wallpapers/ahmados-nocturne.svg",
            "swatches": ["#09131A", "#214455", "#C8D3DA"]
        }
    ]

    readonly property var layoutChoices: [
        {
            "id": "balanced",
            "label": qsTr("Balanced"),
            "body": qsTr("Centered and calm, with room for launcher, running apps, tray, and clock."),
            "recommended": true,
            "panelWidth": 0.68
        },
        {
            "id": "classic",
            "label": qsTr("Classic"),
            "body": qsTr("A wider bottom panel for a more traditional desktop stance."),
            "panelWidth": 0.88
        },
        {
            "id": "minimal",
            "label": qsTr("Minimal"),
            "body": qsTr("A tighter centered panel with less width and a more focused silhouette."),
            "panelWidth": 0.52
        }
    ]

    readonly property var channelChoices: [
        {
            "id": "stable",
            "label": qsTr("Stable"),
            "body": qsTr("Foreground the most normal-user-ready Lumina-OS release path."),
            "recommended": true
        },
        {
            "id": "beta",
            "label": qsTr("Beta"),
            "body": qsTr("Track near-release Lumina-OS builds that still need broader validation.")
        },
        {
            "id": "alpha",
            "label": qsTr("Alpha"),
            "body": qsTr("Follow earlier feature previews with visible rough edges.")
        },
        {
            "id": "dev",
            "label": qsTr("Dev"),
            "body": qsTr("Surface the earliest Lumina-OS work where change is fastest and risk is highest.")
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

    function resolvedColorSchemeLabel() {
        return selectedAppearance === "dark" ? qsTr("Lumina Night") : qsTr("Lumina Day")
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

    function resolvedLookAndFeelLabel() {
        if (selectedLayout === "classic") {
            return qsTr("Classic panel")
        }

        if (selectedLayout === "minimal") {
            return qsTr("Minimal panel")
        }

        return qsTr("Balanced panel")
    }

    function currentNotice() {
        if (currentStep === 1) {
            return qsTr("Language preference is stored now for Lumina-OS-owned surfaces. System-wide locale switching is still a later build step.")
        }

        if (currentStep === 2) {
            return qsTr("Appearance and wallpaper choices are applied to the live session after Welcome closes.")
        }

        if (currentStep === 3) {
            return qsTr("Layout selection maps to real Plasma look-and-feel packages added to the live image.")
        }

        if (currentStep === 4) {
            return qsTr("Update Center will use this channel as the foreground track when showing available release metadata. Stable remains the recommended path for most people.")
        }

        if (currentStep === 5) {
            return qsTr("Finish will save the config and reapply Lumina-OS session defaults immediately.")
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
        anchors.margins: edgeMargin
        spacing: panelSpacing

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            radius: shellRadius
            color: "#D6F7F3ED"
            border.color: lineSoft
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: shellPadding
                spacing: sectionSpacing

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: "Lumina-OS"
                            color: ink
                            font.pixelSize: compact ? 21 : 24
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Live orientation")
                            color: "#5B7180"
                            font.pixelSize: labelSize
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: Math.max(40, Math.round(48 * uiScale))
                        height: Math.max(40, Math.round(48 * uiScale))
                        radius: width / 2
                        color: brand

                        Label {
                            anchors.centerIn: parent
                            text: "A"
                            color: ivory
                            font.pixelSize: compact ? 16 : 18
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

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: pages[currentStep].eyebrow
                        color: brand
                        font.pixelSize: labelSize
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        radius: 12
                        color: "#142D6C8A"
                        border.color: "#222D6C8A"
                        implicitHeight: 28
                        implicitWidth: stepLabel.implicitWidth + 18

                        Label {
                            id: stepLabel
                            anchors.centerIn: parent
                            text: qsTr("Step %1 of %2").arg(root.currentStep + 1).arg(root.pages.length)
                            color: brand
                            font.pixelSize: labelSize
                            font.bold: true
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: pages[currentStep].title
                    color: ink
                    wrapMode: Text.WordWrap
                    font.pixelSize: heroTitleSize
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: pages[currentStep].body
                    color: "#4D6271"
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                    font.pixelSize: heroBodySize
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Math.max(20, Math.round(24 * uiScale))
                    color: "#AAEDF2F4"
                    border.color: "#1409131A"

                    ScrollView {
                        id: contentScroller
                        anchors.fill: parent
                        anchors.margins: Math.max(16, Math.round(24 * uiScale))
                        clip: true
                        padding: 0
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: contentScroller.availableWidth
                            spacing: Math.max(10, Math.round(14 * uiScale))

                            Label {
                                text: pages[currentStep].sideTitle
                                color: ink
                                font.pixelSize: cardTitleSize
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Loader {
                                Layout.fillWidth: true
                                sourceComponent: root.currentContentComponent()
                            }
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
                        text: qsTr("Continue")
                        onClicked: root.currentStep++
                    }

                    Button {
                        visible: root.currentStep === pages.length - 1
                        text: qsTr("Save and Apply")
                        onClicked: root.finishWelcome()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: compact ? 308 : 360
            radius: shellRadius
            color: "#CC10212D"
            border.color: "#22F7F3ED"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: edgeMargin
                spacing: Math.max(12, Math.round(16 * uiScale))

                ScrollView {
                    id: previewScroller
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    padding: 0
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: previewScroller.availableWidth
                        spacing: Math.max(12, Math.round(16 * uiScale))

                        Label {
                            text: qsTr("Session Preview")
                            color: ivory
                            font.pixelSize: headingSize
                            font.bold: true
                        }

                        Label {
                            text: qsTr("These choices are now written to Lumina-OS config so the session can reuse them after Welcome closes.")
                            color: mist
                            wrapMode: Text.WordWrap
                            font.pixelSize: compact ? 13 : 14
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: Math.max(18, Math.round(22 * uiScale))
                            color: "#142D6C8A"
                            border.color: "#222D6C8A"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Math.max(14, Math.round(18 * uiScale))
                                spacing: Math.max(8, Math.round(10 * uiScale))

                                Label {
                                    text: qsTr("Current selection")
                                    color: ivory
                                    font.pixelSize: cardTitleSize
                                    font.bold: true
                                }

                                Label {
                                    text: qsTr("Language") + ": " + root.choiceLabel(root.languageChoices, root.selectedLanguage, qsTr("Arabic"))
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: qsTr("Appearance") + ": " + root.choiceLabel(root.appearanceChoices, root.selectedAppearance, qsTr("Light"))
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: qsTr("Color scheme") + ": " + root.resolvedColorSchemeLabel()
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: qsTr("Layout") + ": " + root.choiceLabel(root.layoutChoices, root.selectedLayout, qsTr("Balanced"))
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: qsTr("Panel style") + ": " + root.resolvedLookAndFeelLabel()
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: qsTr("Wallpaper") + ": " + root.choiceLabel(root.wallpaperChoices, root.selectedWallpaper, qsTr("Lagoon"))
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    text: qsTr("Release channel") + ": " + root.choiceLabel(root.channelChoices, root.selectedChannel, qsTr("Stable"))
                                    color: mist
                                    font.pixelSize: labelSize
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: Math.max(18, Math.round(22 * uiScale))
                            color: "#14C9895B"
                            border.color: "#22C9895B"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Math.max(14, Math.round(18 * uiScale))
                                spacing: Math.max(8, Math.round(10 * uiScale))

                                Label {
                                    text: qsTr("What will apply")
                                    color: ivory
                                    font.pixelSize: cardTitleSize
                                    font.bold: true
                                }

                                Label {
                                    text: root.resolvedColorSchemeLabel() + qsTr(" with ") + root.choiceLabel(root.wallpaperChoices, root.selectedWallpaper, qsTr("Lagoon"))
                                    color: mist
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: labelSize
                                }

                                Label {
                                    text: root.resolvedLookAndFeelLabel() + qsTr(" for the Plasma shell")
                                    color: mist
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: labelSize
                                }

                                Label {
                                    text: qsTr("Update Center will foreground the %1 track").arg(root.choiceLabel(root.channelChoices, root.selectedChannel, qsTr("Stable")))
                                    color: mist
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: labelSize
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: Math.max(18, Math.round(22 * uiScale))
                            color: "#163F8F95"
                            border.color: "#203F8F95"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Math.max(14, Math.round(18 * uiScale))
                                spacing: Math.max(8, Math.round(10 * uiScale))

                                Label {
                                    text: qsTr("Live note")
                                    color: ivory
                                    font.pixelSize: cardTitleSize
                                    font.bold: true
                                }

                                Label {
                                    text: root.currentNotice()
                                    color: mist
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: labelSize
                                }
                            }
                        }
                    }
                }

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
            spacing: root.optionSpacing

            Repeater {
                model: pages[0].items

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 64 : 58, overviewRow.implicitHeight + 28)
                    radius: Math.max(16, Math.round(18 * root.uiScale))
                    color: "#CCFFFFFF"
                    border.color: "#1209131A"

                    RowLayout {
                        id: overviewRow
                        anchors.fill: parent
                        anchors.margins: Math.max(12, Math.round(14 * root.uiScale))
                        spacing: Math.max(10, Math.round(12 * root.uiScale))

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
                            font.pixelSize: root.compact ? 13 : 14
                        }
                    }
                }
            }
        }
    }

    Component {
        id: languageComponent

        ColumnLayout {
            spacing: root.optionSpacing

            Repeater {
                model: root.languageChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 96 : 88, languageChoiceContent.implicitHeight + 32)
                    radius: Math.max(18, Math.round(20 * root.uiScale))
                    color: modelData.id === root.selectedLanguage ? "#142D6C8A" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedLanguage ? "#2D6C8A" : "#1209131A"
                    border.width: modelData.id === root.selectedLanguage ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedLanguage = modelData.id
                    }

                    ColumnLayout {
                        id: languageChoiceContent
                        anchors.fill: parent
                        anchors.margins: Math.max(14, Math.round(16 * root.uiScale))
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.id === root.selectedLanguage ? ivory : ink
                            font.pixelSize: root.choiceTitleSize
                            font.bold: true
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedLanguage ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.labelSize
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appearanceComponent

        ColumnLayout {
            spacing: root.optionSpacing

            Label {
                text: qsTr("Color direction")
                color: ink
                font.pixelSize: root.cardTitleSize
                font.bold: true
            }

            Repeater {
                model: root.appearanceChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 104 : 88, appearanceChoiceContent.implicitHeight + 32)
                    radius: Math.max(18, Math.round(20 * root.uiScale))
                    color: modelData.id === root.selectedAppearance ? "#142D6C8A" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedAppearance ? "#2D6C8A" : "#1209131A"
                    border.width: modelData.id === root.selectedAppearance ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedAppearance = modelData.id
                    }

                    ColumnLayout {
                        id: appearanceChoiceContent
                        anchors.fill: parent
                        anchors.margins: Math.max(14, Math.round(16 * root.uiScale))
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.id === root.selectedAppearance ? ivory : ink
                            font.pixelSize: root.choiceTitleSize
                            font.bold: true
                        }

                        Row {
                            spacing: 6

                            Repeater {
                                model: modelData.swatches

                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: modelData
                                    border.color: "#30FFFFFF"
                                }
                            }

                            Rectangle {
                                visible: !!modelData.recommended
                                radius: 10
                                color: modelData.id === root.selectedAppearance ? "#26F7F3ED" : "#142D6C8A"
                                border.color: modelData.id === root.selectedAppearance ? "#30F7F3ED" : "#202D6C8A"
                                implicitHeight: 20
                                implicitWidth: recommendedAppearanceText.implicitWidth + 14

                                Label {
                                    id: recommendedAppearanceText
                                    anchors.centerIn: parent
                                    text: qsTr("Recommended")
                                    color: modelData.id === root.selectedAppearance ? ivory : brand
                                    font.pixelSize: root.chipTextSize
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedAppearance ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.labelSize
                        }
                    }
                }
            }

            Label {
                text: qsTr("Wallpaper")
                color: ink
                font.pixelSize: root.cardTitleSize
                font.bold: true
                topPadding: 6
            }

            Repeater {
                model: root.wallpaperChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 100 : 84, wallpaperChoiceContent.implicitHeight + 32)
                    radius: Math.max(18, Math.round(20 * root.uiScale))
                    color: modelData.path === root.selectedWallpaper ? "#163F8F95" : "#CCFFFFFF"
                    border.color: modelData.path === root.selectedWallpaper ? "#203F8F95" : "#1209131A"
                    border.width: modelData.path === root.selectedWallpaper ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedWallpaper = modelData.path
                    }

                    ColumnLayout {
                        id: wallpaperChoiceContent
                        anchors.fill: parent
                        anchors.margins: Math.max(14, Math.round(16 * root.uiScale))
                        spacing: 6

                        Label {
                            text: modelData.label
                            color: modelData.path === root.selectedWallpaper ? ivory : ink
                            font.pixelSize: root.choiceTitleSize
                            font.bold: true
                        }

                        Row {
                            spacing: 6

                            Repeater {
                                model: modelData.swatches

                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: modelData
                                    border.color: "#30FFFFFF"
                                }
                            }

                            Rectangle {
                                visible: !!modelData.recommended
                                radius: 10
                                color: modelData.path === root.selectedWallpaper ? "#26F7F3ED" : "#163F8F95"
                                border.color: modelData.path === root.selectedWallpaper ? "#30F7F3ED" : "#203F8F95"
                                implicitHeight: 20
                                implicitWidth: recommendedWallpaperText.implicitWidth + 14

                                Label {
                                    id: recommendedWallpaperText
                                    anchors.centerIn: parent
                                    text: qsTr("Recommended")
                                    color: ivory
                                    font.pixelSize: root.chipTextSize
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            text: modelData.body
                            color: modelData.path === root.selectedWallpaper ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.labelSize
                        }
                    }
                }
            }
        }
    }

    Component {
        id: layoutComponent

        ColumnLayout {
            spacing: root.optionSpacing

            Repeater {
                model: root.layoutChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 108 : 88, layoutChoiceContent.implicitHeight + 32)
                    radius: Math.max(18, Math.round(20 * root.uiScale))
                    color: modelData.id === root.selectedLayout ? "#142D6C8A" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedLayout ? "#2D6C8A" : "#1209131A"
                    border.width: modelData.id === root.selectedLayout ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedLayout = modelData.id
                    }

                    ColumnLayout {
                        id: layoutChoiceContent
                        anchors.fill: parent
                        anchors.margins: Math.max(14, Math.round(16 * root.uiScale))
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: modelData.label
                                color: modelData.id === root.selectedLayout ? ivory : ink
                                font.pixelSize: root.choiceTitleSize
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                visible: !!modelData.recommended
                                radius: 10
                                color: modelData.id === root.selectedLayout ? "#26F7F3ED" : "#142D6C8A"
                                border.color: modelData.id === root.selectedLayout ? "#30F7F3ED" : "#202D6C8A"
                                implicitHeight: 20
                                implicitWidth: recommendedLayoutText.implicitWidth + 14

                                Label {
                                    id: recommendedLayoutText
                                    anchors.centerIn: parent
                                    text: qsTr("Recommended")
                                    color: modelData.id === root.selectedLayout ? ivory : brand
                                    font.pixelSize: root.chipTextSize
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedLayout ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.labelSize
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 13
                            color: modelData.id === root.selectedLayout ? "#1DF7F3ED" : "#1409131A"

                            Rectangle {
                                width: parent.width * modelData.panelWidth
                                height: 10
                                radius: 5
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                color: modelData.id === root.selectedLayout ? ivory : brand
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: channelComponent

        ColumnLayout {
            spacing: root.optionSpacing

            Repeater {
                model: root.channelChoices

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 100 : 84, channelChoiceContent.implicitHeight + 32)
                    radius: Math.max(18, Math.round(20 * root.uiScale))
                    color: modelData.id === root.selectedChannel ? "#163F8F95" : "#CCFFFFFF"
                    border.color: modelData.id === root.selectedChannel ? "#203F8F95" : "#1209131A"
                    border.width: modelData.id === root.selectedChannel ? 2 : 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedChannel = modelData.id
                    }

                    ColumnLayout {
                        id: channelChoiceContent
                        anchors.fill: parent
                        anchors.margins: Math.max(14, Math.round(16 * root.uiScale))
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: modelData.label
                                color: modelData.id === root.selectedChannel ? ivory : ink
                                font.pixelSize: root.choiceTitleSize
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                visible: !!modelData.recommended
                                radius: 10
                                color: modelData.id === root.selectedChannel ? "#26F7F3ED" : "#163F8F95"
                                border.color: modelData.id === root.selectedChannel ? "#30F7F3ED" : "#203F8F95"
                                implicitHeight: 20
                                implicitWidth: recommendedChannelText.implicitWidth + 14

                                Label {
                                    id: recommendedChannelText
                                    anchors.centerIn: parent
                                    text: qsTr("Recommended")
                                    color: ivory
                                    font.pixelSize: root.chipTextSize
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            text: modelData.body
                            color: modelData.id === root.selectedChannel ? mist : "#546A79"
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.labelSize
                        }
                    }
                }
            }
        }
    }

    Component {
        id: readyComponent

        ColumnLayout {
            spacing: root.optionSpacing

            Repeater {
                model: pages[5].items

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(root.compact ? 64 : 58, readyRow.implicitHeight + 28)
                    radius: Math.max(16, Math.round(18 * root.uiScale))
                    color: "#CCFFFFFF"
                    border.color: "#1209131A"

                    RowLayout {
                        id: readyRow
                        anchors.fill: parent
                        anchors.margins: Math.max(12, Math.round(14 * root.uiScale))
                        spacing: Math.max(10, Math.round(12 * root.uiScale))

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
                            font.pixelSize: root.compact ? 13 : 14
                        }
                    }
                }
            }
        }
    }
}
