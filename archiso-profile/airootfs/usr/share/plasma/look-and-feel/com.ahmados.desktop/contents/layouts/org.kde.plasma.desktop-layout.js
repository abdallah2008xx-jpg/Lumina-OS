var panel = new Panel
var panelScreen = panel.screen

panel.location = "floating"
panel.lengthMode = "custom"
panel.height = 2 * Math.ceil(gridUnit * 3.0 / 2)

if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panelScreen)
    const targetWidth = Math.min(geo.width - (gridUnit * 9), Math.max(gridUnit * 38, Math.ceil(geo.height * 1.72)))

    panel.alignment = "center"
    panel.offset = 0
    panel.minimumLength = targetWidth
    panel.maximumLength = targetWidth
}

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.systemtray")
