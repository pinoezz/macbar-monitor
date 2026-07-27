import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "gauge.medium",
            title: "Welcome to MacBar Monitor",
            body: "A lightweight system monitor that lives in your menu bar. Click the gauge icon to see your Mac's vitals at a glance."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Metric Groups",
            body: "Track CPU, memory, swap, thermal state, battery, network activity, and disk usage — all updated in real time."
        ),
        OnboardingPage(
            icon: "menubar.arrow.up.rectangle",
            title: "Menu Bar Display",
            body: "Choose any metric to display permanently in your menu bar. Open Settings to pick your preferred metric and refresh rate."
        ),
        OnboardingPage(
            icon: "gear",
            title: "Settings & Limitations",
            body: "Configure display preferences from the popover. Note: numeric CPU temperature is unavailable through public macOS APIs — only the thermal state is accessible."
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: pages[currentPage].icon)
                .font(.system(size: 48))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            Text(pages[currentPage].title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(pages[currentPage].body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            PageIndicator(current: currentPage, total: pages.count)

            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .accessibilityLabel("Go to previous page")
                } else {
                    Spacer()
                }

                Spacer()

                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .accessibilityLabel("Go to next page")
                } else {
                    Button("Get Started") {
                        onComplete()
                    }
                    .accessibilityLabel("Complete onboarding and start using MacBar Monitor")
                }
            }
        }
        .padding(32)
        .frame(width: 420, height: 360)
        .onAppear {
            currentPage = 0
        }
    }
}

struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(total)")
    }
}
