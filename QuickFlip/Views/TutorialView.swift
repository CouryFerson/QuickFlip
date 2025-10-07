import SwiftUI

// MARK: - Tutorial Manager
class TutorialManager: ObservableObject {
    @AppStorage("hasSeenTutorial") var hasSeenTutorial = false

    func markTutorialAsSeen() {
        hasSeenTutorial = true
    }

    func resetTutorial() {
        hasSeenTutorial = false
    }
}

// MARK: - Tutorial Page Model
struct TutorialPage: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let description: String
}

// MARK: - Tutorial View
struct TutorialView: View {
    @StateObject private var manager = TutorialManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages = [
        TutorialPage(
            iconName: "photo.on.rectangle.angled",
            title: "Welcome to QuikFlip",
            description: "Take photos of items you want to sell and let AI find the perfect marketplace for you"
        ),
        TutorialPage(
            iconName: "camera.fill",
            title: "Capture Your Item",
            description: "Simply take a photo or choose from your library. Our AI works best with clear, well-lit photos"
        ),
        TutorialPage(
            iconName: "sparkles",
            title: "AI Analysis",
            description: "Our intelligent system analyzes your item and determines which marketplace will get you the best results"
        ),
        TutorialPage(
            iconName: "gift.fill",
            title: "10 Free Tokens!",
            description: "You've got 10 free tokens to start! Tokens power your AI analysis and marketplace recommendations. Subscribe or buy more to keep going."
        ),
        TutorialPage(
            iconName: "bag.fill",
            title: "Get Recommendations",
            description: "Receive personalized suggestions for eBay, Poshmark, Facebook Marketplace, and more"
        ),
        TutorialPage(
            iconName: "arrow.right.circle.fill",
            title: "Ready to Start!",
            description: "You're all set! Start photographing items and discover the best places to sell them"
        )
    ]

    var body: some View {
        ZStack {
            backgroundGradient

            VStack {
                skipButton

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        TutorialPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                nextButton
            }
            .padding()
        }
    }
}

// MARK: - Tutorial View Components
private extension TutorialView {
    var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var skipButton: some View {
        HStack {
            Spacer()
            if currentPage < pages.count - 1 {
                Button(action: handleComplete) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                }
            }
        }
    }

    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                    .frame(width: index == currentPage ? 32 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
        .padding(.bottom, 20)
    }

    var nextButton: some View {
        Button(action: handleNext) {
            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
        }
        .padding(.horizontal)
    }

    func handleNext() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            handleComplete()
        }
    }

    func handleComplete() {
        manager.markTutorialAsSeen()
        onComplete()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Tutorial Page View
struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: 24) {
            iconView
            titleView
            descriptionView
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Tutorial Page View Components
private extension TutorialPageView {
    var iconView: some View {
        Image(systemName: page.iconName)
            .font(.system(size: 80))
            .foregroundColor(.white)
            .frame(height: 120)
    }

    var titleView: some View {
        Text(page.title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }

    var descriptionView: some View {
        Text(page.description)
            .font(.title3)
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

// MARK: - App Integration Example
struct ContentView: View {
    @StateObject private var tutorialManager = TutorialManager()

    var body: some View {
        ZStack {
            mainAppView

            if !tutorialManager.hasSeenTutorial {
                TutorialView {
                    // Tutorial completed
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - ContentView Components
private extension ContentView {
    var mainAppView: some View {
        VStack(spacing: 20) {
            Text("Main App Screen")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Tutorial completed! This is where your main app would be.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Button("Show Tutorial Again") {
                tutorialManager.resetTutorial()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
