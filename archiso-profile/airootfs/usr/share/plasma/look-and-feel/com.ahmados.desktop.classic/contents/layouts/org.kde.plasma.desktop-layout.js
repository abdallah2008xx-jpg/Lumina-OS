var panel = new Panel

panel.location = "floating"
panel.lengthMode = "custom"
panel.height = 2 * Math.ceil(gridUnit * 3.0 / 2)

if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panel.screen)
    const targetWidth = Math.min(geo.width - (gridUnit * 6), Math.max(gridUnit * 50, Math.ceil(geo.height * 1.95)))

    panel.alignment = "center"
    panel.offset = 0
    panel.minimumLength = targetWidth
    panel.maximumLength = targetWidth
}

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.marginsseparator")
var tasks = panel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["General"]
tasks.writeConfig("launchers", "preferred://filemanager,preferred://browser")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.systemtray")
