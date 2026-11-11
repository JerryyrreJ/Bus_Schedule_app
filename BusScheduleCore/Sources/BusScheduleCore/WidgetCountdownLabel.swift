import SwiftUI

/// Keep the countdown legible; remove its redundant caption before shrinking it.
/// fixedSize lets ViewThatFits measure the untruncated candidate, not an ellipsis.
public struct WidgetCountdownLabel: View {
    let seconds: Int
    let caption: String
    let fontSize: CGFloat
    let color: Color

    public init(seconds: Int, caption: String, fontSize: CGFloat, color: Color = .primary) {
        self.seconds = seconds
        self.caption = caption
        self.fontSize = fontSize
        self.color = color
    }

    public var body: some View {
        let shortCaption = BusScheduleStrings.inPrefix
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(caption)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                countdown
            }
            .fixedSize(horizontal: true, vertical: false)

            if caption != shortCaption {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(shortCaption)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    countdown
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            countdown
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) \(CountdownFormatter.string(forSeconds: seconds))")
    }

    private var countdown: some View {
        Text(CountdownFormatter.widgetString(forSeconds: seconds))
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
