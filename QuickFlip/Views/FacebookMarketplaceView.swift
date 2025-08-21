import SwiftUI

struct FacebookMarketplaceView: View {
    @State private var listing: FacebookListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    @State private var copiedField: String?
    @State private var selectedCategory: String = "Electronics"
    @State private var selectedCondition: String = "Good"
    @State private var isAvailableForShipping = false
    @State private var meetupLocation = ""

    // Facebook Brand Colors
    private let facebookBlue = Color(red: 0.24, green: 0.35, blue: 0.6) // Facebook blue #3A5998
    private let facebookLightBlue = Color(red: 0.26, green: 0.6, blue: 0.99) // Light blue #42A5F5
    private let facebookGray = Color(red: 0.96, green: 0.96, blue: 0.97) // Light gray background
    private let facebookDarkGray = Color(red: 0.18, green: 0.2, blue: 0.22) // Dark text
    private let facebookGreen = Color(red: 0.26, green: 0.73, blue: 0.32) // Success green

    init(listing: FacebookListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Mobile-style listing preview
                listingPreviewCard

                // Form sections with Facebook styling
                VStack(spacing: 16) {
                    photoSection
                    detailsSection
                    locationSection
                    descriptionSection
                    safetyTipsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Action buttons
                actionButtonsSection

                Spacer(minLength: 30)
            }
            .background(facebookGray.ignoresSafeArea())
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(facebookBlue, for: .navigationBar)
            .navigationBarColor(backgroundColor: facebookBlue, titleColor: .white)
        }
    }
}

// MARK: - Navigation Bar Styling Extension
extension View {
    func navigationBarColor(backgroundColor: Color, titleColor: Color) -> some View {
        self.modifier(NavigationBarColorModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
}

struct NavigationBarColorModifier: ViewModifier {
    let backgroundColor: Color
    let titleColor: Color

    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(backgroundColor)
                appearance.titleTextAttributes = [.foregroundColor: UIColor(titleColor)]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(titleColor)]

                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

// MARK: - Listing Preview (Mobile Facebook Style)
private extension FacebookMarketplaceView {
    var listingPreviewCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(facebookDarkGray)

                Spacer()

                Text("How buyers will see your listing")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)

            // Mobile listing card mockup
            VStack(spacing: 0) {
                // Image area
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        // Price overlay like Facebook
                        VStack {
                            Spacer()
                            HStack {
                                Text("$\(String(format: "%.0f", listing.price))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.7))
                                    .cornerRadius(8)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                    )

                // Listing details
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(facebookDarkGray)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text(selectedCondition)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Text("•")
                            .foregroundColor(.gray)

                        Text(selectedCategory)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Text(meetupLocation.isEmpty ? "Local pickup" : meetupLocation)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Spacer()

                        Text("2 min")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    // Seller info mockup
                    HStack {
                        Circle()
                            .fill(facebookBlue.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(facebookBlue)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("You")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(facebookDarkGray)

                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.orange)
                                }
                                Text("New seller")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(12)
                .background(.white)
            }
            .background(.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(facebookGray)
    }
}

// MARK: - Form Sections
private extension FacebookMarketplaceView {
    var photoSection: some View {
        FacebookFormSection(title: "Photos", icon: "camera.fill") {
            VStack(spacing: 12) {
                HStack {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Great photo!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(facebookGreen)

                        Text("Clear, well-lit photos get 3x more responses")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button("Add More") {
                        // Add more photos
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(facebookBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(facebookBlue.opacity(0.1))
                    .cornerRadius(6)
                }

                FacebookTipBox(
                    icon: "lightbulb.fill",
                    text: "Take photos from multiple angles. Show any flaws honestly to build trust with buyers."
                )
            }
        }
    }

    var detailsSection: some View {
        FacebookFormSection(title: "Details", icon: "info.circle.fill") {
            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(facebookDarkGray)

                    TextField("What are you selling?", text: $listing.title)
                        .textFieldStyle(FacebookTextFieldStyle())

                    HStack {
                        Text("\(listing.title.count)/80")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Spacer()

                        CopyButton(text: listing.title, fieldName: "Title", copiedField: $copiedField)
                    }
                }

                // Price
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(facebookDarkGray)

                    HStack {
                        Text("$")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("0", value: $listing.price, format: .number.precision(.fractionLength(0)))
                            .font(.system(size: 18, weight: .medium))
                            .keyboardType(.numberPad)
                            .textFieldStyle(FacebookTextFieldStyle())
                    }

                    Text("💡 Research similar items to price competitively")
                        .font(.system(size: 12))
                        .foregroundColor(facebookBlue)
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(facebookDarkGray)

                    Picker("Category", selection: $selectedCategory) {
                        Text("Electronics").tag("Electronics")
                        Text("Vehicles").tag("Vehicles")
                        Text("Home & Garden").tag("Home & Garden")
                        Text("Clothing & Accessories").tag("Clothing & Accessories")
                        Text("Entertainment").tag("Entertainment")
                        Text("Family").tag("Family")
                        Text("Sports").tag("Sports")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }

                // Condition
                VStack(alignment: .leading, spacing: 8) {
                    Text("Condition")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(facebookDarkGray)

                    Picker("Condition", selection: $selectedCondition) {
                        Text("New").tag("New")
                        Text("Like New").tag("Like New")
                        Text("Good").tag("Good")
                        Text("Fair").tag("Fair")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }

    var locationSection: some View {
        FacebookFormSection(title: "Location & Delivery", icon: "location.fill") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pickup Location")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(facebookDarkGray)

                    TextField("Enter your city or neighborhood", text: $meetupLocation)
                        .textFieldStyle(FacebookTextFieldStyle())

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(facebookGreen)
                            .font(.system(size: 14))

                        Text("Meet in safe, public places")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $isAvailableForShipping) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Available for shipping")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(facebookDarkGray)

                            Text("Reach more buyers by offering shipping")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(FacebookToggleStyle())

                    if isAvailableForShipping {
                        Text("📦 You'll handle packaging and shipping costs")
                            .font(.system(size: 12))
                            .foregroundColor(facebookBlue)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }

    var descriptionSection: some View {
        FacebookFormSection(title: "Description", icon: "text.alignleft") {
            VStack(spacing: 12) {
                TextEditor(text: $listing.description)
                    .frame(height: 120)
                    .padding(12)
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Text("Include key details buyers want to know")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Spacer()

                    CopyButton(text: listing.description, fieldName: "Description", copiedField: $copiedField)
                }

                FacebookTipBox(
                    icon: "star.fill",
                    text: "Mention size, brand, age, reason for selling, and any flaws. Honest descriptions build trust!"
                )
            }
        }
    }

    var safetyTipsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(facebookGreen)
                    .font(.title2)

                Text("Safety Tips")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(facebookDarkGray)

                Spacer()
            }

            VStack(spacing: 8) {
                SafetyTipRow(icon: "person.2.fill", text: "Meet in public places with good lighting")
                SafetyTipRow(icon: "creditcard.fill", text: "Use secure payment methods")
                SafetyTipRow(icon: "exclamationmark.triangle.fill", text: "Trust your instincts - if something feels off, don't proceed")
                SafetyTipRow(icon: "message.fill", text: "Keep communication on Facebook Messenger")
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Primary action - Open Facebook
            Button(action: {
                openFacebookMarketplace()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Post to Marketplace")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Opens Facebook app")
                            .font(.system(size: 12))
                            .opacity(0.9)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("f")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(facebookBlue)
                            .clipShape(Circle())

                        Text("FREE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(facebookBlue)
                    }
                }
                .foregroundColor(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [facebookBlue, facebookLightBlue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)

            // Secondary actions
            HStack(spacing: 12) {
                Button("Copy All Details") {
                    copyAllListingDetails()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(facebookBlue)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(facebookBlue, lineWidth: 1)
                )

                Button("Save Draft") {
                    saveDraft()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(facebookGray)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }
}

// MARK: - Facebook UI Components
struct FacebookFormSection<Content: View>: View {
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
                    .foregroundColor(Color(red: 0.24, green: 0.35, blue: 0.6))
                    .font(.system(size: 16))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.18, green: 0.2, blue: 0.22))

                Spacer()
            }

            content
        }
        .padding(16)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FacebookTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct FacebookToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color(red: 0.24, green: 0.35, blue: 0.6) : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(.white)
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

struct FacebookTipBox: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.26, green: 0.6, blue: 0.99))
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.26, green: 0.6, blue: 0.99).opacity(0.1))
        .cornerRadius(8)
    }
}

struct SafetyTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.26, green: 0.73, blue: 0.32))
                .font(.system(size: 14))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

struct CopyButton: View {
    let text: String
    let fieldName: String
    @Binding var copiedField: String?

    var body: some View {
        Button(action: {
            UIPasteboard.general.string = text
            copiedField = fieldName

            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copiedField = nil
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: copiedField == fieldName ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))

                Text(copiedField == fieldName ? "Copied!" : "Copy")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Color(red: 0.24, green: 0.35, blue: 0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.24, green: 0.35, blue: 0.6).opacity(0.1))
            .cornerRadius(6)
        }
    }
}

// MARK: - Helper Functions
private extension FacebookMarketplaceView {
    func openFacebookMarketplace() {
        let universalListing = UniversalListing(from: listing,
                                                category: selectedCategory,
                                                condition: selectedCondition,
                                                location: meetupLocation,
                                                shipping: isAvailableForShipping)

        MarketplaceIntegrationManager.postToMarketplace(.facebook,
                                                        listing: universalListing,
                                                        image: capturedImage)
    }

    func copyAllListingDetails() {
        let details = """
        FACEBOOK MARKETPLACE LISTING
        
        Title: \(listing.title)
        
        Price: $\(String(format: "%.0f", listing.price))
        
        Category: \(selectedCategory)
        Condition: \(selectedCondition)
        
        Description:
        \(listing.description)
        
        Location: \(meetupLocation.isEmpty ? "Local pickup" : meetupLocation)
        Shipping: \(isAvailableForShipping ? "Available" : "Pickup only")
        """

        UIPasteboard.general.string = details
        copiedField = "All Details"

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedField = nil
        }
    }

    func saveDraft() {
        // Save to UserDefaults
        print("Saving Facebook Marketplace draft...")
    }
}

// MARK: - Models
struct FacebookListing {
    var title: String
    var description: String
    var price: Double
    var category: String

    // Convenience initializer from ItemAnalysis
    init(from scannedItem: ScannedItem, image: UIImage) {
        self.title = FacebookListing.optimizeTitle(scannedItem.itemName)
        self.description = FacebookListing.optimizeDescription(scannedItem.description)
        self.price = FacebookListing.extractPrice(from: scannedItem.estimatedValue)
        self.category = FacebookListing.mapCategory(scannedItem.category)
    }

    private static func optimizeTitle(_ title: String) -> String {
        // Facebook prefers shorter, punchy titles
        return title.count > 80 ? String(title.prefix(77)) + "..." : title
    }

    private static func optimizeDescription(_ description: String) -> String {
        // Add Facebook-friendly elements
        return description.isEmpty ? "Great condition! Message me with any questions." : description
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        let price = Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "25") ?? 25.0
        return max(price, 1.0) // Facebook minimum
    }

    private static func mapCategory(_ category: String) -> String {
        let categoryLower = category.lowercased()

        if categoryLower.contains("electronics") || categoryLower.contains("phone") || categoryLower.contains("computer") {
            return "Electronics"
        } else if categoryLower.contains("clothing") || categoryLower.contains("fashion") {
            return "Clothing & Accessories"
        } else if categoryLower.contains("home") || categoryLower.contains("furniture") {
            return "Home & Garden"
        } else if categoryLower.contains("car") || categoryLower.contains("vehicle") {
            return "Vehicles"
        } else if categoryLower.contains("sport") || categoryLower.contains("fitness") {
            return "Sports"
        } else if categoryLower.contains("baby") || categoryLower.contains("kid") {
            return "Family"
        } else {
            return "Other"
        }
    }
}
