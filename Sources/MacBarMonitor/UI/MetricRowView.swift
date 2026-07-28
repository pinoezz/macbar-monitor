import SwiftUI

struct MetricRowView: View {
    let icon: String
    let label: String
    let value: String
    let progress: Double?
    let color: Color
    var badge: String? = nil
    var badgeColor: Color? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Icon - fixed width column
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 16, alignment: .center)

            // Label - fixed width column
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 70, alignment: .leading)

            // Badge / Progress bar - fixed width column
            if let badge = badge, let badgeColor = badgeColor {
                Text(badge)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(badgeColor)
                    )
                    .frame(width: 80, alignment: .center)
            } else if let progress = progress {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(color.gradient)
                            .frame(width: max(0, geometry.size.width * min(progress, 1.0)), height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(width: 80, height: 6)
            } else {
                // Empty placeholder to maintain alignment (e.g. Upload/Download)
                Spacer()
                    .frame(width: 80)
            }

            // Value text - fixed width column, right aligned
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .trailing)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.00001)) // hit target
        )
    }
}
