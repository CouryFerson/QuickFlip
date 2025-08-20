import SwiftUI

struct EtsyUploadView: View {
    @State private var listing: EtsyListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // Etsy Integration
    @StateObject private var etsyAuth = EtsyAuthService()
    @StateObject private var etsyListing = EtsyListingService(authService: EtsyAuthService())
    @State private var showingEtsyAuth = false
    @State private var etsyListingResponse: EtsyListingResponse?
    @State private var showingSuccessAlert = false
    @State private var listingError: String?
    @State private var showAuthCodeInput = false
    @State private var authCode = ""
    @State private var isExchangingToken = false

    // Etsy Brand Colors & Styling
    private let etsyOrange = Color(red: 1.0, green: 0.345, blue: 0.133) // Etsy's signature orange
    private let etsyWarm = Color(red: 0.98, green: 0.95, blue: 0.90) // Warm cream background
    private let etsyBrown = Color(red: 0.34, green: 0.25, blue: 0.20) // Warm brown
    private let etsyGreen = Color(red: 0.0, green: 0.6, blue: 0.4) // Etsy green

    init(listing: EtsyListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Etsy Header with handcraft vibes
                    etsyHeaderView

                    // Authentication Status
                    authenticationStatusView

                    // Item Preview Card with craft aesthetic
                    itemPreviewCard

                    // Listing Details Form
                    if etsyAuth.isAuthenticated {
                        listingDetailsForm

                        // Upload Button
                        uploadButton
                    }

                    Spacer(minLength: 50)
                }
            }
            .background(etsyWarm.ignoresSafeArea())
            .navigationTitle("List on Etsy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: etsyLogoView
            )
        }
        .sheet(isPresented: $showingEtsyAuth) {
            etsyAuthenticationSheet
        }
        .alert("Listed Successfully! 🎨", isPresented: $showingSuccessAlert) {
            Button("View on Etsy") {
                if let response = etsyListingResponse,
                   let url = URL(string: response.listingURL) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your handcrafted listing is now live on Etsy!")
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
        .alert("Enter Authorization Code", isPresented: $showAuthCodeInput) {
            TextField("Paste code from Etsy", text: $authCode)
                .textInputAutocapitalization(.never)
            Button("Complete Sign In") {
                Task {
                    isExchangingToken = true
                    await etsyAuth.exchangeCodeForToken(code: authCode)
                    isExchangingToken = false
                    authCode = ""
                }
            }
            .disabled(authCode.isEmpty || isExchangingToken)
            Button("Cancel") {
                authCode = ""
            }
        } message: {
            Text("After signing in to Etsy, copy the authorization code from the success page and paste it here.")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if !etsyAuth.isAuthenticated && !showAuthCodeInput {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAuthCodeInput = true
                }
            }
        }
    }
}

// MARK: - Etsy Branded Components
private extension EtsyUploadView {
    var etsyHeaderView: some View {
        VStack(spacing: 16) {
            // Decorative pattern
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .fill(etsyOrange.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            VStack(spacing: 8) {
                Text("Etsy")
                    .font(.custom("Georgia", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(etsyOrange)

                Text("Share your creativity with the world")
                    .font(.subheadline)
                    .foregroundColor(etsyBrown)
                    .italic()
            }

            // Decorative flourish
            HStack {
                Rectangle()
                    .fill(etsyOrange.opacity(0.3))
                    .frame(height: 1)

                Image(systemName: "star.fill")
                    .foregroundColor(etsyOrange)
                    .font(.caption)

                Rectangle()
                    .fill(etsyOrange.opacity(0.3))
                    .frame(height: 1)
            }
            .frame(maxWidth: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: etsyOrange.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }

    var etsyLogoView: some View {
        Text("Etsy")
            .font(.custom("Georgia", size: 16))
            .fontWeight(.bold)
            .foregroundColor(etsyOrange)
    }

    var authenticationStatusView: some View {
        HStack(spacing: 16) {
            // Craft-inspired icon
            ZStack {
                Circle()
                    .fill(etsyAuth.isAuthenticated ? etsyGreen.opacity(0.2) : etsyOrange.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: etsyAuth.isAuthenticated ? "checkmark.circle.fill" : "paintbrush.pointed")
                    .font(.title2)
                    .foregroundColor(etsyAuth.isAuthenticated ? etsyGreen : etsyOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(etsyAuth.isAuthenticated ? "Connected to your shop" : "Connect your Etsy shop")
                    .font(.headline)
                    .foregroundColor(etsyBrown)

                Text(etsyAuth.isAuthenticated ? "Ready to showcase your creation" : "Link your shop to start selling")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if !etsyAuth.isAuthenticated {
                Button("Connect") {
                    showingEtsyAuth = true
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(etsyOrange)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    var itemPreviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Creation")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(etsyBrown)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(etsyOrange)
                    Text("Handpicked")
                        .font(.caption)
                        .foregroundColor(etsyOrange)
                        .italic()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(etsyOrange.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 16) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(etsyOrange.opacity(0.3), lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(etsyBrown)

                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundColor(etsyOrange)
                        Text("$\(String(format: "%.2f", listing.price))")
                            .font(.headline)
                            .foregroundColor(etsyOrange)
                            .fontWeight(.bold)
                    }

                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                        Text("Made with love")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    var listingDetailsForm: some View {
        VStack(spacing: 20) {
            // Title Section
            EtsyFormSection(title: "Title", icon: "textformat") {
                TextField("Describe your beautiful creation...", text: $listing.title)
                    .textFieldStyle(EtsyTextFieldStyle())

                Text("\(listing.title.count)/140 characters")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Price Section
            EtsyFormSection(title: "Price", icon: "dollarsign.circle") {
                HStack {
                    Text("$")
                        .font(.headline)
                        .foregroundColor(.gray)

                    TextField("0.00", value: $listing.price, format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(EtsyTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                Text("💡 Price fairly for your time and materials")
                    .font(.caption)
                    .foregroundColor(etsyOrange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Category Section
            EtsyFormSection(title: "Category", icon: "grid") {
                Picker("What type of item is this?", selection: $listing.category) {
                    Text("Handmade").tag("handmade")
                    Text("Vintage").tag("vintage")
                    Text("Craft Supplies").tag("craft_supplies")
                    Text("Art").tag("art")
                    Text("Home & Living").tag("home_living")
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Tags Section
            EtsyFormSection(title: "Tags", icon: "tag") {
                TextField("vintage, handmade, unique...", text: $listing.tags)
                    .textFieldStyle(EtsyTextFieldStyle())

                Text("Use relevant tags to help buyers discover your item")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Description Section
            EtsyFormSection(title: "Description", icon: "text.alignleft") {
                TextEditor(text: $listing.description)
                    .frame(height: 120)
                    .padding(8)
                    .background(etsyWarm)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(etsyOrange.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    var uploadButton: some View {
        VStack(spacing: 16) {
            if etsyListing.isUploading {
                VStack(spacing: 12) {
                    ProgressView(value: etsyListing.uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: etsyOrange))
                        .scaleEffect(1.0, anchor: .center)

                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(etsyOrange)

                        Text("Creating your listing...")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("\(Int(etsyListing.uploadProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(etsyOrange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
            } else {
                Button(action: createEtsyListing) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("List on Etsy")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Share your creativity")
                                .font(.caption)
                                .opacity(0.9)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                            Text("CRAFT")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [etsyOrange, Color(red: 1.0, green: 0.4, blue: 0.2)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: etsyOrange.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(!canCreateListing)
                .padding(.horizontal)
            }
        }
    }

    var etsyAuthenticationSheet: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // Etsy craft-inspired logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(etsyOrange.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(systemName: "paintbrush.pointed.fill")
                            .font(.system(size: 50))
                            .foregroundColor(etsyOrange)
                    }

                    Text("Etsy")
                        .font(.custom("Georgia", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(etsyOrange)
                }

                VStack(spacing: 16) {
                    Text("Connect Your Shop")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(etsyBrown)

                    Text("Sign in to your Etsy account to start listing your handcrafted items directly from QuickFlip")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button("Continue with Etsy") {
                        etsyAuth.startAuthentication()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(etsyOrange)
                    .cornerRadius(12)

                    Text("Secure authentication via Etsy")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(etsyWarm.ignoresSafeArea())
            .navigationTitle("Etsy Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingEtsyAuth = false
                }
            )
        }
    }
}

// MARK: - Custom Etsy Styles
struct EtsyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(red: 0.98, green: 0.95, blue: 0.90))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 1.0, green: 0.345, blue: 0.133).opacity(0.3), lineWidth: 1)
            )
    }
}

struct EtsyFormSection<Content: View>: View {
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
                    .foregroundColor(Color(red: 1.0, green: 0.345, blue: 0.133))

                Text(title)
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.34, green: 0.25, blue: 0.20))

                Spacer()
            }

            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Helper Functions & Models
private extension EtsyUploadView {
    var canCreateListing: Bool {
        return etsyAuth.isAuthenticated &&
               !listing.title.isEmpty &&
               listing.price > 0 &&
               !etsyListing.isUploading
    }

    func createEtsyListing() {
        Task {
            do {
                let response = try await etsyListing.createListing(listing)

                await MainActor.run {
                    self.etsyListingResponse = response
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
