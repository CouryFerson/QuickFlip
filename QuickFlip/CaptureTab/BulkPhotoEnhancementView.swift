import SwiftUI

struct BulkPhotoEnhancementView: View {
    let selectedItems: [BulkAnalyzedItem]
    let originalImage: UIImage
    let onItemsSaved: ([ScannedItem]) -> Void
    let onComplete: () -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode

    @State private var currentItemIndex = 0
    @State private var itemPhotos: [UIImage] = []
    @State private var showingCamera = false

    var currentItem: BulkAnalyzedItem? {
        guard currentItemIndex < selectedItems.count else { return nil }
        return selectedItems[currentItemIndex]
    }

    var progress: Double {
        return Double(currentItemIndex + 1) / Double(selectedItems.count)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                progressHeader
                currentItemSection
                photoOptionsSection
                actionButtonsSection

                Spacer()
            }
            .navigationTitle("Enhance Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Initialize photos array with original image for all items
            if itemPhotos.isEmpty {
                itemPhotos = Array(repeating: originalImage, count: selectedItems.count)
            }
        }
        .sheet(isPresented: $showingCamera) {
            SaveImageCameraView { capturedImage in
                itemPhotos[currentItemIndex] = capturedImage
                showingCamera = false
            }
        }
    }
}

// MARK: - View Components
private extension BulkPhotoEnhancementView {
    @ViewBuilder
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Enhance Photos")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("\(currentItemIndex + 1) of \(selectedItems.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))

            Text("Add better photos for higher sales")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }

    @ViewBuilder
    private var currentItemSection: some View {
        if let currentItem = currentItem {
            VStack(spacing: 16) {
                Text(currentItem.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack {
                    Text(currentItem.condition)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)

                    Text(currentItem.estimatedValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                // Current photo preview
                if currentItemIndex < itemPhotos.count {
                    Image(uiImage: itemPhotos[currentItemIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                } else {
                    // Fallback to original image while itemPhotos is being initialized
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private var photoOptionsSection: some View {
        VStack(spacing: 16) {
            Text("Photo Options")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button("📷 Take New Photo") {
                    showingCamera = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)

                Button("✓ Use Original Photo") {
                    // Keep current photo (already set to original)
                    moveToNextItem()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
                .font(.subheadline)
            }
            .padding(.horizontal)

            Text("Pro tip: Individual photos get 3x more views")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if currentItemIndex < selectedItems.count - 1 {
                Button("Continue to Next Item") {
                    moveToNextItem()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            } else {
                Button("Save All Items") {
                    saveAllItems()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            }

            Button("Skip Remaining & Save") {
                saveAllItems()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.gray)
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Actions
private extension BulkPhotoEnhancementView {
    private func moveToNextItem() {
        if currentItemIndex < selectedItems.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentItemIndex += 1
            }
        } else {
            // This is the last item, so save all items
            saveAllItems()
        }
    }

    private func saveAllItems() {
        var savedItems: [ScannedItem] = []

        for (index, item) in selectedItems.enumerated() {
            let itemImage = itemPhotos[index]
            let analysis = item.toItemAnalysis()

            let scannedItem = ScannedItem(
                itemName: analysis.itemName,
                category: analysis.category,
                condition: analysis.condition,
                description: analysis.description,
                estimatedValue: analysis.estimatedValue,
                image: itemImage,
                priceAnalysis: createDefaultAnalysis(for: analysis)
            )

            itemStorage.saveItem(scannedItem)
            savedItems.append(scannedItem)
        }

        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator()
        impactFeedback.impactOccurred()

        // Ask user what they want to do next
        showPostSaveOptions(savedItems: savedItems)
    }

    private func showPostSaveOptions(savedItems: [ScannedItem]) {
        let alert = UIAlertController(
            title: "Items Saved!",
            message: "Your \(savedItems.count) items have been saved to your inventory. What would you like to do next?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "List Items Now", style: .default) { _ in
            onItemsSaved(savedItems)
        })

        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { _ in
            onComplete()
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    private func createDefaultAnalysis(for item: ItemAnalysis) -> MarketplacePriceAnalysis {
        let basePrice = extractPrice(from: item.estimatedValue)
        let prices: [Marketplace: Double] = [
            .ebay: basePrice,
            .mercari: basePrice * 0.9,
            .facebook: basePrice * 0.8,
            .stockx: basePrice * 1.2
        ]

        return MarketplacePriceAnalysis(
            recommendedMarketplace: .ebay,
            confidence: .medium,
            averagePrices: prices,
            reasoning: "Bulk analysis result"
        )
    }

    private func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "25") ?? 25.0
    }
}


// MARK: - Camera View
struct SaveImageCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SaveImageCameraView

        init(_ parent: SaveImageCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
        }
    }
}
