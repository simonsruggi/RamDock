/// Latest system-wide values, shared by the status item and the settings preview.
final class BarReadings {
    var ram = 0.0
    var cpu = 0.0
    var onChange: (() -> Void)?
}
