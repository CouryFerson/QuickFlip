//
//  ItemDetailView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/21/25.
//

import SwiftUI

struct ItemDetailView: View {
    let item: ScannedItem
    let marketplaceAction: () -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var marketPriceService: eBayMarketPriceService
    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var imageScale: CGFloat = 1.0
    @State private var marketData: MarketPriceData?

    // New state for camera
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?

    init(item: ScannedItem, supabaseService: SupabaseService, marketplaceAction: @escaping () -> Void) {
        self.item = item
        self.marketplaceAction = marketplaceAction
        _marketPriceService = StateObject(wrappedValue: eBayMarketPriceService(supabaseService: supabaseService))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero Image Section with navigation overlay
                    ZStack(alignment: .top) {
                        heroImageSection(width: geometry.size.width)
                        customNavigationOverlay
                    }

                    // Content Section
                    contentSection
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .navigationBarHidden(true)
            .confirmationDialog("Update Status", isPresented: $showingActionSheet, titleVisibility: .visible) {
                Button("Mark as Listed") {
                    // Handle mark as listed
                }
                Button("Mark as Sold") {
                    // Handle mark as sold
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    itemStorage.deleteItem(item)
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this item? This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let imageURL = item.imageUrl {
                    CachedImageView.listItem(imageUrl: imageURL)
                } else {
                    ShareSheet(items: [item.itemName])
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ItemDetailCameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .task {
                marketData = try? await marketPriceService.fetchMarketPrices(for: item.itemName, category: item.category)
            }
            .onChange(of: capturedImage) { newImage in
                if let newImage = newImage {
                    handleNewImage(newImage)
                }
            }
        }
    }

    private func getStatusIcon() -> String {
        // You can extend this based on item status
        return "circle.fill"
    }

    private func getStatusText() -> String {
        // You can extend this based on item status
        return "Update Status"
    }

    private func getStatusColor() -> Color {
        // You can extend this based on item status
        return .green
    }

    private func handleNewImage(_ image: UIImage) {
        // Update the item with the new image
        Task {
            // Here you would typically:
            // 1. Upload the image to your storage
            // 2. Update the item's imageUrl
            // 3. Save the updated item

            // For now, we'll just update the local item
            // You'll need to implement the actual upload logic based on your storage service

            // Example:
            // if let imageUrl = await itemStorage.uploadImage(image) {
            //     var updatedItem = item
            //     updatedItem.imageUrl = imageUrl
            //     itemStorage.updateItem(updatedItem)
            // }
        }

        // Reset the captured image
        capturedImage = nil
    }
}

// MARK: - Private View Components
private extension ItemDetailView {
    @ViewBuilder
    var customNavigationOverlay: some View {
        HStack {
            // Back button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                    )
            }

            Spacer()

            // Camera button
            Button(action: { showingCamera = true }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60) // Adjust for status bar
    }

    @ViewBuilder
    func heroImageSection(width: CGFloat) -> some View {
        ZStack {
            if let imageURL = item.imageUrl {
                CachedImageView.detail(width: width, imageUrl: imageURL)
                    .clipped()
                    .scaleEffect(imageScale)
                    .animation(.easeInOut(duration: 0.3), value: imageScale)
            } else {
                noImagePlaceholder
            }

            // Gradient overlay for better text readability
            imageGradientOverlay
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                imageScale = imageScale == 1.0 ? 1.05 : 1.0
            }
        }
    }

    @ViewBuilder
    var noImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 400)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Image")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
    }

    @ViewBuilder
    var imageGradientOverlay: some View {
        LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.3)],
            startPoint: .center,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    var contentSection: some View {
        VStack(spacing: 0) {
            // Header Info
            headerInfo

            // Description Section
            if !item.description.isEmpty {
                descriptionSection
            }

            if item.itemName != "Unknown Item" {
                chartView
                    .padding(.horizontal, 8)
            }

            // Quick Actions Section
            quickActionsSection
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .offset(y: -24)
    }

    @ViewBuilder
    var headerInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.itemName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 12) {
                        if let categoryName = item.categoryName,
                               !categoryName.isEmpty {
                            CategoryBadge(category: categoryName)
                        }

                        if !item.condition.isEmpty {
                            ConditionBadge(condition: item.condition)
                        }

                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    @ViewBuilder
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            Text(item.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    @ViewBuilder
    var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            deleteButton
            marketplaceButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    @ViewBuilder
    var marketplaceButton: some View {
        Button(action: marketplaceAction) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("List Item")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.bottom, 30)
    }

    @ViewBuilder
    var deleteButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                Text("Delete")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.red)
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    var chartView: some View {
        if marketPriceService.isLoading {
            MarketPriceLoadingView()
        } else if let error = marketPriceService.lastError {
            MarketPriceErrorView(errorMessage: error) {
                Task {
                    marketData = try? await marketPriceService.fetchMarketPrices(for: item.itemName, category: item.category)
                }
            }
        } else if let marketData = marketData {
            MarketPriceChartView(marketData: marketData)
        }
    }
}

// MARK: - Camera View
struct ItemDetailCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ItemDetailCameraView

        init(_ parent: ItemDetailCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
