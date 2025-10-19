import SwiftUI

// MARK: - StockX Market Search Card
struct StockXMarketSearchCard: View {
    let scannedItem: ScannedItem
    let supabaseService: SupabaseService
    let displayMode: ChartDisplayMode

    @StateObject private var productService: StockXProductService
    @StateObject private var authService: StockXAuthService

    @State private var searchQuery: String
    @State private var selectedProduct: StockXProduct?
    @State private var selectedVariant: StockXVariant?
    @State private var marketData: StockXMarketData?
    @State private var currentStep: SearchStep = .search
    @State private var showingChart = false
    @State private var showingExpandedChart = false
    @State private var showAuthCodeInput = false
    @State private var authCode = ""
    @State private var isExchangingToken = false

    // StockX Theme Colors
    private let bgDark = Color(UIColor.systemBackground)
    private let bgCard = Color(UIColor.secondarySystemBackground)
    private let textPrimary = Color.primary
    private let textSecondary = Color.secondary
    private let accentGreen = Color(red: 0.0, green: 0.8, blue: 0.4)

    init(scannedItem: ScannedItem, supabaseService: SupabaseService, displayMode: ChartDisplayMode = .compact) {
        self.scannedItem = scannedItem
        self.supabaseService = supabaseService
        self.displayMode = displayMode

        let auth = StockXAuthService(supabaseService: supabaseService)
        _authService = StateObject(wrappedValue: auth)
        _productService = StateObject(wrappedValue: StockXProductService(
            supabaseService: supabaseService,
            authService: auth
        ))
        _searchQuery = State(initialValue: scannedItem.itemName)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !authService.isAuthenticated {
                authRequiredView
            } else if showingChart, let product = selectedProduct,
                      let variant = selectedVariant, let market = marketData {
                chartWithBackButton(product: product, variant: variant, market: market)
            } else {
                switch currentStep {
                case .search:
                    searchView
                case .selectVariant:
                    variantSelectionView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgDark)
        .cornerRadius(16)
        .onAppear {
            if authService.isAuthenticated && !searchQuery.isEmpty {
                Task {
                    await productService.searchProducts(query: searchQuery)
                }
            }
        }
        .sheet(isPresented: $showingExpandedChart) {
            if let product = selectedProduct,
               let variant = selectedVariant,
               let market = marketData {
                expandedChartSheet(product: product, variant: variant, market: market)
            }
        }
        .alert("Enter Authorization Code", isPresented: $showAuthCodeInput) {
            TextField("Paste code from StockX", text: $authCode)
                .textInputAutocapitalization(.never)
            Button("Complete Sign In") {
                Task {
                    isExchangingToken = true
                    await authService.exchangeCodeForToken(code: authCode)
                    isExchangingToken = false
                    authCode = ""
                    if authService.isAuthenticated {
                        // Start searching automatically after auth
                        await productService.searchProducts(query: searchQuery)
                    }
                }
            }
            .disabled(authCode.isEmpty || isExchangingToken)
            Button("Cancel") {
                authCode = ""
            }
        } message: {
            Text("After signing in to StockX, copy the authorization code and paste it here.")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if !authService.isAuthenticated && !showAuthCodeInput {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAuthCodeInput = true
                }
            }
        }
    }
}

// MARK: - View Components
private extension StockXMarketSearchCard {

    @ViewBuilder
    var authRequiredView: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(accentGreen)

                Text("Connect StockX")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textPrimary)

                Text("One-time connection to view live market data")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: {
                authService.startAuthentication()
            }) {
                Text("Connect StockX")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accentGreen)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    @ViewBuilder
    var searchView: some View {
        VStack(spacing: 16) {
            searchHeader
            searchBar

            if productService.isLoading {
                loadingView
            } else if !productService.searchResults.isEmpty {
                productResultsList
            } else if !searchQuery.isEmpty {
                emptyStateView
            } else {
                placeholderView
            }

            Spacer()
        }
        .padding(20)
    }

    @ViewBuilder
    var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("StockX Market Data")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(accentGreen)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentGreen.opacity(0.15))
                .cornerRadius(12)
            }

            Text("Search to find your exact product")
                .font(.system(size: 13))
                .foregroundColor(textSecondary)
        }
    }

    @ViewBuilder
    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(textSecondary)

            TextField("Search products...", text: $searchQuery)
                .font(.system(size: 15))
                .foregroundColor(textPrimary)
                .onChange(of: searchQuery) { newValue in
                    Task {
                        await productService.searchProducts(query: newValue)
                    }
                }

            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                    productService.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(textSecondary)
                }
            }
        }
        .padding(12)
        .background(bgCard)
        .cornerRadius(10)
    }

    @ViewBuilder
    var productResultsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(productService.searchResults.prefix(5)) { product in
                    compactProductCard(product)
                        .onTapGesture {
                            selectProduct(product)
                        }
                }
            }
        }
    }

    @ViewBuilder
    func compactProductCard(_ product: StockXProduct) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(bgCard)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textPrimary)
                    .lineLimit(2)

                if !product.colorwayDisplay.isEmpty {
                    Text(product.colorwayDisplay)
                        .font(.system(size: 11))
                        .foregroundColor(textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(textSecondary)
        }
        .padding(12)
        .background(bgCard)
        .cornerRadius(10)
    }

    @ViewBuilder
    var variantSelectionView: some View {
        VStack(spacing: 16) {
            variantHeader

            if productService.isLoading {
                loadingView
            } else if !productService.productVariants.isEmpty {
                variantsList
            } else {
                // No variants - select the product directly
                noVariantsView
            }

            Spacer()
        }
        .padding(20)
        .onAppear {
            if let product = selectedProduct {
                Task {
                    await productService.fetchVariants(for: product.productId)

                    // If no variants exist, auto-select the product
                    if productService.productVariants.isEmpty {
                        // Create a dummy variant for products without sizes
                        let defaultVariant = StockXVariant(
                            productId: product.productId,
                            variantId: product.productId,
                            variantName: "default",
                            variantValue: "One Size",
                            sizeChart: nil,
                            gtins: nil,
                            isFlexEligible: false,
                            isDirectEligible: false
                        )
                        selectVariant(defaultVariant)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var variantHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    currentStep = .search
                    selectedProduct = nil
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                        .foregroundColor(accentGreen)
                }

                Spacer()
            }

            if let product = selectedProduct {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: product.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(bgCard)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textPrimary)
                            .lineLimit(2)

                        if !product.colorwayDisplay.isEmpty {
                            Text(product.colorwayDisplay)
                                .font(.system(size: 12))
                                .foregroundColor(textSecondary)
                        }
                    }
                }
            }

            Text("Select Size")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textPrimary)
        }
    }

    @ViewBuilder
    var variantsList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(productService.productVariants.prefix(8)) { variant in
                    variantCard(variant)
                        .onTapGesture {
                            selectVariant(variant)
                        }
                }
            }
        }
    }

    @ViewBuilder
    func variantCard(_ variant: StockXVariant) -> some View {
        HStack {
            Text("Size \(variant.sizeDisplay)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(textPrimary)

            Text(variant.sizeType.uppercased())
                .font(.system(size: 11))
                .foregroundColor(textSecondary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(textSecondary)
        }
        .padding(14)
        .background(bgCard)
        .cornerRadius(10)
    }

    @ViewBuilder
    func chartWithBackButton(product: StockXProduct, variant: StockXVariant, market: StockXMarketData) -> some View {
        VStack(spacing: 0) {
            // Back button header
            HStack {
                Button(action: {
                    showingChart = false
                    currentStep = .selectVariant
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                        Text("Change Size")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(accentGreen)
                }

                Spacer()

                // Only show expand button in compact mode
                if displayMode == .compact {
                    Button(action: {
                        showingExpandedChart = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 12))
                            Text("View Details")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(accentGreen)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Chart with proper display mode
            ScrollView {
                StockXMarketChartView(
                    product: product,
                    variant: variant,
                    marketData: market,
                    displayMode: displayMode
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Only allow tap to expand in compact mode
                    if displayMode == .compact {
                        showingExpandedChart = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    func expandedChartSheet(product: StockXProduct, variant: StockXVariant, market: StockXMarketData) -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Full chart with all insights
                    StockXMarketChartView(
                        product: product,
                        variant: variant,
                        marketData: market,
                        displayMode: .full
                    )
                    .padding()

                    // List on StockX button
                    listOnStockXButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("StockX Market Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingExpandedChart = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    var listOnStockXButton: some View {
        NavigationLink(destination: StockXUploadView(
            scannedItem: scannedItem,
            capturedImage: UIImage(), // You may need to pass the actual image
            supabaseService: supabaseService
        )) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.headline)

                Text("List on StockX")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(accentGreen)
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(accentGreen)
            Text("Loading...")
                .font(.system(size: 14))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(textSecondary.opacity(0.5))

            Text("No products found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textPrimary)

            Text("Try a different search term")
                .font(.system(size: 13))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(textSecondary.opacity(0.5))

            Text("Search for products")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textPrimary)

            Text("Find exact matches to see live market data")
                .font(.system(size: 13))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    @ViewBuilder
    var noVariantsView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(accentGreen)
            Text("Loading market data...")
                .font(.system(size: 14))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Actions
private extension StockXMarketSearchCard {
    func selectProduct(_ product: StockXProduct) {
        selectedProduct = product
        currentStep = .selectVariant
    }

    func selectVariant(_ variant: StockXVariant) {
        selectedVariant = variant

        guard let product = selectedProduct else { return }

        Task {
            do {
                let data = try await productService.fetchMarketData(
                    productId: product.productId,
                    variantId: variant.variantId
                )
                await MainActor.run {
                    self.marketData = data
                    self.showingChart = true
                }
            } catch {
                print("Error fetching market data: \(error)")
            }
        }
    }
}

// MARK: - Search Steps
enum SearchStep {
    case search
    case selectVariant
}
