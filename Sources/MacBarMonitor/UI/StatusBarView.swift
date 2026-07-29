import AppKit

/// Custom NSView placed in the menu bar showing stacked label/value columns.
///
/// **CRITICAL**: Column views are created once in `makeColumn()` and reused
/// forever. Only `.stringValue` of existing NSTextFields is updated on each
/// refresh cycle. This avoids the view-hierarchy churn that caused crashes.
@MainActor
final class StatusBarView: NSView {
    // MARK: - Layout constants

    private enum Layout {
        static let iconSize: CGFloat = 14
        static let iconSpacing: CGFloat = 4
        static let columnSpacing: CGFloat = 3
        static let horizontalPadding: CGFloat = 4
        static let height: CGFloat = 22
        static let labelFont = NSFont.systemFont(ofSize: 8, weight: .medium)
        static let valueFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    }

    // MARK: - Subviews

    private let stackView: NSStackView = {
        let sv = NSStackView()
        sv.orientation = .horizontal
        sv.alignment = .centerY
        sv.spacing = Layout.columnSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let iconView: NSImageView = {
        let iv = NSImageView()
        iv.image = NSImage(systemSymbolName: "gauge.medium", accessibilityDescription: nil)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Callback

    var onTogglePopover: (() -> Void)?

    // MARK: - Tracking

    private var trackingArea: NSTrackingArea?

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(stackView)
        stackView.addArrangedSubview(iconView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: Layout.height),

            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
        ])
    }

    // MARK: - Tracking area

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        window?.contentView?.wantsLayer = true
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    override func mouseDown(with event: NSEvent) {
        onTogglePopover?()
    }

    // MARK: - Update (THE KEY FIX)

    /// Reuse existing column views; only update `.stringValue` of text fields.
    /// Only add/remove views when the metric count changes.
    func update(with metrics: [(label: String, value: String)]) {
        let targetCount = metrics.count
        let currentCount = stackView.arrangedSubviews.count - 1 // subtract icon

        if targetCount > currentCount {
            // Add missing columns
            for i in currentCount..<targetCount {
                let column = makeColumn(label: metrics[i].label, value: metrics[i].value)
                stackView.addArrangedSubview(column)
            }
        } else if targetCount < currentCount {
            // Remove excess columns (from the end)
            let toRemove = currentCount - targetCount
            for _ in 0..<toRemove {
                if let last = stackView.arrangedSubviews.last, last !== iconView {
                    stackView.removeArrangedSubview(last)
                    last.removeFromSuperview()
                }
            }
        }

        // Update text of ALL existing columns (skip icon at index 0)
        for (index, metric) in metrics.enumerated() {
            let subviewIndex = index + 1 // +1 to skip icon
            guard subviewIndex < stackView.arrangedSubviews.count else { break }
            guard let columnStack = stackView.arrangedSubviews[subviewIndex] as? NSStackView else { continue }
            guard columnStack.arrangedSubviews.count >= 2 else { continue }

            if let labelField = columnStack.arrangedSubviews[0] as? NSTextField {
                if labelField.stringValue != metric.label {
                    labelField.stringValue = metric.label
                }
            }
            if let valueField = columnStack.arrangedSubviews[1] as? NSTextField {
                if valueField.stringValue != metric.value {
                    valueField.stringValue = metric.value
                }
            }
        }
    }

    // MARK: - Column factory

    private func makeColumn(label: String, value: String) -> NSView {
        let col = NSStackView()
        col.orientation = .vertical
        col.alignment = .centerX
        col.spacing = 0

        let labelField = NSTextField(labelWithString: label)
        labelField.font = Layout.labelFont
        labelField.textColor = .white
        labelField.alignment = .center
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.refusesFirstResponder = true
        // Ensure the field has a zero-width intrinsic content size so the column
        // widths are driven by Auto Layout rather than intrinsic sizes.
        labelField.setContentHuggingPriority(.required, for: .vertical)
        labelField.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueField = NSTextField(labelWithString: value)
        valueField.font = Layout.valueFont
        valueField.textColor = .labelColor
        valueField.alignment = .center
        valueField.translatesAutoresizingMaskIntoConstraints = false
        valueField.refusesFirstResponder = true
        valueField.setContentHuggingPriority(.required, for: .vertical)
        valueField.setContentCompressionResistancePriority(.required, for: .horizontal)

        col.addArrangedSubview(labelField)
        col.addArrangedSubview(valueField)

        return col
    }
}
