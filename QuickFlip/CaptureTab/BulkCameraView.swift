//
//  BulkCameraView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import AVFoundation
import SwiftUI

struct BulkCameraView: View {
    let cameraAction: (BulkAnalysisResult) -> Void

    @StateObject private var cameraController = CameraController()
    @StateObject private var bulkAnalysisService = BulkAnalysisService()
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var isAnalyzing = false
    @State private var bulkResult: BulkAnalysisResult?
    @State private var photoDelegate: BulkPhotoDelegate?
    @State private var showTips = true

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

            if isAnalyzing {
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
                                .foregroundColor(.orange)
                            Text("Bulk Analysis Tips")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(icon: "rectangle.3.group", text: "Spread items out on a flat surface", color: .white)
                            TipRow(icon: "lightbulb", text: "Ensure good lighting on all items", color: .white)
                            TipRow(icon: "tag", text: "Include brand labels when possible", color: .white)
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
                        captureAndAnalyze()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 95, height: 95)

                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .disabled(isAnalyzing)
                    .scaleEffect(isAnalyzing ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isAnalyzing)
                }
                .padding(.bottom, 50)
            }
        }
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
        .alert("Camera Permission Required", isPresented: $cameraController.showPermissionAlert) {
            Button("Settings") {
                cameraController.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("QuickFlip needs camera access to analyze items.")
        }
    }

    private func captureAndAnalyze() {
        guard !isAnalyzing else {
            print("QuickFlip: Already analyzing, skipping")
            return
        }

        isAnalyzing = true

        // Store the delegate as a property so it doesn't get deallocated
        photoDelegate = BulkPhotoDelegate { image in
            print("QuickFlip: BulkPhotoDelegate callback called")

            guard let capturedImage = image else {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.photoDelegate = nil // Clean up
                }
                return
            }

            Task {
                do {
                    let result = try await self.bulkAnalysisService.analyzeBulkItems(image: capturedImage)

                    await MainActor.run {
                        self.bulkResult = result
                        self.isAnalyzing = false
                        self.photoDelegate = nil // Clean up
                        cameraAction(result)
                    }

                } catch {
                    print("QuickFlip: Bulk analysis failed with error: \(error)")
                    await MainActor.run {
                        self.isAnalyzing = false
                        self.photoDelegate = nil // Clean up
                    }
                }
            }
        }

        cameraController.captureBulkPhoto(delegate: photoDelegate!)
    }
}

// MARK: - Photo Delegate for Bulk Analysis
class BulkPhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }

        completion(image)
    }
}
