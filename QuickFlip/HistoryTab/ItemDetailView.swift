import SwiftUI

struct ItemDetailView: View {
    @State private var item: ScannedItem
    let marketplaceAction: () -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var marketPriceService: eBayMarketPriceService

    // Action sheets and modals
    @State private var showingStatusActionSheet = false
    @State private var showingMarkAsListedSheet = false
    @State private var showingMarkAsSoldSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false

    // Camera
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?

    // UI state
    @State private var imageScale: CGFloat = 1.0
    @State private var marketData: MarketPriceData?
    @State private var imageRefreshID = UUID()

    init(item: ScannedItem, supabaseService: SupabaseService, marketplaceAction: @escaping () -> Void) {
        self._item = State(initialValue: item)
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
            .confirmationDialog("Update Status", isPresented: $showingStatusActionSheet, titleVisibility: .visible) {
                statusActionSheetButtons
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                deleteAlertButtons
            } message: {
                Text("Are you sure you want to delete this item? This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                shareSheet
            }
            .sheet(isPresented: $showingMarkAsListedSheet) {
                MarkAsListedSheet(item: item) { marketplaces in
                    handleMarkAsListed(marketplaces: marketplaces)
                }
            }
            .sheet(isPresented: $showingMarkAsSoldSheet) {
                MarkAsSoldSheet(item: item) { price, marketplace, costBasis in
                    handleMarkAsSold(price: price, marketplace: marketplace, costBasis: costBasis)
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

    // MARK: - Status Update Handlers

    private func handleMarkAsListed(marketplaces: [Marketplace]) {
        Task {
            await itemStorage.markItemAsListed(item: item, on: marketplaces)
            // Update local item state
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                self.item = updatedItem
            }
        }
    }

    private func handleMarkAsSold(price: Double, marketplace: Marketplace, costBasis: Double?) {
        Task {
            await itemStorage.markItemAsSold(item: item, price: price, marketplace: marketplace, costBasis: costBasis)
            // Update local item state
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                self.item = updatedItem
            }
        }
    }

    private func handleMarkAsReadyToList() {
        Task {
            await itemStorage.markItemAsReadyToList(item: item)
            // Update local item state
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                self.item = updatedItem
            }
        }
    }

    private func handleNewImage(_ image: UIImage) {
        Task {
            await itemStorage.updateItemImage(for: item, newImage: image)
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                await MainActor.run {
                    self.item = updatedItem
                    self.imageRefreshID = UUID()
                }
            }
        }
        capturedImage = nil
    }
}

// MARK: - Private View Components
private extension ItemDetailView {
    @ViewBuilder
    var customNavigationOverlay: some View {
        HStack {
            backButton
            Spacer()
            cameraButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    @ViewBuilder
    var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.regularMaterial))
        }
    }

    @ViewBuilder
    var cameraButton: some View {
        Button(action: { showingCamera = true }) {
            Image(systemName: "camera.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.regularMaterial))
        }
    }

    @ViewBuilder
    func heroImageSection(width: CGFloat) -> some View {
        ZStack {
            if let imageURL = item.imageUrl {
                CachedImageView.detail(width: width, imageUrl: imageURL)
                    .id(imageRefreshID)
                    .clipped()
                    .scaleEffect(imageScale)
                    .animation(.easeInOut(duration: 0.3), value: imageScale)
            } else {
                noImagePlaceholder
            }
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
            headerInfo
            descriptionSection

            if item.itemName != "Unknown Item" {
                chartView.padding(.horizontal, 8)
            }

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
                        if let categoryName = item.categoryName, !categoryName.isEmpty {
                            CategoryBadge(category: categoryName)
                        }
                        if !item.condition.isEmpty {
                            ConditionBadge(condition: item.condition)
                        }
                        // Status Badge
                        ListingStatusBadge(status: item.listingStatus.status)
                        Spacer()
                    }
                }
                Spacer()
            }

            // Show sold details if applicable
            if item.listingStatus.status == .sold {
                soldDetailsCard
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    @ViewBuilder
    var soldDetailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sold Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if let soldPrice = item.listingStatus.formattedSoldPrice {
                HStack {
                    Text("Sale Price:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(soldPrice)
                        .fontWeight(.semibold)
                }
            }

            if let marketplace = item.listingStatus.getSoldMarketplaceAsEnum() {
                HStack {
                    Text("Marketplace:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(marketplace.rawValue)
                        .fontWeight(.medium)
                }
            }

            if let profit = item.listingStatus.formattedNetProfit {
                HStack {
                    Text("Net Profit:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(profit)
                        .fontWeight(.semibold)
                        .foregroundColor(item.listingStatus.profitColor)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    var descriptionSection: some View {
        if !item.description.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
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
            updateStatusButton
            deleteButton
            marketplaceButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    @ViewBuilder
    var updateStatusButton: some View {
        Button(action: { showingStatusActionSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: item.listingStatus.status.iconName)
                    .font(.system(size: 18, weight: .semibold))
                Text("Update Status")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [item.listingStatus.status.displayColor, item.listingStatus.status.displayColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: item.listingStatus.status.displayColor.opacity(0.3), radius: 10, x: 0, y: 5)
        }
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

    // MARK: - Action Sheet and Alert Content

    @ViewBuilder
    var statusActionSheetButtons: some View {
        Group {
            if item.listingStatus.status != .listed {
                Button("Mark as Listed") {
                    showingMarkAsListedSheet = true
                }
            }

            if item.listingStatus.status != .sold {
                Button("Mark as Sold") {
                    showingMarkAsSoldSheet = true
                }
            }

            if item.listingStatus.status != .readyToList {
                Button("Mark as Ready to List") {
                    handleMarkAsReadyToList()
                }
            }

            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder
    var deleteAlertButtons: some View {
        Group {
            Button("Delete", role: .destructive) {
                itemStorage.deleteItem(item)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder
    var shareSheet: some View {
        if let imageURL = item.imageUrl {
            CachedImageView.listItem(imageUrl: imageURL)
        } else {
            ShareSheet(items: [item.itemName])
        }
    }
}

// MARK: - Camera View (unchanged)
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
