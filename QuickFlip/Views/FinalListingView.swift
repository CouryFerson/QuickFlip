//
//  FinalListingView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct FinalListingView: View {
    let listing: EbayListing
    let selectedMarketplace: Marketplace
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @State private var generatedListing: MarketplaceListingOutput?
    @State private var showingCopySuccess = false
    @State private var showingPhotoSaved = false
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: selectedMarketplace.iconName)
                        .font(.system(size: 50))
                        .foregroundColor(selectedMarketplace.color)

                    Text("Ready to List on \(selectedMarketplace.rawValue)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Your listing has been optimized for \(selectedMarketplace.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Photo Preview
                if let photo = listing.photos.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Ready")
                            .font(.headline)

                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }

                // Generated Listing Preview
                if let generated = generatedListing {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Listing Details")
                            .font(.headline)

                        ScrollView {
                            Text(generated.listingText)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)

                        // Fee Information
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Estimated Fees")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(generated.estimatedFees)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // Action Buttons
                VStack(spacing: 12) {
                    // Primary Actions
                    VStack(spacing: 12) {
                        Button("📋 Copy Listing Details") {
                            copyListingToClipboard()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedMarketplace.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)

                        Button("📸 Save Photo to Camera Roll") {
                            savePhotoToLibrary()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    // Secondary Actions
                    HStack(spacing: 12) {
                        Button("Share") {
                            showingShareSheet = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)

                        Button("Edit Listing") {
                            // Go back to edit
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }

                // Instructions
                if let generated = generatedListing {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Steps")
                            .font(.headline)

                        Text(generated.instructions)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // Success Actions
                VStack(spacing: 12) {
                    Button("✅ Mark as Listed") {
                        markAsListed()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)

                    Button("🏠 Back to Home") {
                        navigateToHome()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("Final Listing")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateListing()
        }
        .alert("Copied!", isPresented: $showingCopySuccess) {
            Button("OK") { }
        } message: {
            Text("Listing details have been copied to your clipboard. Now go to \(selectedMarketplace.rawValue) and paste!")
        }
        .alert("Photo Saved!", isPresented: $showingPhotoSaved) {
            Button("OK") { }
        } message: {
            Text("Photo has been saved to your camera roll.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let generated = generatedListing {
                ShareSheet(items: [generated.copyableContent])
            }
        }
    }

    private func generateListing() {
        generatedListing = UniversalListingGenerator.generateListing(
            for: selectedMarketplace,
            item: listing
        )
    }

    private func copyListingToClipboard() {
        guard let generated = generatedListing else { return }

        UIPasteboard.general.string = generated.listingText

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        showingCopySuccess = true
    }

    private func savePhotoToLibrary() {
        guard let photo = listing.photos.first else { return }

        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator()
        impactFeedback.impactOccurred()

        showingPhotoSaved = true
    }

    private func markAsListed() {
        // Update the item in storage to mark as listed
        // This could add a "listed" status to the ScannedItem model

        let impactFeedback = UIImpactFeedbackGenerator()
        impactFeedback.impactOccurred()

        // Navigate back to home or show success
        navigateToHome()
    }

    private func navigateToHome() {
        // Dismiss all the way back to the main tab view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct FinalListingView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleListing = EbayListing(
            title: "Apple TV Remote Control",
            description: "Like new Apple TV remote in excellent condition",
            category: "Electronics",
            condition: "Like New",
            startingPrice: 35.0,
            buyItNowPrice: 45.0,
            listingType: .buyItNow,
            duration: 7,
            shippingCost: 0.0,
            returnsAccepted: true,
            returnPeriod: 30,
            photos: [UIImage(systemName: "photo")!]
        )

        NavigationView {
            FinalListingView(
                listing: sampleListing,
                selectedMarketplace: .ebay
            )
        }
    }
}
