//
//  CaptureView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct CaptureView: View {
    let captureSingleItemAction: () -> Void
    let captureBulktemsAction: () -> Void
    let captureBarcodeAction: () -> Void

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingImagePicker = false
    @State private var showingUpgradeAlert = false
    @State private var showingSubscriptionView = false
    @State private var showingTokenAlert = false
    @State private var showingHowItWorksSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                captureOptionsSection
                tipsSection

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
        .sheet(isPresented: $showingHowItWorksSheet) {
            HowItWorksSheet()
        }
        .alert("Upgrade Required", isPresented: $showingUpgradeAlert) {
            Button("Upgrade") {
                showingSubscriptionView = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(subscriptionManager.upgradePromptMessage)
        }
        .alert("No tokens left", isPresented: $showingTokenAlert) {
            Button("Done", role: .cancel) { }
        } message: {
            Text(subscriptionManager.addTokensMessage)
        }
    }
}

// MARK: - View Components
private extension CaptureView {

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()

                Button {
                    showingHowItWorksSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("How It Works")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.trailing)
                .padding(.top, 8)
            }

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
        .padding(.top, 20)
    }

    @ViewBuilder
    var captureOptionsSection: some View {
        VStack(spacing: 20) {
            singleItemOption
            bulkAnalysisOption
            barcodeOption
            uploadPhotoOption
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var singleItemOption: some View {
        CaptureOptionCard(
            title: "Single Item",
            subtitle: "Analyze one item at a time",
            icon: "camera.fill",
            color: .blue,
            tokenCount: 1,
            isRecommended: false
        ) {
            if authManager.hasTokens() {
                captureSingleItemAction()
            } else {
                showingTokenAlert = true
            }
        }
    }

    @ViewBuilder
    var bulkAnalysisOption: some View {
        CaptureOptionCard(
            title: "Bulk Analysis",
            subtitle: "Scan multiple items at once",
            icon: "square.grid.3x3.fill",
            color: .purple,
            tokenCount: 2,
            isRecommended: true,
            isPremium: !subscriptionManager.canAccessFeature("bulk_scanning")
        ) {
            if subscriptionManager.canAccessFeature("bulk_scanning") {
                if authManager.hasTokens() {
                    captureBulktemsAction()
                } else {
                    showingTokenAlert = true
                }
            } else {
                showingUpgradeAlert = true
            }
        }
    }

    @ViewBuilder
    var barcodeOption: some View {
        CaptureOptionCard(
            title: "Scan Barcode",
            subtitle: "Quick lookup for products",
            icon: "barcode.viewfinder",
            color: .orange,
            tokenCount: 1,
            isPremium: !subscriptionManager.canAccessFeature("barcode_scanning")
        ) {
            if subscriptionManager.canAccessFeature("barcode_scanning") {
                if authManager.hasTokens() {
                    captureBarcodeAction()
                } else {
                    showingTokenAlert = true
                }
            } else {
                showingUpgradeAlert = true
            }
        }
    }

    @ViewBuilder
    var uploadPhotoOption: some View {
        CaptureOptionCard(
            title: "Upload Photo",
            subtitle: "Choose from photo library",
            icon: "photo.fill",
            color: .green,
            tokenCount: 1,
            isComingSoon: true
        ) {
            showingImagePicker = true
        }
    }

    @ViewBuilder
    var tipsSection: some View {
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
    }
}

// MARK: - Actions
private extension CaptureView {

    func handleUploadedImage(_ image: UIImage) {
        // TODO: Navigate to marketplace selection with uploaded image
        print("Uploaded image: \(image)")
    }
}

// MARK: - How It Works Sheet
struct HowItWorksSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    howItWorksSteps
                    importantNoteSection

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - How It Works Components
private extension HowItWorksSheet {

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("AI-Powered Price Analysis")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Our AI analyzes your items and provides estimated pricing based on marketplace data")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    var howItWorksSteps: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The Process")
                .font(.headline)
                .fontWeight(.semibold)

            stepRow(
                number: 1,
                icon: "camera.fill",
                title: "Capture Your Item",
                description: "Take a clear photo of the item you want to analyze. Each scan uses tokens from your account."
            )

            stepRow(
                number: 2,
                icon: "sparkles",
                title: "AI Analysis",
                description: "Our AI examines the image to identify the item, brand, condition, and other relevant details."
            )

            stepRow(
                number: 3,
                icon: "chart.bar.fill",
                title: "Price Estimation",
                description: "Based on current marketplace data and similar listings, the AI generates estimated pricing across multiple platforms."
            )

            stepRow(
                number: 4,
                icon: "checkmark.circle.fill",
                title: "Review Results",
                description: "You'll receive detailed analysis including estimated values, market insights, and selling recommendations."
            )
        }
    }

    @ViewBuilder
    func stepRow(number: Int, icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    var importantNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text("Important Information")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 12) {
                infoRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Prices are estimates, not guarantees. Actual selling prices may vary based on market conditions, buyer demand, and item specifics."
                )

                infoRow(
                    icon: "brain",
                    text: "Our AI is trained on extensive marketplace data and continuously improves, but it may occasionally make errors in identification or pricing."
                )

                infoRow(
                    icon: "person.fill.checkmark",
                    text: "Always verify pricing and item details independently before making business decisions. Use these estimates as a helpful starting point."
                )

                infoRow(
                    icon: "bitcoinsign.circle.fill",
                    text: "Each analysis consumes tokens from your account. Tokens reset monthly for subscribers or can be purchased separately."
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    @ViewBuilder
    func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Supporting Views
struct CaptureOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let tokenCount: Int
    var isRecommended: Bool = false
    var isComingSoon: Bool = false
    var isPremium: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                iconView
                contentView
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isRecommended ? color : Color.clear, lineWidth: 2)
                    .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isComingSoon ? 0.6 : 1.0)
        .disabled(isComingSoon)
    }
}

private extension CaptureOptionCard {

    @ViewBuilder
    var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 32))
            .foregroundColor(color)
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(color.opacity(0.1))
            )
    }

    @ViewBuilder
    var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                badgesView
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)

            tokenIndicator
        }
    }

    @ViewBuilder
    var badgesView: some View {
        HStack(spacing: 6) {
            if isRecommended {
                badgeView(text: "RECOMMENDED", color: .green)
            }

            if isComingSoon {
                badgeView(text: "COMING SOON", color: .gray)
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

    @ViewBuilder
    func badgeView(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    @ViewBuilder
    var tokenIndicator: some View {
        Text(tokenCount == 1 ? "1 token" : "\(tokenCount) tokens")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.15))
            )
            .padding(.top, 2)
    }
}

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
