//
//  CameraView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var cameraController = CameraController()
    let appState: AppState
    @EnvironmentObject var itemStorage: ItemStorageService

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text("QuickFlip")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)

                // Camera Preview
                CameraPreviewView(session: cameraController.session)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                // Results Area
                VStack(spacing: 12) {
                    if cameraController.isAnalyzing {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.2)
                            Text("Analyzing with AI...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                        .frame(height: 120)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                if let result = cameraController.analysisResult,
                                   let image = cameraController.lastCapturedImage {

                                    NavigationLink(
                                        destination: MarketplaceSelectionView(
                                            itemAnalysis: result,
                                            capturedImage: image
                                        )
                                    ) {
                                        ItemResultView(result: result)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                } else {
                                    Text("Point camera at an item and tap to identify")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                }

                Spacer()

                // Capture Button
                Button(action: {
                    cameraController.capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .fill(cameraController.isAnalyzing ? Color.gray : Color.blue)
                            .frame(width: 80, height: 80)

                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .disabled(cameraController.isAnalyzing)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraController.requestCameraPermission()
            cameraController.itemStorage = itemStorage
        }
        .alert("Camera Permission Required", isPresented: $cameraController.showPermissionAlert) {
            Button("Settings") {
                cameraController.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("QuickFlip needs camera access to identify items.")
        }
    }
}
