var panel = new Panel
var panelScreen = panel.screen

panel.height = 2 * Math.ceil(gridUnit * 2.25 / 2)

if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panelScreen)
    const targetWidth = Math.min(geo.width - (gridUnit * 18), Math.ceil(geo.height * 1.15))

    panel.alignment = "center"
    panel.minimumLength = targetWidth
    panel.maximumLength = targetWidth
}

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
