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
    @State private var navigateToMarketplace = false

    var body: some View {
        NavigationStack {
            ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Item Scanner")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Point camera at an item to identify and price")
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
                            if cameraController.isAnalyzing {
                                Color.black.opacity(0.7)
                                    .overlay(
                                        VStack(spacing: 16) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.5)

                                            VStack(spacing: 4) {
                                                Text("Analyzing Item...")
                                                    .font(.headline)
                                                    .foregroundColor(.white)

                                                Text("Identifying and pricing your item")
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
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Capture Button
                Button(action: {
                    cameraController.capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .fill(cameraController.isAnalyzing ? Color.gray : Color.blue)
                            .frame(width: 80, height: 80)

                        if cameraController.isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(cameraController.isAnalyzing)
                .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToMarketplace) {
                if let result = cameraController.analysisResult,
                   let image = cameraController.lastCapturedImage {
                    MarketplaceSelectionView(
                        itemAnalysis: result,
                        capturedImage: image
                    )
                    .environmentObject(itemStorage)
                }
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
        .onChange(of: cameraController.analysisResult) { _, newResult in
            if newResult != nil && cameraController.lastCapturedImage != nil && !navigateToMarketplace {
                navigateToMarketplace = true
            }
        }
    }
}
