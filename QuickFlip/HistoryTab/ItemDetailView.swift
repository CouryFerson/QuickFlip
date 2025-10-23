import SwiftUI

struct ItemDetailView: View {
    @State private var item: ScannedItem
    let marketplaceAction: () -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var marketPriceService: eBayMarketPriceService

    // Supabase service for StockX
    let supabaseService: SupabaseService

    // Action sheets and modals
    @State private var showingStatusActionSheet = false
    @State private var showingMarkAsListedSheet = false
    @State private var showingMarkAsSoldSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingStorageLocationSheet = false
    @State private var showingSubscriptionView = false

    // Camera
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?

    // UI state
    @State private var imageScale: CGFloat = 1.0
    @State private var imageRefreshID = UUID()

    // Market Data State for all marketplaces
    @State private var ebayMarketData: MarketPriceData?
    @State private var stockxMarketData: MarketPriceData?
    @State private var etsyMarketData: MarketPriceData?

    // Loading States
    @State private var isLoadingEbay = false
    @State private var isLoadingStockX = false
    @State private var isLoadingEtsy = false

    // Error tracking
    @State private var ebayLoadFailed = false
    @State private var stockxLoadFailed = false
    @State private var etsyLoadFailed = false

    init(item: ScannedItem, supabaseService: SupabaseService, marketplaceAction: @escaping () -> Void) {
        self._item = State(initialValue: item)
        self.supabaseService = supabaseService
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
            .sheet(isPresented: $showingStorageLocationSheet) {
                StorageLocationSheet(item: item) { location in
                    handleUpdateStorageLocation(location: location)
                }
            }
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
                    .environmentObject(subscriptionManager)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ItemDetailCameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .task {
                // Only load market data for premium users - don't waste API calls!
                if subscriptionManager.hasStarterOrProAccess {
                    loadAllMarketData()
                }
            }
            .onChange(of: capturedImage) { newImage in
                if let newImage = newImage {
                    handleNewImage(newImage)
                }
            }
            .onChange(of: subscriptionManager.hasStarterOrProAccess) { oldValue, newValue in
                // If user just upgraded, load market data
                if newValue && !oldValue {
                    loadAllMarketData()
                }
            }
        }
    }

    // MARK: - Status Update Handlers

    private func handleMarkAsListed(marketplaces: [Marketplace]) {
        Task {
            await itemStorage.markItemAsListed(item: item, on: marketplaces)
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                self.item = updatedItem
            }
        }
    }

    private func handleMarkAsSold(price: Double, marketplace: Marketplace, costBasis: Double?) {
        Task {
            await itemStorage.markItemAsSold(item: item, price: price, marketplace: marketplace, costBasis: costBasis)
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                self.item = updatedItem
            }
        }
    }

    private func handleMarkAsReadyToList() {
        Task {
            await itemStorage.markItemAsReadyToList(item: item)
            if let updatedItem = itemStorage.scannedItems.first(where: { $0.id == item.id }) {
                self.item = updatedItem
            }
        }
    }

    private func handleUpdateStorageLocation(location: String?) {
        Task {
            await itemStorage.updateStorageLocation(for: item, location: location)
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

    // MARK: - Market Data Loading

    private func loadAllMarketData() {
        isLoadingEbay = true
        isLoadingStockX = true
        isLoadingEtsy = true

        Task {
            await fetchEbayDataAsync()
            await fetchStockXDataAsync()
            await fetchEtsyDataAsync()
        }
    }

    private func fetchEbayDataAsync() async {
        do {
            let data = try await marketPriceService.fetchMarketPrices(for: item.itemName, category: item.category)
            await MainActor.run {
                self.ebayMarketData = data
                self.isLoadingEbay = false
                self.ebayLoadFailed = (data == nil)
            }
        } catch {
            await MainActor.run {
                self.ebayMarketData = nil
                self.isLoadingEbay = false
                self.ebayLoadFailed = true
            }
        }
    }

    private func fetchStockXDataAsync() async {
        // StockX uses search card, so no data to fetch
        await MainActor.run {
            self.stockxMarketData = nil
            self.isLoadingStockX = false
            self.stockxLoadFailed = false
        }
    }

    private func fetchEtsyDataAsync() async {
        // Etsy not implemented yet
        await MainActor.run {
            self.etsyMarketData = nil
            self.isLoadingEtsy = false
            self.etsyLoadFailed = false
        }
    }

    private func retryEbayFetch() {
        ebayLoadFailed = false
        isLoadingEbay = true
        Task {
            await fetchEbayDataAsync()
        }
    }

    private func retryStockXFetch() {
        stockxLoadFailed = false
        isLoadingStockX = true
        Task {
            await fetchStockXDataAsync()
        }
    }

    private func retryEtsyFetch() {
        etsyLoadFailed = false
        isLoadingEtsy = true
        Task {
            await fetchEtsyDataAsync()
        }
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
                marketIntelligenceSection
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
                        ListingStatusBadge(status: item.listingStatus.status)
                        Spacer()
                    }
                }
                Spacer()
            }

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
    var marketIntelligenceSection: some View {
        VStack(spacing: 0) {
            sectionHeader

            if subscriptionManager.hasStarterOrProAccess {
                unlockedChartContent
            } else {
                lockedChartContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    @ViewBuilder
    var sectionHeader: some View {
        HStack {
            Label("Market Intelligence", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            Spacer()

            if subscriptionManager.hasStarterOrProAccess {
                unlockedBadge
            } else {
                lockedBadge
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    var unlockedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
            Text("UNLOCKED")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    var lockedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption)
            Text("LOCKED")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    var unlockedChartContent: some View {
        VStack(spacing: 16) {
            // Use SwipeableMarketChartsView for all 3 marketplaces in FULL mode!
            SwipeableMarketChartsView(
                scannedItem: item,
                supabaseService: supabaseService,
                ebayData: ebayMarketData,
                stockxData: stockxMarketData,
                etsyData: etsyMarketData,
                isLoadingEbay: isLoadingEbay,
                isLoadingStockX: isLoadingStockX,
                isLoadingEtsy: isLoadingEtsy,
                ebayLoadFailed: ebayLoadFailed,
                stockxLoadFailed: stockxLoadFailed,
                etsyLoadFailed: etsyLoadFailed,
                recommendedMarketplace: .ebay,
                onRetryEbay: retryEbayFetch,
                onRetryStockX: retryStockXFetch,
                onRetryEtsy: retryEtsyFetch,
                displayMode: .full
            )
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    var lockedChartContent: some View {
        VStack(spacing: 0) {
            lockedPreview
            unlockButton
        }
    }

    @ViewBuilder
    var lockedPreview: some View {
        ZStack {
            // Blurred background with fake swipeable chart preview
            VStack(spacing: 12) {
                // Tab-like preview showing multiple marketplaces
                HStack(spacing: 8) {
                    ForEach([("eBay", Color.blue), ("StockX", Color.green), ("Etsy", Color.orange)], id: \.0) { name, color in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 8)

                // Fake chart card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("eBay")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("24 listings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$127")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("avg price")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Fake chart bars
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<6) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: CGFloat.random(in: 40...120))
                        }
                    }
                    .frame(height: 140)

                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text("Range")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("$80-$180")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 30)

                        VStack(spacing: 2) {
                            Text("Competition")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Moderate")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Fake selling strategy preview
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("Your Selling Strategy")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Suggested List Price")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("$139")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }

                            Spacer()
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .blur(radius: 5)
            .opacity(0.4)

            // Lock overlay
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 6) {
                    Text("Unlock Market Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Access eBay, StockX & Etsy pricing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 40)
        }
        .frame(height: 420)
        .padding(.top, 8)
    }

    @ViewBuilder
    var unlockButton: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.top, 12)

            // Value propositions
            VStack(spacing: 10) {
                valuePropositionRow(icon: "chart.bar.fill", text: "Swipe through eBay, StockX & Etsy data", color: .blue)
                valuePropositionRow(icon: "dollarsign.circle.fill", text: "AI pricing recommendations", color: .green)
                valuePropositionRow(icon: "lightbulb.fill", text: "Selling strategy insights", color: .orange)
            }

            // Unlock button
            Button(action: { showingSubscriptionView = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.open.fill")
                        .font(.headline)

                    Text("Upgrade to Unlock")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    func valuePropositionRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(.green.opacity(0.6))
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
            storageLocationButton
            deleteButton
            marketplaceButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
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
    var storageLocationButton: some View {
        Button(action: { showingStorageLocationSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16, weight: .medium))
                Text(item.storageLocation?.isEmpty == false ? item.storageLocation! : "Set Storage Location")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.purple)
            .clipShape(Capsule())
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

// MARK: - Storage Location Sheet
struct StorageLocationSheet: View {
    let item: ScannedItem
    let onSave: (String?) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var locationText: String
    @State private var recentLocations: [String] = []

    init(item: ScannedItem, onSave: @escaping (String?) -> Void) {
        self.item = item
        self.onSave = onSave
        _locationText = State(initialValue: item.storageLocation ?? "")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Where are you storing this item?")
                        .font(.headline)

                    TextField("e.g., Garage shelf, Closet bin 3", text: $locationText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 8)

                    if !recentLocations.isEmpty {
                        Text("Recent Locations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentLocations, id: \.self) { location in
                                    Button(action: { locationText = location }) {
                                        Text(location)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Storage Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmed.isEmpty ? nil : trimmed)
                        saveToRecentLocations(trimmed)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    if item.storageLocation != nil {
                        Button("Clear") {
                            onSave(nil)
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear {
            loadRecentLocations()
        }
    }

    private func loadRecentLocations() {
        if let saved = UserDefaults.standard.stringArray(forKey: "recentStorageLocations") {
            recentLocations = saved
        }
    }

    private func saveToRecentLocations(_ location: String) {
        guard !location.isEmpty else { return }

        var locations = recentLocations
        // Remove if already exists
        locations.removeAll { $0 == location }
        // Add to front
        locations.insert(location, at: 0)
        // Keep only last 5
        locations = Array(locations.prefix(5))

        recentLocations = locations
        UserDefaults.standard.set(locations, forKey: "recentStorageLocations")
    }
}
