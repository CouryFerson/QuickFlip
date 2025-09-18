//
//  WebvIew.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/13/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator

        // Load the initial URL only when creating the view
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Remove the URL loading logic here - let the webview handle its own navigation
        // The original code was reloading the initial URL on every view update
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
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

struct WebViewContainer: View {
    let url: URL
    let title: String

    init(url: URL, title: String) {
        self.url = url
        self.title = title
    }

    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @Environment(\.presentationMode) var presentationMode

    private var webView = WebView(url: URL(string: "about:blank")!, isLoading: .constant(false))

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if isLoading {
                progressBar
            }

            // WebView
            webViewSection
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension WebViewContainer {
    @ViewBuilder
    var progressBar: some View {
        ProgressView()
            .progressViewStyle(LinearProgressViewStyle())
            .frame(height: 2)
    }

    @ViewBuilder
    var webViewSection: some View {
        WebView(url: url, isLoading: $isLoading)
    }
}
