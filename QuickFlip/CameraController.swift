//
//  Camera.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import AVFoundation
import SwiftUI

class CameraController: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isAnalyzing = false
    @Published var analysisResult: ItemAnalysis?
    @Published var showPermissionAlert = false
    @Published var lastCapturedImage: UIImage?

    var itemStorage: ItemStorageService?
    private var photoOutput = AVCapturePhotoOutput()

    override init() {
        super.init()
    }

    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }

    private func setupCamera() {
        session.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
            print("QuickFlip: Unable to access back camera")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)

            session.beginConfiguration()
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }

            if session.canAddInput(input) && session.canAddOutput(photoOutput) {
                session.addInput(input)
                session.addOutput(photoOutput)
            }

            session.commitConfiguration()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }

        } catch {
            print("QuickFlip: Error setting up camera: \(error)")
        }
    }

    func capturePhoto() {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        analysisResult = nil

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func captureBulkPhoto(delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

extension CameraController {
    private func analyzeImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                print("QuickFlip: Failed to process image")
            }
            return
        }

        let base64Image = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64Image)"

        let prompt = """
        You are an expert at identifying items for resale on eBay. Analyze this image and provide specific details:

        ITEM: [Exact product name, brand, model if identifiable]
        CONDITION: [New/Like New/Good/Fair/Poor based on visible condition]
        DESCRIPTION: [2-3 sentences suitable for eBay listing]
        VALUE: $[low]-$[high] [estimated resale value range]
        CATEGORY: [Suggested eBay category]

        Be very specific. If it's an Apple TV remote, say "Apple TV Siri Remote (4th generation)" not just "remote". If you can see wear, scratches, or damage, mention it in the condition.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": dataURL
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]

        guard let url = URL(string: OpenAIConfig.apiURL) else {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                print("QuickFlip: Invalid API URL")
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                print("QuickFlip: Failed to encode request: \(error)")
            }
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleOpenAIResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func handleOpenAIResponse(data: Data?, response: URLResponse?, error: Error?) {
        isAnalyzing = false

        if let error = error {
            print("QuickFlip: Network error: \(error.localizedDescription)")
            return
        }

        guard let data = data else {
            print("QuickFlip: No response data")
            return
        }

        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("QuickFlip: Raw API response: \(responseString)")
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {

                print("QuickFlip: OpenAI Analysis Result:\n\(content)")
                analysisResult = parseAnalysisResult(from: content)

            } else {
                print("QuickFlip: Failed to parse OpenAI response")
            }
        } catch {
            print("QuickFlip: JSON parsing error: \(error)")
        }
    }

    private func parseAnalysisResult(from content: String) -> ItemAnalysis {
        let lines = content.components(separatedBy: .newlines)

        var itemName = "Unknown Item"
        var condition = ""
        var description = ""
        var estimatedValue = ""
        var category = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Handle both "ITEM:" and "**ITEM:**" formats
            if trimmedLine.hasPrefix("ITEM:") || trimmedLine.hasPrefix("**ITEM:**") {
                let startIndex = trimmedLine.firstIndex(of: ":") ?? trimmedLine.startIndex
                if startIndex < trimmedLine.endIndex {
                    itemName = String(trimmedLine[trimmedLine.index(after: startIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "**", with: "") // Remove markdown formatting
                }
            } else if trimmedLine.hasPrefix("CONDITION:") || trimmedLine.hasPrefix("**CONDITION:**") {
                let startIndex = trimmedLine.firstIndex(of: ":") ?? trimmedLine.startIndex
                if startIndex < trimmedLine.endIndex {
                    condition = String(trimmedLine[trimmedLine.index(after: startIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "**", with: "")
                }
            } else if trimmedLine.hasPrefix("DESCRIPTION:") || trimmedLine.hasPrefix("**DESCRIPTION:**") {
                let startIndex = trimmedLine.firstIndex(of: ":") ?? trimmedLine.startIndex
                if startIndex < trimmedLine.endIndex {
                    description = String(trimmedLine[trimmedLine.index(after: startIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "**", with: "")
                }
            } else if trimmedLine.hasPrefix("VALUE:") || trimmedLine.hasPrefix("**VALUE:**") {
                let startIndex = trimmedLine.firstIndex(of: ":") ?? trimmedLine.startIndex
                if startIndex < trimmedLine.endIndex {
                    estimatedValue = String(trimmedLine[trimmedLine.index(after: startIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "**", with: "")
                }
            } else if trimmedLine.hasPrefix("CATEGORY:") || trimmedLine.hasPrefix("**CATEGORY:**") {
                let startIndex = trimmedLine.firstIndex(of: ":") ?? trimmedLine.startIndex
                if startIndex < trimmedLine.endIndex {
                    category = String(trimmedLine[trimmedLine.index(after: startIndex)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "**", with: "")
                }
            }
        }

        // Debug: Print what we parsed
        print("QuickFlip: Parsed item name: '\(itemName)'")
        print("QuickFlip: Parsed condition: '\(condition)'")
        print("QuickFlip: Parsed description: '\(description)'")
        print("QuickFlip: Parsed value: '\(estimatedValue)'")

        let analysis = ItemAnalysis(
            itemName: itemName,
            condition: condition,
            description: description,
            estimatedValue: estimatedValue,
            category: category
        )

        // Save immediately after successful analysis
        if let image = lastCapturedImage, let storage = itemStorage {
            saveAnalyzedItem(analysis: analysis, image: image, storage: storage)
        }

        return analysis
    }

    private func saveAnalyzedItem(analysis: ItemAnalysis, image: UIImage, storage: ItemStorageService) {
        let basePrice = extractPrice(from: analysis.estimatedValue)

        // Create safe dictionary without duplicate keys
        let defaultPrices: [Marketplace: Double] = [
            .ebay: basePrice,
            .mercari: basePrice * 0.9,
            .facebook: basePrice * 0.8,
            .amazon: basePrice * 1.1,
            .stockx: basePrice * 1.2
        ]

        let defaultAnalysis = MarketplacePriceAnalysis(
            recommendedMarketplace: .ebay,
            confidence: .medium,
            averagePrices: defaultPrices,
            reasoning: "Initial analysis - tap to select marketplace"
        )

        let scannedItem = ScannedItem(
            itemName: analysis.itemName,
            category: analysis.category,
            condition: analysis.condition,
            description: analysis.description,
            estimatedValue: analysis.estimatedValue,
            image: image,
            priceAnalysis: defaultAnalysis
        )

        storage.saveItem(scannedItem)
        print("QuickFlip: Auto-saved '\(analysis.itemName)' after AI analysis")
    }

    private func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "45") ?? 45.0
    }

    // Helper to get the storage service - you'll need to pass this down
    private func getItemStorage() -> ItemStorageService? {
        // We need to pass the storage service to CameraController
        // For now, return nil and we'll fix the architecture
        return nil
    }
}


// MARK: - Photo Capture Delegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                print("QuickFlip: Failed to capture image")
            }
            return
        }

        // Store the captured image
        DispatchQueue.main.async {
            self.lastCapturedImage = image
        }

        analyzeImage(image)
    }
}
