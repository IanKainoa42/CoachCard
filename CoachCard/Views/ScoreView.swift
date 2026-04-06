import SwiftUI

struct ScoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scoreIndex: Int = 100 // 10.0
    @State private var theme: CardTheme = .dark
    @State private var previousBrightness: CGFloat = 0.5
    @State private var controlsVisible: Bool = true
    @State private var dragOffsetAccumulator: CGFloat = 0
    @State private var isScrubbing = false
    @State private var hideControlsTask: Task<Void, Never>?

    private let pointsPerStep: CGFloat = 22
    private let fastThreshold: CGFloat = 80

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

            // Score number — fills the screen
            Text(scoreText)
                .font(.system(size: 500, weight: .bold))
                .foregroundColor(theme.textColor)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
                .modifier(GlowModifier(enabled: true, color: theme.textColor))

            // Controls overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(theme.textColor)
                    }
                    .opacity(controlsVisible ? 0.5 : 0.15)

                    Spacer()

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
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .contentShape(Rectangle())
        .gesture(scoreScrubGesture)
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
            cancelHideTask()
        }
        .animation(.easeInOut(duration: 0.3), value: controlsVisible)
    }

    private func showControls() {
        if !controlsVisible {
            controlsVisible = true
        }
    }

    private func showControlsAndScheduleHide() {
        showControls()
        scheduleHide()
    }

    private func scheduleHide() {
        cancelHideTask()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            controlsVisible = false
        }
    }

    private func cancelHideTask() {
        hideControlsTask?.cancel()
        hideControlsTask = nil
    }

    private var scoreScrubGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if !isScrubbing {
                    isScrubbing = true
                    showControls()
                    cancelHideTask()
                }

                let deltaY = value.translation.height - dragOffsetAccumulator

                guard abs(deltaY) >= pointsPerStep else { return }

                let speed = abs(value.velocity.height)
                let stepSize = speed > fastThreshold ? 5 : 1

                let rawSteps = Int(abs(deltaY) / pointsPerStep)
                let direction = deltaY < 0 ? 1 : -1
                adjustScore(by: rawSteps * stepSize * direction)

                dragOffsetAccumulator += CGFloat(rawSteps) * pointsPerStep * CGFloat(direction == 1 ? -1 : 1)
            }
            .onEnded { _ in
                dragOffsetAccumulator = 0
                isScrubbing = false
                showControlsAndScheduleHide()
            }
    }

    private func adjustScore(by stepDelta: Int) {
        guard stepDelta != 0 else { return }
        scoreIndex = min(100, max(0, scoreIndex + stepDelta))
    }
}
