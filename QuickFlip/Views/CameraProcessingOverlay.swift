//
//  CameraProcessingOverlay.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/21/25.
//

import SwiftUI

struct CameraProcessingOverlay: View {
    @State private var currentStep = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var opacity: Double = 0.0

    let processingSteps = [
        "Scanning...",
        "Analyzing image...",
        "Getting price...",
        "Almost done..."
    ]

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated scanning circle
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)

                    // Inner rotating ring
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan, .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotationAngle))

                    // Center AI icon
                    Image(systemName: "brain")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(pulseScale * 0.8)
                }

                // Processing text
                VStack(spacing: 8) {
                    Text(processingSteps[currentStep])
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<processingSteps.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentStep ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Fade in
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 1.0
        }

        // Continuous rotation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulsing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }

        // Step through processing stages
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Dont restart the animation
                guard currentStep != processingSteps.count - 1 else { return }
                currentStep = (currentStep + 1) % processingSteps.count
            }
        }
    }
}
