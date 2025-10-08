import SwiftUI

struct StockXUploadView: View {
    let scannedItem: ScannedItem
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // Services
    @StateObject private var authService: StockXAuthService
    @StateObject private var productService: StockXProductService
    @StateObject private var listingService: StockXListingService

    // State
    @State private var searchQuery: String = ""
    @State private var selectedProduct: StockXProduct?
    @State private var selectedVariant: StockXVariant?
    @State private var marketData: StockXMarketData?
    @State private var askPrice: Double = 0
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage: String?
    @State private var showAuthCodeInput = false
    @State private var authCode = ""
    @State private var isExchangingToken = false

    // UI State
    @State private var currentStep: UploadStep = .authenticate

    // StockX Colors
    private let stockXGreen = Color(red: 0.0, green: 0.7, blue: 0.4)
    private let stockXDarkGreen = Color(red: 0.0, green: 0.55, blue: 0.3)
    private let stockXBlack = Color(red: 0.1, green: 0.1, blue: 0.12)
    private let stockXGray = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let stockXRed = Color(red: 0.9, green: 0.2, blue: 0.2)

    init(scannedItem: ScannedItem, capturedImage: UIImage, supabaseService: SupabaseService) {
        self.scannedItem = scannedItem
        self.capturedImage = capturedImage

        let auth = StockXAuthService(supabaseService: supabaseService)
        _authService = StateObject(wrappedValue: auth)
        _productService = StateObject(wrappedValue: StockXProductService(supabaseService: supabaseService, authService: auth))
        _listingService = StateObject(wrappedValue: StockXListingService(supabaseService: supabaseService, authService: auth))

        // Pre-fill search with AI-detected item name
        _searchQuery = State(initialValue: scannedItem.itemName)
    }

    var body: some View {
        ZStack {
            stockXGray.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    stockXHeader
                    progressIndicator

                    if !authService.isAuthenticated {
                        authenticationView
                    } else {
                        switch currentStep {
                        case .authenticate:
                            EmptyView()
                        case .search:
                            searchStepView
                        case .selectVariant:
                            variantStepView
                        case .setPrice:
                            priceStepView
                        case .confirm:
                            confirmStepView
                        }
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear {
            if authService.isAuthenticated {
                currentStep = .search
                Task {
                    await productService.searchProducts(query: searchQuery)
                }
            }
        }
        .alert("Ask Placed Successfully!", isPresented: $showingSuccessAlert) {
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your item is now listed on StockX. Ship it when it sells!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
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
                        currentStep = .search
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
private extension StockXUploadView {

    var authenticationView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(stockXGreen.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 40))
                        .foregroundColor(stockXGreen)
                }

                Text("Sign in to StockX")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Text("Connect your StockX account to place asks and manage your listings")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: {
                authService.startAuthentication()
            }) {
                HStack {
                    Text("Continue with StockX")
                        .font(.system(size: 16, weight: .semibold))

                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [stockXGreen, stockXDarkGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    var stockXHeader: some View {
        HStack {
            Text("StockX")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(stockXBlack)

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(stockXGreen)
                    .frame(width: 8, height: 8)
                Text("Live Market")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(stockXGreen)
            }
        }
        .padding()
        .background(Color.white)
    }

    var progressIndicator: some View {
        HStack(spacing: 12) {
            ForEach(UploadStep.allCases, id: \.self) { step in
                HStack(spacing: 8) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? stockXGreen : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(step.rawValue + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    if step != .confirm {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? stockXGreen : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
    }

    // MARK: - Step 1: Search
    var searchStepView: some View {
        VStack(spacing: 16) {
            searchHeader
            productSearchBar

            if productService.isLoading {
                loadingView
            } else if !productService.searchResults.isEmpty {
                productResultsList
            } else if !searchQuery.isEmpty {
                emptySearchView
            }
        }
        .padding()
    }

    var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find Your Product")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(stockXBlack)

            Text("Search StockX catalog to find the exact product you're selling")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var productSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search products...", text: $searchQuery)
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
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }

    var productResultsList: some View {
        VStack(spacing: 12) {
            ForEach(productService.searchResults) { product in
                ProductSearchCard(product: product, stockXGreen: stockXGreen)
                    .onTapGesture {
                        selectProduct(product)
                    }
            }
        }
    }

    var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No products found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(40)
    }

    // MARK: - Step 2: Select Variant
    var variantStepView: some View {
        VStack(spacing: 16) {
            if let product = selectedProduct {
                selectedProductHeader(product)
                variantsList
            }
        }
        .padding()
        .onAppear {
            if let product = selectedProduct {
                Task {
                    await productService.fetchVariants(for: product.productId)
                }
            }
        }
    }

    func selectedProductHeader(_ product: StockXProduct) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stockXBlack)

                if !product.colorwayDisplay.isEmpty {
                    Text(product.colorwayDisplay)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Button("Change Product") {
                    currentStep = .search
                    selectedProduct = nil
                    productService.productVariants = []
                }
                .font(.system(size: 12))
                .foregroundColor(stockXGreen)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    var variantsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Size")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(stockXBlack)

            if productService.isLoading {
                loadingView
            } else if !productService.productVariants.isEmpty {
                ForEach(productService.productVariants) { variant in
                    VariantCard(variant: variant, stockXGreen: stockXGreen)
                        .onTapGesture {
                            selectVariant(variant)
                        }
                }
            }
        }
    }

    // MARK: - Step 3: Set Price
    var priceStepView: some View {
        VStack(spacing: 16) {
            if let variant = selectedVariant, let market = marketData {
                marketDataCard(market)
                priceInputCard(market)
                continueButton
            }
        }
        .padding()
        .onAppear {
            if let product = selectedProduct, let variant = selectedVariant {
                Task {
                    do {
                        let data = try await productService.fetchMarketData(
                            productId: product.productId,
                            variantId: variant.variantId
                        )
                        await MainActor.run {
                            self.marketData = data
                            self.askPrice = data.earnMore
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                        showingErrorAlert = true
                    }
                }
            }
        }
    }

    func marketDataCard(_ market: StockXMarketData) -> some View {
        VStack(spacing: 12) {
            Text("Market Data")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(stockXBlack)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                MarketStatCard(title: "Lowest Ask", value: market.lowestAsk, color: stockXRed)
                MarketStatCard(title: "Highest Bid", value: market.highestBid, color: stockXGreen)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    func priceInputCard(_ market: StockXMarketData) -> some View {
        VStack(spacing: 16) {
            Text("Set Your Ask")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(stockXBlack)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("$")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(stockXBlack)

                TextField("0", value: $askPrice, format: .number)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(stockXBlack)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(stockXGray)
            .cornerRadius(8)

            // Quick price options
            HStack(spacing: 8) {
                QuickPriceButton(title: "Sell Faster", price: market.sellFaster, askPrice: $askPrice)
                QuickPriceButton(title: "Earn More", price: market.earnMore, askPrice: $askPrice)
            }

            // Price validation
            if askPrice > 0 {
                let validation = listingService.validateAskPrice(askPrice, against: market)
                PriceValidationBanner(validation: validation, stockXGreen: stockXGreen)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    var continueButton: some View {
        Button(action: placeAsk) {
            HStack {
                if listingService.isCreatingAsk {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Place Ask")
                        .font(.system(size: 18, weight: .semibold))

                    Image(systemName: "arrow.right")
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [stockXGreen, stockXDarkGreen],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(askPrice <= 0 || listingService.isCreatingAsk)
    }

    var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(stockXGreen)
            Text("Loading...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(40)
    }

    // MARK: - Step 4: Confirm
    var confirmStepView: some View {
        Text("Confirmation")
    }
}

// MARK: - Actions
private extension StockXUploadView {
    func selectProduct(_ product: StockXProduct) {
        selectedProduct = product
        currentStep = .selectVariant
    }

    func selectVariant(_ variant: StockXVariant) {
        selectedVariant = variant
        currentStep = .setPrice
    }

    func placeAsk() {
        guard let variant = selectedVariant else { return }

        Task {
            do {
                let response = try await listingService.placeAsk(
                    variantId: variant.variantId,
                    askPrice: askPrice
                )

                await MainActor.run {
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ProductSearchCard: View {
    let product: StockXProduct
    let stockXGreen: Color

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))
                    .lineLimit(2)

                if !product.colorwayDisplay.isEmpty {
                    Text(product.colorwayDisplay)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(stockXGreen)
                    Text("Verified")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(stockXGreen)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct VariantCard: View {
    let variant: StockXVariant
    let stockXGreen: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Size \(variant.sizeDisplay)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))

                Text(variant.sizeType.uppercased())
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct MarketStatCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Text("$\(String(format: "%.0f", value))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct QuickPriceButton: View {
    let title: String
    let price: Double
    @Binding var askPrice: Double

    var body: some View {
        Button(action: { askPrice = price }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text("$\(String(format: "%.0f", price))")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.0, green: 0.7, blue: 0.4).opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct PriceValidationBanner: View {
    let validation: PriceValidation
    let stockXGreen: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(validation.isValid ? stockXGreen : .orange)

            Text(validation.message)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(12)
        .background((validation.isValid ? stockXGreen : Color.orange).opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Upload Steps
enum UploadStep: Int, CaseIterable {
    case authenticate = 0
    case search = 1
    case selectVariant = 2
    case setPrice = 3
    case confirm = 4
}
