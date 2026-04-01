import QtCore
import QtQml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1320
    height: 860
    visible: true
    title: qsTr("Lumina-OS Update Center")
    color: "#09131A"

    property var releases: []
    property string metadataStateKind: "loading"
    property string metadataState: qsTr("Loading release metadata...")
    property string metadataBody: qsTr("Lumina-OS is reading the local cache so release browsing still works even before deeper package actions exist.")
    property string metadataSource: qsTr("Bundled")
    property string requestedMetadataSource: qsTr("GitHub Releases")
    property string checkedAt: qsTr("Unknown")
    property string installedVersion: "0.1.0-dev"
    property string fallbackReason: ""
    property string releaseApiUrl: ""
    property int releaseCount: 0
    property string releaseCacheUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/ahmados/update-center/releases.json"
    property string statusCacheUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/ahmados/update-center/status.json"

    readonly property color ink: "#09131A"
    readonly property color mist: "#C8D3DA"
    readonly property color cloud: "#EDF2F4"
    readonly property color ivory: "#F7F3ED"
    readonly property color brand: "#2D6C8A"
    readonly property color lagoon: "#3F8F95"
    readonly property color copper: "#C9895B"
    readonly property color danger: "#BC6454"

    readonly property var channels: [
        { "id": "stable", "name": qsTr("Stable"), "text": qsTr("Recommended for normal users and the default Lumina-OS channel."), "recommended": true },
        { "id": "beta", "name": qsTr("Beta"), "text": qsTr("Near-release builds with lower risk and broader validation.") },
        { "id": "alpha", "name": qsTr("Alpha"), "text": qsTr("Feature previews for early testing with visible rough edges.") },
        { "id": "dev", "name": qsTr("Dev"), "text": qsTr("Earliest internal work and the highest expected instability.") }
    ]

    Settings {
        id: welcomeSettings
        location: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/ahmados/welcome.conf"
        property string channel: "stable"
    }

    function channelLabel(channelId) {
        for (var index = 0; index < channels.length; index++) {
            if (channels[index].id === channelId) {
                return channels[index].name
            }
        }

        return qsTr("Stable")
    }

    function setMetadataState(kind, headline, body) {
        metadataStateKind = kind
        metadataState = headline
        metadataBody = body
    }

    function metadataBadgeText() {
        if (metadataStateKind === "ready") {
            return qsTr("Ready")
        }

        if (metadataStateKind === "empty") {
            return qsTr("Empty")
        }

        if (metadataStateKind === "error") {
            return qsTr("Attention")
        }

        return qsTr("Loading")
    }

    function metadataFill() {
        if (metadataStateKind === "ready") {
            return "#142D6C8A"
        }

        if (metadataStateKind === "empty") {
            return "#143F8F95"
        }

        if (metadataStateKind === "error") {
            return "#14BC6454"
        }

        return "#19F7F3ED"
    }

    function metadataBorder() {
        if (metadataStateKind === "ready") {
            return "#222D6C8A"
        }

        if (metadataStateKind === "empty") {
            return "#203F8F95"
        }

        if (metadataStateKind === "error") {
            return "#22BC6454"
        }

        return "#16F7F3ED"
    }

    function releaseChannelHint(release) {
        var detectedChannel = detectChannel(release)

        if (detectedChannel === welcomeSettings.channel) {
            return qsTr("Matches the channel saved in Welcome.")
        }

        if (detectedChannel === "stable") {
            return qsTr("Best starting point for most users.")
        }

        return qsTr("Available for preview and validation.")
    }

    function detectChannel(release) {
        var tag = ((release.tag_name || "") + " " + (release.name || "")).toLowerCase()

        if (tag.indexOf("dev") !== -1) {
            return "dev"
        }

        if (tag.indexOf("alpha") !== -1) {
            return "alpha"
        }

        if (tag.indexOf("beta") !== -1) {
            return "beta"
        }

        if (tag.indexOf("preview") !== -1 || release.prerelease) {
            return "beta"
        }

        return "stable"
    }

    function firstLine(text, fallbackText) {
        if (!text || text.length === 0) {
            return fallbackText
        }

        var lines = text.split("\n")

        for (var index = 0; index < lines.length; index++) {
            var candidate = lines[index].trim()

            if (candidate.length > 0) {
                return candidate
            }
        }

        return fallbackText
    }

    function releaseVersion(release) {
        return release.name || release.tag_name || qsTr("Unlabeled release")
    }

    function releaseStatus(release, index) {
        var version = releaseVersion(release)

        if (version === installedVersion || release.tag_name === installedVersion || release.tag_name === "v" + installedVersion) {
            return qsTr("Current release")
        }

        if (index === 0) {
            return qsTr("Latest published")
        }

        return qsTr("Available to review")
    }

    function restartText(release, index) {
        if (releaseStatus(release, index) === qsTr("Current release")) {
            return qsTr("Already installed")
        }

        return qsTr("Restart likely required")
    }

    function publishedText(release) {
        if (!release.published_at || release.published_at.length < 10) {
            return qsTr("Publish date unavailable")
        }

        return qsTr("Published") + ": " + release.published_at.slice(0, 10)
    }

    function sourceLabel(sourceId) {
        if (sourceId === "github") {
            return qsTr("GitHub Releases")
        }

        if (sourceId === "bundled") {
            return qsTr("Bundled metadata")
        }

        return qsTr("Bundled metadata")
    }

    function fallbackReasonLabel(reasonId) {
        if (reasonId === "github-returned-no-releases") {
            return qsTr("GitHub is configured, but no releases have been published yet. Bundled metadata is being shown for now.")
        }

        if (reasonId === "github-request-failed") {
            return qsTr("GitHub release metadata could not be reached, so the local bundled fallback is being used.")
        }

        if (reasonId === "github-config-incomplete") {
            return qsTr("GitHub mode is selected, but the owner or repository value is incomplete.")
        }

        if (reasonId === "curl-unavailable") {
            return qsTr("GitHub mode is selected, but curl is unavailable in this session.")
        }

        return ""
    }

    function loadJson(url, onSuccess, onFailure) {
        var request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) {
                return
            }

            if (request.status === 0 || request.status === 200) {
                try {
                    onSuccess(JSON.parse(request.responseText))
                } catch (error) {
                    onFailure(error.toString())
                }
            } else {
                onFailure(request.statusText)
            }
        }

        request.open("GET", url)
        request.send()
    }

    function normalizePayload(payload) {
        var source = payload

        if (!source) {
            return []
        }

        if (!(source instanceof Array) && source.releases && source.releases instanceof Array) {
            source = source.releases
        }

        if (!(source instanceof Array)) {
            return []
        }

        return source
    }

    function reloadMetadata() {
        setMetadataState(
            "loading",
            qsTr("Loading release metadata..."),
            qsTr("Lumina-OS is refreshing the local release cache and the last-known status snapshot.")
        )

        loadJson(statusCacheUrl, function(payload) {
            checkedAt = payload.checkedAt ? payload.checkedAt.slice(0, 19).replace("T", " ") : qsTr("Unknown")
            metadataSource = sourceLabel(payload.source || "bundled")
            requestedMetadataSource = sourceLabel(payload.requestedSource || "github")
            installedVersion = payload.installedVersion || installedVersion
            fallbackReason = payload.fallbackReason || ""
            releaseApiUrl = payload.releaseUrl || ""
            releaseCount = payload.releaseCount || 0
        }, function() {
            checkedAt = qsTr("Unknown")
            metadataSource = qsTr("Bundled metadata")
            requestedMetadataSource = qsTr("GitHub Releases")
            fallbackReason = ""
            releaseApiUrl = ""
            releaseCount = 0
        })

        loadJson(releaseCacheUrl, function(payload) {
            releases = normalizePayload(payload)
            if (releases.length > 0) {
                setMetadataState(
                    "ready",
                    qsTr("Release metadata loaded successfully."),
                    qsTr("The local cache is ready to describe available Lumina-OS builds without reopening the app.")
                )
            } else {
                setMetadataState(
                    "empty",
                    qsTr("No releases were found in the current metadata cache."),
                    qsTr("The app opened successfully, but there are no release cards to show yet from the current source.")
                )
            }
        }, function(errorText) {
            releases = []
            setMetadataState(
                "error",
                qsTr("Unable to load the local release cache."),
                qsTr("Update Center could not parse the cached release data.") + " " + errorText
            )
        })
    }

    Component.onCompleted: reloadMetadata()

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#09131A" }
            GradientStop { position: 0.52; color: "#10212D" }
            GradientStop { position: 1.0; color: "#214455" }
        }
    }

    Rectangle {
        width: 420
        height: 420
        radius: 210
        x: root.width - 280
        y: -120
        color: "#123F8F95"
    }

    Rectangle {
        width: 520
        height: 520
        radius: 260
        x: -180
        y: root.height - 310
        color: "#142D6C8A"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 128
            radius: 30
            color: "#D6F7F3ED"
            border.color: "#1AF7F3ED"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                ColumnLayout {
                    spacing: 6

                    Label {
                        text: qsTr("Lumina-OS Update Center")
                        color: ink
                        font.pixelSize: 30
                        font.bold: true
                    }

                    Label {
                        text: qsTr("A release-aware system surface that now reads JSON metadata instead of keeping release cards hardcoded in QML.")
                        color: "#546A79"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 20
                        color: root.metadataFill()
                        border.color: root.metadataBorder()

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    radius: 10
                                    color: "#26F7F3ED"
                                    border.color: "#30F7F3ED"
                                    implicitHeight: 20
                                    implicitWidth: metadataBadgeTextLabel.implicitWidth + 14

                                    Label {
                                        id: metadataBadgeTextLabel
                                        anchors.centerIn: parent
                                        text: root.metadataBadgeText()
                                        color: ivory
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: checkedAt === qsTr("Unknown") ? qsTr("Waiting for cache timestamp") : checkedAt
                                    color: mist
                                    font.pixelSize: 12
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: metadataState
                                color: ivory
                                font.pixelSize: 15
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                Layout.fillWidth: true
                                text: metadataBody
                                color: mist
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    radius: 18
                    color: "#172D6C8A"
                    border.color: "#242D6C8A"
                    implicitWidth: 220
                    implicitHeight: 72

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: qsTr("Foreground channel")
                            color: ivory
                            font.pixelSize: 12
                        }

                        Label {
                            text: channelLabel(welcomeSettings.channel)
                            color: cloud
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Label {
                            text: metadataSource
                            color: mist
                            font.pixelSize: 11
                        }
                    }
                }

                Button {
                    text: qsTr("Reload metadata")
                    onClicked: root.reloadMetadata()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 2.3
                radius: 30
                color: "#D6F7F3ED"
                border.color: "#1AF7F3ED"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 18

                    Label {
                        text: qsTr("Available Releases")
                        color: ink
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Repeater {
                        model: root.releases

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 154
                            radius: 24
                            color: index === 0 ? "#1A2D6C8A" : "#CCFFFFFF"
                            border.color: index === 0 ? "#262D6C8A" : "#1209131A"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        text: root.releaseVersion(modelData)
                                        color: index === 0 ? ivory : ink
                                        font.pixelSize: 22
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        radius: 14
                                        color: index === 0 ? "#163F8F95" : "#142D6C8A"
                                        border.color: index === 0 ? "#1F3F8F95" : "#1C2D6C8A"
                                        implicitHeight: 28
                                        implicitWidth: channelLabelText.implicitWidth + 20

                                        Label {
                                            id: channelLabelText
                                            anchors.centerIn: parent
                                            text: root.channelLabel(root.detectChannel(modelData))
                                            color: ivory
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.firstLine(modelData.body, qsTr("No release summary was provided."))
                                    color: index === 0 ? mist : "#546A79"
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 14
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.releaseChannelHint(modelData)
                                    color: index === 0 ? cloud : brand
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        text: root.restartText(modelData, index)
                                        color: index === 0 ? copper : brand
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Label {
                                        text: root.releaseStatus(modelData, index)
                                        color: index === 0 ? cloud : "#546A79"
                                        font.pixelSize: 13
                                    }
                                }

                                Label {
                                    text: root.publishedText(modelData)
                                    color: index === 0 ? mist : "#546A79"
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.releases.length === 0
                        Layout.fillWidth: true
                        implicitHeight: 164
                        radius: 24
                        color: "#CCFFFFFF"
                        border.color: "#1209131A"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            Label {
                                text: qsTr("No release cards are ready yet")
                                color: ink
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Label {
                                Layout.fillWidth: true
                                text: metadataBody
                                color: "#546A79"
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Check the cached JSON source, then reload metadata or regenerate the release cache from the launcher script.")
                                color: brand
                                wrapMode: Text.WordWrap
                                font.pixelSize: 13
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 132
                        radius: 24
                        color: "#CCFFFFFF"
                        border.color: "#1209131A"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            Label {
                                text: qsTr("Release Cache Summary")
                                color: ink
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Label {
                                text: qsTr("Checked") + ": " + checkedAt
                                color: "#546A79"
                                font.pixelSize: 14
                            }

                            Label {
                                text: qsTr("Installed baseline") + ": " + installedVersion
                                color: "#546A79"
                                font.pixelSize: 14
                            }

                            Label {
                                text: qsTr("Source") + ": " + metadataSource
                                color: "#546A79"
                                font.pixelSize: 14
                            }

                            Label {
                                text: qsTr("Requested source") + ": " + requestedMetadataSource
                                color: "#546A79"
                                font.pixelSize: 14
                            }

                            Label {
                                text: qsTr("Visible release count") + ": " + releaseCount
                                color: "#546A79"
                                font.pixelSize: 14
                            }

                            Label {
                                visible: fallbackReason.length > 0
                                text: root.fallbackReasonLabel(fallbackReason)
                                color: copper
                                wrapMode: Text.WordWrap
                                font.pixelSize: 13
                            }

                            Label {
                                visible: releaseApiUrl.length > 0
                                text: qsTr("Release API") + ": " + releaseApiUrl
                                color: "#546A79"
                                wrapMode: Text.WrapAnywhere
                                font.pixelSize: 12
                            }

                            Label {
                                text: qsTr("This surface is ready for a later pass that adds package actions, restart flows, and history.")
                                color: brand
                                wrapMode: Text.WordWrap
                                font.pixelSize: 13
                            }
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
                        text: qsTr("Channels")
                        color: ivory
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Repeater {
                        model: channels

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 88
                            radius: 22
                            color: modelData.id === welcomeSettings.channel ? "#163F8F95" : "#19F7F3ED"
                            border.color: modelData.id === welcomeSettings.channel ? "#203F8F95" : "#16F7F3ED"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 6

                                Label {
                                    text: modelData.name
                                    color: ivory
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Rectangle {
                                    visible: modelData.id === welcomeSettings.channel || !!modelData.recommended
                                    radius: 10
                                    color: modelData.id === welcomeSettings.channel ? "#26F7F3ED" : "#142D6C8A"
                                    border.color: modelData.id === welcomeSettings.channel ? "#30F7F3ED" : "#202D6C8A"
                                    implicitHeight: 20
                                    implicitWidth: channelBadgeLabel.implicitWidth + 14

                                    Label {
                                        id: channelBadgeLabel
                                        anchors.centerIn: parent
                                        text: modelData.id === welcomeSettings.channel ? qsTr("Foreground") : qsTr("Recommended")
                                        color: ivory
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Label {
                                    text: modelData.text
                                    color: mist
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 22
                        color: "#14BC6454"
                        border.color: "#22BC6454"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            Label {
                                text: qsTr("Recovery Notice")
                                color: ivory
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Label {
                                text: qsTr("Rollback is not automated yet. Until that exists, the system should explain that risk clearly instead of hiding it.")
                                color: mist
                                wrapMode: Text.WordWrap
                                font.pixelSize: 13
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Close Update Center")
                        onClicked: root.close()
                    }
                }
            }
        }
    }
}
