import SwiftUI
import PencilKit

struct WhiteboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var canvas = CanvasManager()
    @State private var theme: CardTheme = .dark
    @State private var toolMode: WhiteboardTool = .draw
    @State private var penColor: Color = .white
    @State private var penWidth: CGFloat = 8
    @State private var controlsVisible: Bool = true
    @State private var hideTimer: Timer?
    @State private var previousBrightness: CGFloat = 0.5

    enum WhiteboardTool: String {
        case draw
        case erase
    }

    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()

            CanvasRepresentable(manager: canvas)
                .ignoresSafeArea()

            // Controls — separated from canvas to avoid triggering updateUIView
            controlsOverlay
        }
        .statusBarHidden(true)
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
            penColor = theme.textColor
            canvas.configure(
                backgroundColor: UIColor(theme.backgroundColor),
                tool: makeTool()
            )
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
            hideTimer?.invalidate()
        }
        .onChange(of: theme) {
            penColor = theme.textColor
            canvas.setBackground(UIColor(theme.backgroundColor))
            canvas.setTool(makeTool())
        }
        .onChange(of: toolMode) {
            canvas.setTool(makeTool())
        }
        .onChange(of: penColor) {
            if toolMode == .draw {
                canvas.setTool(makeTool())
            }
        }
        .onChange(of: penWidth) {
            if toolMode == .draw {
                canvas.setTool(makeTool())
            }
        }
    }

    private func makeTool() -> PKTool {
        switch toolMode {
        case .draw:
            return PKInkingTool(.pen, color: UIColor(penColor), width: penWidth)
        case .erase:
            return PKEraserTool(.bitmap)
        }
    }

    @ViewBuilder
    private var controlsOverlay: some View {
        VStack {
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(theme.textColor)
                }
                .opacity(controlsVisible ? 0.6 : 0.15)

                Spacer()

                // Undo / Redo
                HStack(spacing: 8) {
                    Button { canvas.undo() } label: {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(theme.textColor)
                    }
                    .disabled(!canvas.canUndo)

                    Button { canvas.redo() } label: {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(theme.textColor)
                    }
                    .disabled(!canvas.canRedo)
                }
                .opacity(controlsVisible ? 0.6 : 0.15)

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

                if toolMode == .draw {
                    ColorPicker("", selection: $penColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 36, height: 36)
                        .opacity(controlsVisible ? 0.8 : 0.15)
                }

                // Pen width
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.textColor)
                        .frame(width: 4, height: 4)
                    Slider(value: $penWidth, in: 2...30)
                        .frame(width: 100)
                    Circle()
                        .fill(theme.textColor)
                        .frame(width: 16, height: 16)
                }
                .opacity(controlsVisible ? 0.8 : 0.15)

                Button { canvas.clear() } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(theme.textColor)
                }
                .opacity(controlsVisible ? 0.6 : 0.15)

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
            .allowsHitTesting(true)

            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: controlsVisible)
    }
}

// MARK: - Canvas Manager (owns the PKCanvasView, avoids SwiftUI rebuild churn)

final class CanvasManager: NSObject, ObservableObject, PKCanvasViewDelegate {
    let canvasView = PKCanvasView()
    @Published var canUndo = false
    @Published var canRedo = false

    override init() {
        super.init()

        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.isOpaque = true
        canvasView.contentInsetAdjustmentBehavior = .never
        canvasView.showsVerticalScrollIndicator = false
        canvasView.showsHorizontalScrollIndicator = false
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false
        canvasView.maximumZoomScale = 1
        canvasView.minimumZoomScale = 1
        canvasView.bouncesZoom = false
    }

    func configure(backgroundColor: UIColor, tool: PKTool) {
        canvasView.backgroundColor = backgroundColor
        canvasView.tool = tool
        refreshUndoState()
    }

    func setTool(_ tool: PKTool) {
        canvasView.tool = tool
    }

    func setBackground(_ color: UIColor) {
        canvasView.backgroundColor = color
    }

    func clear() {
        canvasView.drawing = PKDrawing()
        updateUndoState()
    }

    func undo() {
        canvasView.undoManager?.undo()
        updateUndoState()
    }

    func redo() {
        canvasView.undoManager?.redo()
        updateUndoState()
    }

    func refreshUndoState() {
        updateUndoState()
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateUndoState()
    }

    private func updateUndoState() {
        let nextCanUndo = canvasView.undoManager?.canUndo ?? !canvasView.drawing.strokes.isEmpty
        let nextCanRedo = canvasView.undoManager?.canRedo ?? false

        if canUndo != nextCanUndo {
            canUndo = nextCanUndo
        }
        if canRedo != nextCanRedo {
            canRedo = nextCanRedo
        }
    }
}

// MARK: - UIViewRepresentable (minimal — no updateUIView work)

struct CanvasRepresentable: UIViewRepresentable {
    let manager: CanvasManager

    func makeUIView(context: Context) -> PKCanvasView {
        manager.refreshUndoState()
        return manager.canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Intentionally empty — all updates go through CanvasManager
        // to avoid SwiftUI rebuild churn during drawing
    }
}
