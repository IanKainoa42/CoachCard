import SwiftUI
import PencilKit

struct WhiteboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var theme: CardTheme = .dark
    @State private var toolMode: WhiteboardTool = .draw
    @State private var penColor: Color = .white
    @State private var penWidth: CGFloat = 8
    @State private var controlsVisible: Bool = true
    @State private var hideTimer: Timer?
    @State private var previousBrightness: CGFloat = 0.5

    enum WhiteboardTool: String, CaseIterable {
        case draw = "Draw"
        case erase = "Erase"
    }

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            CanvasRepresentable(
                canvasView: $canvasView,
                backgroundColor: UIColor(theme.backgroundColor),
                toolMode: toolMode,
                penColor: UIColor(penColor),
                penWidth: penWidth
            )
            .ignoresSafeArea()

            // Controls overlay
            VStack {
                HStack(spacing: 16) {
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(theme.textColor)
                    }
                    .opacity(controlsVisible ? 0.6 : 0.15)

                    Spacer()

                    // Tool picker
                    Picker("Tool", selection: $toolMode) {
                        Label("Draw", systemImage: "pencil.tip")
                            .tag(WhiteboardTool.draw)
                        Label("Erase", systemImage: "eraser")
                            .tag(WhiteboardTool.erase)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .opacity(controlsVisible ? 0.8 : 0.15)

                    // Pen color (only when drawing)
                    if toolMode == .draw {
                        ColorPicker("", selection: $penColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 36, height: 36)
                            .opacity(controlsVisible ? 0.8 : 0.15)
                    }

                    // Pen width slider
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(theme.textColor)
                        Slider(value: $penWidth, in: 2...30)
                            .frame(width: 100)
                        Image(systemName: "circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textColor)
                    }
                    .opacity(controlsVisible ? 0.8 : 0.15)

                    // Clear button
                    Button {
                        canvasView.drawing = PKDrawing()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(theme.textColor)
                    }
                    .opacity(controlsVisible ? 0.6 : 0.15)

                    // Theme picker
                    Picker("Theme", selection: $theme) {
                        ForEach(CardTheme.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .opacity(controlsVisible ? 0.7 : 0.15)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(
                    theme.backgroundColor.opacity(controlsVisible ? 0.7 : 0)
                )

                Spacer()
            }
        }
        .statusBarHidden(true)
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            penColor = theme.textColor
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
            hideTimer?.invalidate()
        }
        .onChange(of: theme) {
            penColor = theme.textColor
        }
        .animation(.easeInOut(duration: 0.3), value: controlsVisible)
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var backgroundColor: UIColor
    var toolMode: WhiteboardView.WhiteboardTool
    var penColor: UIColor
    var penWidth: CGFloat

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = backgroundColor
        canvasView.isOpaque = true
        updateTool()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.backgroundColor = backgroundColor
        updateTool()
    }

    private func updateTool() {
        switch toolMode {
        case .draw:
            canvasView.tool = PKInkingTool(.pen, color: penColor, width: penWidth)
        case .erase:
            canvasView.tool = PKEraserTool(.bitmap)
        }
    }
}
