import SwiftUI

struct SpecTile: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 13, weight: .semibold)).monospacedDigit()
                if let detail {
                    Text(detail).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.6)))
    }
}
