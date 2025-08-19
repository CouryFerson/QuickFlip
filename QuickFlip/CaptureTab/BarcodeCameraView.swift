import SwiftUI
import AVFoundation

struct BarcodeCameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraController = CameraController()
    @State private var errorMessage: String?
    @State private var showingMarketplaceSelection = false

    var body: some View {
        NavigationView {
            ZStack {
                // Camera Feed
                CameraPreview(cameraController: cameraController)
                    .ignoresSafeArea()

                // Scanning Reticle
                VStack {
                    Spacer()

                    ZStack {
                        // Reticle Frame
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 3)
                            .frame(width: 280, height: 140)
                            .background(Color.clear)

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
                        if !cameraController.isBarcodeAnalyzing {
                            ScanningLine()
                        }
                    }

                    Spacer()
                }

                // Top overlay with tips
                VStack {
                    // Tips Section
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
                            cameraController.captureBarcodePhoto()
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
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            cameraController.requestCameraPermission()
        }
        .onChange(of: cameraController.barcodeAnalysisResult) { _, result in
            if result != nil {
                showingMarketplaceSelection = true
            }
        }
        .fullScreenCover(isPresented: $showingMarketplaceSelection) {
            if let itemAnalysis = cameraController.barcodeAnalysisResult,
               let capturedImage = cameraController.lastCapturedImage {
                NavigationView {
                    MarketplaceSelectionView(
                        itemAnalysis: itemAnalysis,
                        capturedImage: capturedImage
                    )
                    .navigationBarItems(
                        leading: Button("Back") {
                            showingMarketplaceSelection = false
                            cameraController.barcodeAnalysisResult = nil
                        }
                    )
                }
            }
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
                            .frame(width: 20, height: 3)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 3, height: 20)
                        Spacer()
                    }
                    Spacer()
                }
            case .topRight:
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 20, height: 3)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 3, height: 20)
                    }
                    Spacer()
                }
            case .bottomLeft:
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 3, height: 20)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 20, height: 3)
                        Spacer()
                    }
                }
            case .bottomRight:
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 3, height: 20)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(width: 20, height: 3)
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
    @State private var position: CGFloat = 0

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
                    position = 70
                }
            }
    }
}
