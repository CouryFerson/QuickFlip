//
//  BulkCameraView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import AVFoundation
import SwiftUI

struct BulkCameraView: View {
    @StateObject private var cameraController = CameraController()
    @StateObject private var bulkAnalysisService = BulkAnalysisService()
    let appState: AppState
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var isAnalyzing = false
    @State private var bulkResult: BulkAnalysisResult?
    @State private var showingResults = false
    @State private var photoDelegate: BulkPhotoDelegate?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Bulk Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Capture multiple items in one photo")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)

                // Camera Preview
                CameraPreviewView(session: cameraController.session)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .overlay(
                        // Analysis overlay
                        Group {
                            if isAnalyzing {
                                Color.black.opacity(0.7)
                                    .overlay(
                                        VStack(spacing: 16) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.5)

                                            VStack(spacing: 4) {
                                                Text("Analyzing Scene...")
                                                    .font(.headline)
                                                    .foregroundColor(.white)

                                                Text("Finding all sellable items")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    )

                Spacer()

                // Tips Section
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
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Capture Button
                Button(action: {
                    captureAndAnalyze()
                }) {
                    ZStack {
                        Circle()
                            .fill(isAnalyzing ? Color.gray : Color.purple)
                            .frame(width: 80, height: 80)

                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isAnalyzing)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraController.requestCameraPermission()
        }
        .alert("Camera Permission Required", isPresented: $cameraController.showPermissionAlert) {
            Button("Settings") {
                cameraController.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("QuickFlip needs camera access to analyze items.")
        }
        .fullScreenCover(isPresented: $showingResults) {
            if let result = bulkResult {
                BulkAnalysisResultsView(result: result)
                    .environmentObject(itemStorage)
            }
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
                        self.showingResults = true
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
