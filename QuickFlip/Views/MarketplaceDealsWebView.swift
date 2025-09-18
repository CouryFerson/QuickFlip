//
//  MarketplaceDealsWebView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/17/25.
//

import SwiftUI

struct MarketplaceDealsWebView: View {
    let marketplaceURL: URL
    let marketplaceName: String

    var body: some View {
        WebViewContainer(
            url: marketplaceURL,
            title: "\(marketplaceName) Deals"
        )
    }
}
