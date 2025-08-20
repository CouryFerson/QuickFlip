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

    @State private var showingImagePicker = false

    var body: some View {
        NavigationView {
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

                        // Bulk Analysis Option (NEW!)
                        CaptureOptionCard(
                            title: "Bulk Analysis",
                            subtitle: "Scan multiple items at once",
                            icon: "square.grid.3x3.fill",
                            color: .purple,
                            isRecommended: true
                        ) {
                            captureBulktemsAction()
                        }

                        // Barcode Scanner (Future feature)
                        CaptureOptionCard(
                            title: "Scan Barcode",
                            subtitle: "Quick lookup for products",
                            icon: "barcode.viewfinder",
                            color: .orange
                        ) {
                            captureBarcodeAction()
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
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                // TODO: Process uploaded image
                handleUploadedImage(image)
            }
        }
    }

    private func handleUploadedImage(_ image: UIImage) {
        // TODO: Navigate to marketplace selection with uploaded image
        print("Uploaded image: \(image)")
    }
}

struct CaptureOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isRecommended: Bool = false
    var isComingSoon: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.title)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if isRecommended {
                                Text("RECOMMENDED")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
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
                        }

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if !isComingSoon {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isRecommended ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isComingSoon)
        .opacity(isComingSoon ? 0.6 : 1.0)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.subheadline)
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
