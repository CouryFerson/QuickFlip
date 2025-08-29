import SwiftUI
import AVFoundation

struct BarcodeCameraView: View {
    let captureAction: (ScannedItem, UIImage) -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var imageAnalysisService: ImageAnalysisService
    @StateObject private var cameraController = CameraController()
    @State private var errorMessage: String?
    @State private var showTips = true
    @State private var lastZoom: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Camera Feed
            CameraPreview(cameraController: cameraController)
                .ignoresSafeArea()
                .onTapGesture { location in
                    // Get the geometry of the camera preview
                    let previewBounds = UIScreen.main.bounds // We'll improve this

                    // Convert to camera coordinates (0-1 range)
                    // Camera coordinates: (0,0) = top-left, (1,1) = bottom-right
                    let convertedPoint = CGPoint(
                        x: location.x / previewBounds.width,
                        y: location.y / previewBounds.height
                    )

                    cameraController.focusAt(point: convertedPoint, screenLocation: location)
                }

            // Focus indicator - use screen location instead of converted point
            if let screenLocation = cameraController.focusScreenLocation {
                FocusIndicator(isFocusing: cameraController.isFocusing)
                    .position(screenLocation)
            }

            if cameraController.isBarcodeAnalyzing {
                CameraProcessingOverlay()
            }

            // Scanning Reticle
            if !cameraController.isBarcodeAnalyzing {
                VStack {
                    // Corner brackets
                    VStack {
                        HStack {
                            CornerBracket(position: .topLeft)
                            Spacer()
                            CornerBracket(position: .topRight)
                        }
                        Spacer()
                        HStack {
                            CornerBracket(position: .bottomLeft)
                            Spacer()
                            CornerBracket(position: .bottomRight)
                        }
                    }
                    .frame(width: 280, height: 140)

                    // Scanning animation line
                    ScanningLine()
                }
            }

            // Top overlay with tips
            VStack {
                // Tips Section with fade animation
                if showTips {
                    VStack(spacing: 12) {
                        Text("Scan Barcode")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        VStack(spacing: 8) {
                            TipRow(
                                icon: "viewfinder",
                                text: "Center barcode in the frame",
                                color: .white
                            )

                            TipRow(
                                icon: "lightbulb.fill",
                                text: "Ensure good lighting on barcode",
                                color: .white
                            )

                            TipRow(
                                icon: "hand.raised.fill",
                                text: "Hold steady until scan completes",
                                color: .white
                            )
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }

                Spacer()

                // Bottom controls area
                VStack(spacing: 16) {
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }

                    // Capture button
                    Button(action: {
                        cameraController.captureBarcodePhoto(analysisService: imageAnalysisService)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 95, height: 95)

                            if cameraController.isBarcodeAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .disabled(cameraController.isBarcodeAnalyzing)
                    .scaleEffect(cameraController.isBarcodeAnalyzing ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: cameraController.isBarcodeAnalyzing)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .gesture(pinchGesture)
        .onAppear {
            cameraController.requestCameraPermission()
            cameraController.itemStorage = itemStorage

            // Fade out tips after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showTips = false
                }
            }
        }
        .onDisappear {
            cameraController.session.stopRunning()
        }
        .onChange(of: cameraController.barcodeScannedItem) { _, result in
            if let itemAnalysis = cameraController.barcodeScannedItem,
               let capturedImage = cameraController.lastCapturedImage {
                captureAction(itemAnalysis, capturedImage)
            }
        }
    }
}

private extension BarcodeCameraView {
    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newZoom = lastZoom * value
                cameraController.setZoom(factor: newZoom)
            }
            .onEnded { _ in
                lastZoom = cameraController.currentZoom
            }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let cameraController: CameraController

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraController.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Corner Bracket
struct CornerBracket: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    let position: Position

    var body: some View {
        ZStack {
            switch position {
            case .topLeft:
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 10, height: 3)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 3, height: 10)
                        Spacer()
                    }
                    Spacer()
                }
            case .topRight:
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 10, height: 3)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 3, height: 10)
                    }
                    Spacer()
                }
            case .bottomLeft:
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 3, height: 10)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 10, height: 3)
                        Spacer()
                    }
                }
            case .bottomRight:
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 3, height: 10)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 10, height: 3)
                    }
                }
            }
        }
        .foregroundColor(.green)
        .frame(width: 30, height: 30)
    }
}

// MARK: - Scanning Line Animation
struct ScanningLine: View {
    @State private var position: CGFloat = -8

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .green, .green, .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 280, height: 2)
            .offset(y: position)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    position = -148
                }
            }
    }
}
