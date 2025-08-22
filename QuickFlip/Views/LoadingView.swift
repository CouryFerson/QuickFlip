//
//  LoadingView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/21/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var isRotating = false

    var body: some View {
        VStack(spacing: 40) {
            logoWithSpinner
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            isRotating = true
        }
    }
}

private extension LoadingView {
    @ViewBuilder
    private var logoWithSpinner: some View {
        ZStack {
            // Spinning circle border
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8), Color.clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isRotating)

            // App logo (static)
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
