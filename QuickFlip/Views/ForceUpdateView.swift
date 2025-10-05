//
//  ForceUpdateView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/5/25.
//

import SwiftUI

struct ForceUpdateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Update Required")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button {
                openAppStore()
            } label: {
                Text("Update Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/6751441491") {
            UIApplication.shared.open(url)
        }
    }
}
