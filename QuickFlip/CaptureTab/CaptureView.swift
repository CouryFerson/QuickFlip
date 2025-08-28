//
//  Untitled.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct CaptureView: View {
    let captureSingleItemAction: () -> Void
    let captureBulktemsAction: () -> Void
    let captureBarcodeAction: () -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingImagePicker = false
    @State private var showingUpgradeAlert = false
    @State private var showingSubscriptionView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Capture & Analyze")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose how you'd like to analyze your item")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Capture Options
                VStack(spacing: 20) {
                    // Take Photo Option
                    CaptureOptionCard(
                        title: "Single Item",
                        subtitle: "Analyze one item at a time",
                        icon: "camera.fill",
                        color: .blue,
                        isRecommended: false
                    ) {
                        captureSingleItemAction()
                    }

                    // Bulk Analysis Option (Premium)
                    CaptureOptionCard(
                        title: "Bulk Analysis",
                        subtitle: "Scan multiple items at once",
                        icon: "square.grid.3x3.fill",
                        color: .purple,
                        isRecommended: true,
                        isPremium: !subscriptionManager.canAccessFeature("bulk_scanning")
                    ) {
                        if subscriptionManager.canAccessFeature("bulk_scanning") {
                            captureBulktemsAction()
                        } else {
                            showingUpgradeAlert = true
                        }
                    }

                    // Barcode Scanner (Premium)
                    CaptureOptionCard(
                        title: "Scan Barcode",
                        subtitle: "Quick lookup for products",
                        icon: "barcode.viewfinder",
                        color: .orange,
                        isPremium: !subscriptionManager.canAccessFeature("barcode_scanning")
                    ) {
                        if subscriptionManager.canAccessFeature("barcode_scanning") {
                            captureBarcodeAction()
                        } else {
                            showingUpgradeAlert = true
                        }
                    }

                    // Upload from Gallery
                    CaptureOptionCard(
                        title: "Upload Photo",
                        subtitle: "Choose from photo library",
                        icon: "photo.fill",
                        color: .green,
                        isComingSoon: true
                    ) {
                        showingImagePicker = true
                    }
                }
                .padding(.horizontal)

                // Tips Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                        Text("Tips for Best Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(icon: "camera.macro", text: "Take clear, well-lit photos", color: .primary)
                        TipRow(icon: "eye.fill", text: "Include brand names and labels", color: .primary)
                        TipRow(icon: "hand.raised.fill", text: "Show the item's condition clearly", color: .primary)
                        TipRow(icon: "tag.fill", text: "Include model numbers if visible", color: .primary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                handleUploadedImage(image)
            }
        }
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }
        .alert("Upgrade Required", isPresented: $showingUpgradeAlert) {
            Button("Upgrade") {
                showingSubscriptionView = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(subscriptionManager.upgradePromptMessage)
        }
    }

    private func handleUploadedImage(_ image: UIImage) {
        // TODO: Navigate to marketplace selection with uploaded image
        print("Uploaded image: \(image)")
    }
}

// Updated CaptureOptionCard to support premium features
struct CaptureOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isRecommended: Bool = false
    var isComingSoon: Bool = false
    var isPremium: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Spacer()

                        // Badges
                        HStack(spacing: 6) {
                            if isRecommended {
                                Text("RECOMMENDED")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }

                            if isComingSoon {
                                Text("COMING SOON")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }

                            if isPremium {
                                HStack(spacing: 2) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                    Text("Starter")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            }
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isComingSoon ? 0.6 : 1.0)
        .disabled(isComingSoon)
    }
}

// Helper view for tips
struct TipRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(color)

            Spacer()
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
