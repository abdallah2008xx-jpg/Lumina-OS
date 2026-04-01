var panel = new Panel

panel.location = "bottom"
panel.height = 2 * Math.ceil(gridUnit * 2.5 / 2)

if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panel.screen)

    panel.alignment = "left"
    panel.minimumLength = geo.width - (gridUnit * 2)
    panel.maximumLength = geo.width - (gridUnit * 2)
}

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
