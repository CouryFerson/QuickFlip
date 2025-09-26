import SwiftUI

struct eBayUploadView: View {
    @State private var listing: EbayListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // eBay Integration - Local instances
    @StateObject private var ebayAuthService: eBayAuthService
    @StateObject private var eBayListing: eBayListingService
    @State private var showingeBayAuth = false
    @State private var eBayListingResponse: eBayListingResponse?
    @State private var showingSuccessAlert = false
    @State private var listingError: String?
    @State private var showAuthCodeInput = false
    @State private var authCode = ""
    @State private var isExchangingToken = false

    // eBay Brand Colors
    private let eBayBlue = Color(red: 0.0, green: 0.4, blue: 0.8)
    private let eBayRed = Color(red: 0.9, green: 0.1, blue: 0.3)
    private let eBayYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    private let eBayGray = Color(red: 0.95, green: 0.95, blue: 0.97)

    init(listing: EbayListing, capturedImage: UIImage) {
        let ebayAuthService = eBayAuthService()
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage

        // Create listing service that gets passed the auth service
        self._eBayListing = StateObject(wrappedValue: eBayListingService(authService: ebayAuthService))
        self._ebayAuthService = StateObject(wrappedValue: ebayAuthService)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // eBay Header
                eBayHeaderView

                // Authentication Status
                authenticationStatusView

                // Item Preview Card
                itemPreviewCard

                // Listing Details Form
                if ebayAuthService.isAuthenticated {
                    listingDetailsForm

                    // Upload Button
                    uploadButton
                }

                Spacer(minLength: 50)
            }
        }
        .background(eBayGray.ignoresSafeArea())
        .navigationTitle("List on eBay")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: eBayLogoView)
        .sheet(isPresented: $showingeBayAuth) {
            eBayAuthenticationSheet
        }
        .sheet(isPresented: $showAuthCodeInput) {
            AuthCodeInputSheet(
                isPresented: $showAuthCodeInput,
                authCode: $authCode,
                isProcessing: $isExchangingToken
            ) { code in
                Task {
                    isExchangingToken = true
                    await ebayAuthService.exchangeCodeForToken(code: code)
                    await MainActor.run {
                        isExchangingToken = false
                        authCode = ""
                        showAuthCodeInput = false
                    }
                }
            }
        }
        .alert("Listed Successfully! 🎉", isPresented: $showingSuccessAlert) {
            Button("View on eBay") {
                if let response = eBayListingResponse,
                   let url = URL(string: response.listingURL) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your item is now live on eBay and ready for buyers!")
        }
        .alert("Upload Failed", isPresented: .init(
            get: { listingError != nil },
            set: { _ in listingError = nil }
        )) {
            Button("Try Again") { }
            Button("Cancel") { }
        } message: {
            Text(listingError ?? "")
        }
    }
}

// MARK: - Custom Auth Code Input Sheet
struct AuthCodeInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var authCode: String
    @Binding var isProcessing: Bool
    let onComplete: (String) -> Void

    private let eBayBlue = Color(red: 0.0, green: 0.4, blue: 0.8)

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(eBayBlue)

                // Title and Instructions
                VStack(spacing: 16) {
                    Text("Enter Authorization Code")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(spacing: 12) {
                        Text("After signing in to eBay, you'll see an 'Authorization Complete' page.")
                        Text("Copy the code from that page and paste it below:")
                    }
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }

                // Input Section
                VStack(spacing: 20) {
                    TextField("Paste authorization code here", text: $authCode)
                        .textFieldStyle(CodeInputTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal)

                    Button(action: {
                        if !authCode.isEmpty {
                            onComplete(authCode)
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isProcessing ? "Connecting..." : "Complete Setup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(authCode.isEmpty || isProcessing ? Color.gray : eBayBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                    .disabled(authCode.isEmpty || isProcessing)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("eBay Authorization")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                    authCode = ""
                }
            )
        }
    }
}

// MARK: - Custom Text Field Style for Code Input
struct CodeInputTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.0, green: 0.4, blue: 0.8).opacity(0.3), lineWidth: 2)
            )
    }
}

// MARK: - eBay Branded Components
private extension eBayUploadView {
    var eBayHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("e")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(eBayRed)
                + Text("B")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(eBayBlue)
                + Text("a")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(eBayYellow)
                + Text("y")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)

                Spacer()
            }

            HStack {
                Text("Ready to sell on the world's marketplace?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }

    var eBayLogoView: some View {
        Text("eBay")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(eBayBlue)
    }

    var authenticationStatusView: some View {
        HStack(spacing: 12) {
            authStatusIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(authStatusTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(authStatusSubtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            authActionButton
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }

    @ViewBuilder
    var authStatusIcon: some View {
        if isExchangingToken {
            ProgressView()
                .scaleEffect(0.8)
                .tint(eBayBlue)
        } else {
            Image(systemName: ebayAuthService.isAuthenticated ? "checkmark.circle.fill" : "person.circle")
                .font(.title2)
                .foregroundColor(ebayAuthService.isAuthenticated ? .green : eBayBlue)
        }
    }

    var authStatusTitle: String {
        if isExchangingToken {
            return "Connecting to eBay..."
        } else if ebayAuthService.isAuthenticated {
            return "Connected to eBay"
        } else {
            return "Sign in to eBay"
        }
    }

    var authStatusSubtitle: String {
        if isExchangingToken {
            return "Please wait..."
        } else if ebayAuthService.isAuthenticated {
            return "Ready to list your item"
        } else {
            return "Connect your account to start selling"
        }
    }

    @ViewBuilder
    var authActionButton: some View {
        if !ebayAuthService.isAuthenticated && !isExchangingToken {
            Button("Sign In") {
                showingeBayAuth = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(eBayBlue)
            .cornerRadius(20)
        } else if ebayAuthService.isAuthenticated {
            Button("Sign Out") {
                ebayAuthService.signOut()
            }
            .font(.caption)
            .foregroundColor(eBayBlue)
        }
    }

    var itemPreviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Item")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("Preview")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }

            HStack(spacing: 16) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text("Condition: \(listing.condition)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("$\(String(format: "%.2f", listing.buyItNowPrice))")
                        .font(.headline)
                        .foregroundColor(eBayBlue)
                        .fontWeight(.bold)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }

    var listingDetailsForm: some View {
        VStack(spacing: 20) {
            // Title Section
            eBayFormSection(title: "Title", icon: "text.cursor") {
                TextField("What are you selling?", text: $listing.title)
                    .textFieldStyle(eBayTextFieldStyle())

                Text("\(listing.title.count)/80 characters")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Price Section
            eBayFormSection(title: "Price", icon: "dollarsign.circle") {
                HStack {
                    Text("$")
                        .font(.headline)
                        .foregroundColor(.gray)

                    TextField("0.00", value: $listing.buyItNowPrice, format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(eBayTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                Text("💡 Research similar items to price competitively")
                    .font(.caption)
                    .foregroundColor(eBayBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Shipping Section
            eBayFormSection(title: "Shipping", icon: "shippingbox") {
                VStack(spacing: 12) {
                    Toggle("Offer free shipping", isOn: .init(
                        get: { listing.shippingCost == 0 },
                        set: { listing.shippingCost = $0 ? 0 : 5.99 }
                    ))
                    .toggleStyle(eBayToggleStyle())

                    if listing.shippingCost > 0 {
                        HStack {
                            Text("Shipping cost: $")
                                .foregroundColor(.gray)

                            TextField("0.00", value: $listing.shippingCost, format: .number.precision(.fractionLength(2)))
                                .textFieldStyle(eBayTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                }
            }

            // Condition Section
            eBayFormSection(title: "Condition", icon: "star") {
                Picker("Item condition", selection: $listing.condition) {
                    Text("New").tag("New")
                    Text("Like New").tag("Like New")
                    Text("Good").tag("Good")
                    Text("Fair").tag("Fair")
                    Text("Poor").tag("Poor")
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Description Section
            eBayFormSection(title: "Description", icon: "text.alignleft") {
                TextEditor(text: $listing.description)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(eBayBlue.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    var uploadButton: some View {
        VStack(spacing: 16) {
            if eBayListing.isUploading {
                VStack(spacing: 12) {
                    ProgressView(value: eBayListing.uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: eBayBlue))
                        .scaleEffect(1.0, anchor: .center)

                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(eBayBlue)

                        Text("Uploading to eBay...")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(Int(eBayListing.uploadProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(eBayBlue)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
            } else {
                Button(action: createeBayListing) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)

                        Text("List on eBay")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("FREE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(eBayBlue)
                    .cornerRadius(12)
                    .shadow(color: eBayBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!canCreateListing)
                .padding(.horizontal)
            }
        }
    }

    var eBayAuthenticationSheet: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // eBay Logo
                Text("e")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(eBayRed)
                + Text("B")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(eBayBlue)
                + Text("a")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(eBayYellow)
                + Text("y")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.green)

                VStack(spacing: 16) {
                    Text("Connect to eBay")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Sign in to your eBay account to start listing items directly from QuickFlip")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button("Continue with eBay") {
                        ebayAuthService.startAuthentication()
                        showingeBayAuth = false
                        // Show auth code input after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showAuthCodeInput = true
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(eBayBlue)
                    .cornerRadius(12)

                    Text("You'll return here after signing in")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("eBay Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingeBayAuth = false
                }
            )
        }
    }
}

// MARK: - Custom eBay Styles (keeping your existing ones)
struct eBayTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.0, green: 0.4, blue: 0.8).opacity(0.3), lineWidth: 1)
            )
    }
}

struct eBayToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color(red: 0.0, green: 0.4, blue: 0.8) : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct eBayFormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.8))

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }

            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// MARK: - Helper Functions
private extension eBayUploadView {
    var canCreateListing: Bool {
        return ebayAuthService.isAuthenticated &&
               !listing.title.isEmpty &&
               listing.buyItNowPrice > 0 &&
               !eBayListing.isUploading
    }

    func createeBayListing() {
        Task {
            do {
                let response = try await eBayListing.createListing(listing)

                await MainActor.run {
                    self.eBayListingResponse = response
                    self.showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.listingError = error.localizedDescription
                }
            }
        }
    }
}
