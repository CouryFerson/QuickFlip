//
//  MarketplaceWebView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI
import WebKit

struct MarketplaceWebView: View {
    let marketplace: Marketplace
    let itemName: String
    @State private var isLoading = true
    @State private var webView: WKWebView?

    var body: some View {
        ZStack {
            WebViewRepresentable(
                url: constructSearchURL(),
                isLoading: $isLoading
            )

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)

                    Text("Loading \(marketplace.displayName)...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationTitle(marketplace.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func constructSearchURL() -> URL {
        let cleanItemName = itemName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString: String

        switch marketplace {
        case .ebay:
            urlString = "https://www.ebay.com/sch/i.html?_nkw=\(cleanItemName)"
        case .amazon:
            urlString = "https://www.amazon.com/s?k=\(cleanItemName)"
        case .mercari:
            urlString = "https://www.mercari.com/search/?keyword=\(cleanItemName)"
        case .facebook:
            urlString = "https://www.facebook.com/marketplace/search/?query=\(cleanItemName)"
        case .poshmark:
            urlString = "https://poshmark.com/search?query=\(cleanItemName)"
        case .depop:
            urlString = "https://www.depop.com/search/?q=\(cleanItemName)"
        case .stockx:
            urlString = "https://stockx.com/search?s=\(cleanItemName)"
        case .etsy:
            urlString = "https://www.etsy.com/search?q=\(cleanItemName)"
//        case .grailed:
//            urlString = "https://www.grailed.com/search?query=\(cleanItemName)"
//        case .vinted:
//            urlString = "https://www.vinted.com/catalog?search_text=\(cleanItemName)"
//        case .offerup:
//            urlString = "https://offerup.com/search/?q=\(cleanItemName)"
        }

        return URL(string: urlString) ?? URL(string: marketplace.websiteURL)!
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.navigationDelegate = context.coordinator
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// Extension to provide website URLs and display names for marketplaces
extension Marketplace {
    var websiteURL: String {
        switch self {
        case .ebay:
            return "https://www.ebay.com"
        case .amazon:
            return "https://www.amazon.com"
        case .mercari:
            return "https://www.mercari.com"
        case .facebook:
            return "https://www.facebook.com/marketplace"
        case .poshmark:
            return "https://www.poshmark.com"
        case .depop:
            return "https://www.depop.com"
        case .stockx:
            return "https://stockx.com"
        case .etsy:
            return "https://www.etsy.com"
//        case .grailed:
//            return "https://www.grailed.com"
//        case .vinted:
//            return "https://www.vinted.com"
//        case .offerup:
//            return "https://offerup.com"
        }
    }

    var displayName: String {
        switch self {
        case .ebay:
            return "eBay"
        case .amazon:
            return "Amazon"
        case .mercari:
            return "Mercari"
        case .facebook:
            return "Facebook Marketplace"
        case .poshmark:
            return "Poshmark"
        case .depop:
            return "Depop"
        case .stockx:
            return "StockX"
        case .etsy:
            return "Etsy"
//        case .grailed:
//            return "Grailed"
//        case .vinted:
//            return "Vinted"
//        case .offerup:
//            return "OfferUp"
        }
    }
}
