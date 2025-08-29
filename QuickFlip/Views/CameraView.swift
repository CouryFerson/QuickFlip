////
////  CameraView.swift
////  QuickFlip
////
////  Created by Ferson, Coury on 8/17/25.
////

import SwiftUI

struct CameraView: View {
    let captureAction: (ScannedItem, UIImage) -> Void
    @StateObject private var cameraController = CameraController()
    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var imageAnalysisService: ImageAnalysisService
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

            if cameraController.isAnalyzing {
                CameraProcessingOverlay()
            }

            // Focus indicator - use screen location instead of converted point
            if let screenLocation = cameraController.focusScreenLocation {
                FocusIndicator(isFocusing: cameraController.isFocusing)
                    .position(screenLocation)
            }

            VStack {
                //  Tips Section
                if showTips {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                            Text("Scanning Tips")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(icon: "viewfinder", text: "Center item in camera frame", color: .white)
                            TipRow(icon: "lightbulb", text: "Ensure good lighting", color: .white)
                            TipRow(icon: "tag", text: "Include brand labels and text", color: .white)
                            TipRow(icon: "hand.raised", text: "Hold steady while scanning", color: .white)
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
                    //                    if let errorMessage = errorMessage {
                    //                        Text(errorMessage)
                    //                            .font(.subheadline)
                    //                            .foregroundColor(.red)
                    //                            .padding()
                    //                            .background(Color.red.opacity(0.1))
                    //                            .cornerRadius(8)
                    //                            .padding(.horizontal)
                    //                    }

                    // Capture button
                    Button(action: {
                        cameraController.capturePhoto(analysisService: imageAnalysisService)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 95, height: 95)

                            if cameraController.isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "camera")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .disabled(cameraController.isAnalyzing)
                    .scaleEffect(cameraController.isAnalyzing ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: cameraController.isAnalyzing)
                }
                .padding(.bottom, 50)
            }
        }
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
        .alert("Camera Permission Required", isPresented: $cameraController.showPermissionAlert) {
            Button("Settings") {
                cameraController.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("QuickFlip needs camera access to identify items.")
        }
        .onChange(of: cameraController.scannedItem) { _, newResult in
            if let result = cameraController.scannedItem,
               let image = cameraController.lastCapturedImage {
                captureAction(result, image)
            }
        }
    }
}

private extension CameraView {
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

struct FocusIndicator: View {
    let isFocusing: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(isFocusing ? Color.yellow : Color.green, lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(isFocusing ? 1.2 : 1.0)
            .opacity(isFocusing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocusing)
    }
}
