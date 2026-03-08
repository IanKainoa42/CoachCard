import SwiftUI

struct ScoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scoreIndex: Int = 100 // 10.0
    @State private var theme: CardTheme = .dark
    @State private var previousBrightness: CGFloat = 0.5
    @State private var controlsVisible: Bool = true
    @State private var hideTimer: Timer?

    private var scoreValue: Double {
        Double(scoreIndex) / 10.0
    }

    private var scoreText: String {
        String(format: "%.1f", scoreValue)
    }

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            // Score number
            Text(scoreText)
                .font(.system(size: 300, weight: .bold))
                .foregroundColor(theme.textColor)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .padding(.horizontal, 40)
                .modifier(GlowModifier(enabled: true, color: theme.textColor))

            // Controls overlay
            VStack {
                HStack {
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(theme.textColor)
                    }
                    .opacity(controlsVisible ? 0.5 : 0.15)

                    Spacer()

                    // Theme picker
                    Picker("Theme", selection: $theme) {
                        ForEach(CardTheme.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .opacity(controlsVisible ? 0.7 : 0.15)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Score picker
                Picker("Score", selection: $scoreIndex) {
                    ForEach(0...100, id: \.self) { i in
                        Text(String(format: "%.1f", Double(i) / 10.0))
                            .tag(i)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 80)
                .padding(.horizontal, 40)
                .opacity(controlsVisible ? 0.6 : 0.15)
            }
        }
        .statusBarHidden(true)
        .contentShape(Rectangle())
        .onTapGesture {
            showControls()
        }
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            scheduleHide()
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
            hideTimer?.invalidate()
        }
        .onChange(of: scoreIndex) {
            showControls()
        }
        .animation(.easeInOut(duration: 0.3), value: controlsVisible)
    }

    private func showControls() {
        controlsVisible = true
        scheduleHide()
    }

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            controlsVisible = false
        }
    }
}
