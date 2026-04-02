var panel = new Panel
var panelScreen = panel.screen

panel.location = "floating"
panel.lengthMode = "custom"
panel.height = 2 * Math.ceil(gridUnit * 2.85 / 2)

if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panelScreen)
    const targetWidth = Math.min(geo.width - (gridUnit * 18), Math.max(gridUnit * 30, Math.ceil(geo.height * 1.22)))

    panel.alignment = "center"
    panel.offset = 0
    panel.minimumLength = targetWidth
    panel.maximumLength = targetWidth
}

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.systemtray")
