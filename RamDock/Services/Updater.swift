import Sparkle

/// Sparkle auto-updates. Started only when the bundle carries a feed URL, so a
/// `swift run` build never checks a feed it can't use.
enum Updater {
    private static let controller: SPUStandardUpdaterController? =
        Bundle.main.infoDictionary?["SUFeedURL"] != nil
            ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            : nil

    static func start() { _ = controller }

    static var isAvailable: Bool { controller != nil }

    static func checkForUpdates() { controller?.updater.checkForUpdates() }
}
