import SwiftUI
import AuthenticationServices
import Supabase

struct AppleSignInView: View {
    let authManager: AuthManager
    let onSignInComplete: () -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?

    // Supabase client - you'll need to add this to your app
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://caozetulkpyyuniwprtd.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhb3pldHVsa3B5eXVuaXdwcnRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NjEyOTMsImV4cCI6MjA3MTIzNzI5M30.sdw4OMWXBl9-DrJX165M0Fz8NXBxSVJ6QQJb_qG11vM"
    )

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon/logo placeholder
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

            // App title and description
            VStack(spacing: 12) {
                Text("Welcome to QuickFlip")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Snap, scan, and sell smarter")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Sign in to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Apple Sign In Button
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1.0)

            if isLoading {
                ProgressView("Signing in...")
                    .progressViewStyle(CircularProgressViewStyle())
            }

            // Feature highlights
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "camera.fill",
                    title: "Instant Price Predictions",
                    description: "Take photos and get instant value estimates"
                )

                FeatureRow(
                    icon: "magnifyingglass.circle.fill",
                    title: "Smart Marketplace Search",
                    description: "Find the best platform for maximum revenue"
                )

                FeatureRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Direct Marketplace Upload",
                    description: "List directly to Amazon, eBay, Etsy & more"
                )

                FeatureRow(
                    icon: "barcode.viewfinder",
                    title: "Bulk Scanning",
                    description: "Scan entire tables of items at once"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    do {
                        try await authManager.signInWithApple(credential: appleIDCredential)
                        isLoading = false
                    } catch {
                        self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                    }
                }
            }
        case .failure(let error):
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }
}

// Preview for SwiftUI canvas
//struct AppleSignInView_Previews: PreviewProvider {
//    static var previews: some View {
//        AppleSignInView {
//            print("Sign in completed!")
//        }
//    }
//}
