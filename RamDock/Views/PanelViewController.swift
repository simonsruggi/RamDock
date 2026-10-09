import AppKit

/// Swaps between the process list and Settings inside the dropdown panel.
final class PanelViewController: NSViewController {
    private let sampler: ProcessSampler
    private let readings: BarReadings

    init(sampler: ProcessSampler, readings: BarReadings) {
        self.sampler = sampler
        self.readings = readings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 520))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showList()
    }

    private func showList() {
        show(ProcessListViewController(sampler: sampler) { [weak self] in self?.showSettings() })
    }

    private func showSettings() {
        show(SettingsViewController(readings: readings) { [weak self] in self?.showList() })
    }

    private func show(_ child: NSViewController) {
        for old in children {
            old.view.removeFromSuperview()
            old.removeFromParent()
        }
        addChild(child)
        view.addSubview(child.view)
        pinEdges(child.view, to: view)
    }
}
