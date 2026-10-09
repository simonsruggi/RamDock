import AppKit

/// Live replica of the status item, so changes are visible without looking up.
final class BarPreviewView: NSView {
    private let readings: BarReadings
    private let label = NSTextField(labelWithString: "")

    init(readings: BarReadings) {
        self.readings = readings
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let capsule = RoundedBackgroundView(radius: .greatestFiniteMagnitude, fill: .quaternaryLabelColor)
        addSubview(capsule)
        capsule.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 42),
            capsule.heightAnchor.constraint(equalToConstant: 30),
            capsule.centerXAnchor.constraint(equalTo: centerXAnchor),
            capsule.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
        ])
        update()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func update() {
        label.attributedStringValue = BarTitle.make(ram: readings.ram, cpu: readings.cpu)
    }
}
