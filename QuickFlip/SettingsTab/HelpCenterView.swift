//
//  HelpCenterView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/18/25.
//

import SwiftUI

struct HelpCenterView: View {
    @State private var expandedSections: Set<HelpSection> = []
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar

                List {
                    if searchText.isEmpty {
                        ForEach(HelpSection.allCases, id: \.self) { section in
                            helpSectionView(section)
                        }
                    } else {
                        ForEach(filteredQuestions, id: \.id) { question in
                            searchResultView(question)
                        }
                    }

                    contactSupportSection
                }
            }
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - View Components
private extension HelpCenterView {

    @ViewBuilder
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search help topics...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    func helpSectionView(_ section: HelpSection) -> some View {
        let isExpanded = expandedSections.contains(section)

        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                toggleSection(section)
            }) {
                HStack {
                    Image(systemName: section.icon)
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(section.subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(section.questions, id: \.id) { question in
                        questionAnswerView(question)
                    }
                }
                .padding(.leading, 40)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    func questionAnswerView(_ qa: HelpQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(qa.question)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(qa.answer)
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }

    @ViewBuilder
    func searchResultView(_ question: HelpQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(question.answer)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)

            Text(question.section.title)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    var contactSupportSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "envelope.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("Still need help?")
                    .font(.headline)

                Text("Contact our support team and we'll get back to you within 24 hours.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button("Contact Support") {
                    contactSupport()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.vertical, 20)
        }
    }

    var filteredQuestions: [HelpQuestion] {
        guard !searchText.isEmpty else { return [] }

        let allQuestions = HelpSection.allCases.flatMap { $0.questions }
        return allQuestions.filter { question in
            question.question.localizedCaseInsensitiveContains(searchText) ||
            question.answer.localizedCaseInsensitiveContains(searchText) ||
            question.section.title.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Helper Methods
private extension HelpCenterView {

    func toggleSection(_ section: HelpSection) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }

    func contactSupport() {
        if let url = URL(string: "mailto:support@quickflip.app?subject=QuickFlip Support Request") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Data Models
enum HelpSection: CaseIterable {
    case gettingStarted
    case scanning
    case analysis
    case account
    case technical

    var title: String {
        switch self {
        case .gettingStarted:
            return "Getting Started"
        case .scanning:
            return "Scanning Items"
        case .analysis:
            return "Understanding Results"
        case .account:
            return "Account & Billing"
        case .technical:
            return "Technical Support"
        }
    }

    var subtitle: String {
        switch self {
        case .gettingStarted:
            return "Learn the basics of QuickFlip"
        case .scanning:
            return "Camera and scanning issues"
        case .analysis:
            return "Price analysis and marketplace data"
        case .account:
            return "Subscriptions, tokens, and billing"
        case .technical:
            return "App issues and troubleshooting"
        }
    }

    var icon: String {
        switch self {
        case .gettingStarted:
            return "play.circle"
        case .scanning:
            return "camera"
        case .analysis:
            return "chart.bar"
        case .account:
            return "person.circle"
        case .technical:
            return "wrench"
        }
    }

    var questions: [HelpQuestion] {
        switch self {
        case .gettingStarted:
            return [
                HelpQuestion(
                    question: "How do I scan my first item?",
                    answer: "Tap the camera button on the main screen, point your camera at the item, and tap the shutter button. Make sure the item is well-lit and clearly visible.",
                    section: self
                ),
                HelpQuestion(
                    question: "What types of items can I scan?",
                    answer: "QuickFlip works best with retail products that have barcodes or clear brand names. Items like electronics, clothing, shoes, books, and collectibles typically work well.",
                    section: self
                ),
                HelpQuestion(
                    question: "How does the AI analysis work?",
                    answer: "Our AI analyzes your scanned item and searches multiple marketplaces to provide current pricing data, sales history, and profit potential estimates.",
                    section: self
                )
            ]
        case .scanning:
            return [
                HelpQuestion(
                    question: "The camera won't focus on my item",
                    answer: "Make sure you're in good lighting and hold the camera steady. Tap the screen to focus manually, and ensure the item fills most of the camera frame.",
                    section: self
                ),
                HelpQuestion(
                    question: "Barcode scanning isn't working",
                    answer: "Clean your camera lens and make sure the barcode is clearly visible without glare. Some older or damaged barcodes may not scan - try taking a regular photo instead.",
                    section: self
                ),
                HelpQuestion(
                    question: "My photos are coming out blurry",
                    answer: "Hold your phone steady and wait for the camera to focus (you'll see a focus indicator). Use good lighting and avoid scanning in dim environments.",
                    section: self
                )
            ]
        case .analysis:
            return [
                HelpQuestion(
                    question: "How accurate are the price estimates?",
                    answer: "Our AI provides estimates based on current marketplace data, but actual selling prices can vary. Use the estimates as a starting point and consider market conditions.",
                    section: self
                ),
                HelpQuestion(
                    question: "Which marketplaces do you check?",
                    answer: "We analyze pricing data from eBay, Mercari, Facebook Marketplace, StockX, and other major reselling platforms to give you comprehensive market insights.",
                    section: self
                ),
                HelpQuestion(
                    question: "Why do I see different prices for the same item?",
                    answer: "Prices vary based on condition, seller location, demand, and marketplace fees. We show you the range so you can price competitively.",
                    section: self
                )
            ]
        case .account:
            return [
                HelpQuestion(
                    question: "How do tokens work?",
                    answer: "Each AI analysis uses 1 token. Free accounts get 10 tokens per month, while paid plans include more tokens plus additional features.",
                    section: self
                ),
                HelpQuestion(
                    question: "Can I buy more tokens?",
                    answer: "Yes! You can purchase additional token packs anytime from the Subscription page in Settings. Tokens never expire.",
                    section: self
                ),
                HelpQuestion(
                    question: "How do I cancel my subscription?",
                    answer: "Go to Settings > Subscription > Manage Subscription, or cancel directly through your App Store account settings.",
                    section: self
                )
            ]
        case .technical:
            return [
                HelpQuestion(
                    question: "The app is running slowly",
                    answer: "Try closing other apps, restarting QuickFlip, or restarting your phone. Make sure you have the latest version installed from the App Store.",
                    section: self
                ),
                HelpQuestion(
                    question: "My scans aren't saving",
                    answer: "Check that you have a stable internet connection and sufficient storage space. Your scan history syncs to the cloud automatically.",
                    section: self
                ),
                HelpQuestion(
                    question: "I'm not receiving notifications",
                    answer: "Check your notification settings in iOS Settings > QuickFlip > Notifications, and make sure notifications are enabled in the app's settings.",
                    section: self
                )
            ]
        }
    }
}

struct HelpQuestion {
    let id = UUID()
    let question: String
    let answer: String
    let section: HelpSection
}
