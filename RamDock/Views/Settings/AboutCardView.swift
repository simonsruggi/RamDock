import AppKit

/// Version, "Check for Updates" and "Open at login".
final class AboutCardView: NSView {
    private let loginSwitch = NSSwitch()
    private let errorLabel = makeLabel("", size: 11, color: .systemRed)

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let info = Bundle.main.infoDictionary
        let version = "\(info?["CFBundleShortVersionString"] as? String ?? "–") (\(info?["CFBundleVersion"] as? String ?? "–"))"
        let versionLabel = makeLabel(version, size: 12, color: .secondaryLabelColor, monospacedDigits: true)
        versionLabel.isSelectable = true

        let updateButton = NSButton(title: "Check for Updates…", target: self, action: #selector(checkForUpdates))
        updateButton.controlSize = .small
        updateButton.isEnabled = Updater.isAvailable

        loginSwitch.controlSize = .mini
        loginSwitch.state = LaunchAtLogin.isEnabled ? .on : .off
        loginSwitch.target = self
        loginSwitch.action = #selector(toggleLogin)

        errorLabel.isHidden = true
        let rows: [NSView] = [
            settingRow("Version", [versionLabel, spacer(), updateButton], expands: true),
            settingRow("Startup", [makeLabel("Open at login", size: 12), spacer(), loginSwitch], expands: true),
            errorLabel,
        ]
        let card = SettingsCardView(title: "RamDock", rows: rows)
        addSubview(card)
        pinEdges(card, to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    @objc private func checkForUpdates() { Updater.checkForUpdates() }

    @objc private func toggleLogin() {
        let error = LaunchAtLogin.set(loginSwitch.state == .on)
        loginSwitch.state = LaunchAtLogin.isEnabled ? .on : .off
        errorLabel.stringValue = error ?? ""
        errorLabel.isHidden = error == nil
    }
}
