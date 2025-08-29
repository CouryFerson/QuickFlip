import AVFoundation
import SwiftUI

class CameraController: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isAnalyzing = false
    @Published var scannedItem: ScannedItem?
    @Published var showPermissionAlert = false
    @Published var lastCapturedImage: UIImage?
    @Published var isBarcodeAnalyzing = false
    @Published var barcodeScannedItem: ScannedItem?
    @Published var isFocusing = false
    @Published var focusScreenLocation: CGPoint?

    var itemStorage: ItemStorageService?
    private var photoOutput = AVCapturePhotoOutput()
    private var singlePhotoDelegate: SinglePhotoDelegate?
    private var barcodeCaptureDelegate: BarcodeCaptureDelegate?

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
            try backCamera.lockForConfiguration()

            if backCamera.isFocusModeSupported(.continuousAutoFocus) {
                backCamera.focusMode = .continuousAutoFocus
                print("Set focus mode to: \(backCamera.focusMode.rawValue)")
            }

            backCamera.unlockForConfiguration()

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

    func focusAt(point: CGPoint, screenLocation: CGPoint) {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else { return }

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            try backCamera.lockForConfiguration()

            DispatchQueue.main.async {
                self.isFocusing = true
                self.focusScreenLocation = screenLocation
            }

            if backCamera.isFocusPointOfInterestSupported {
                backCamera.focusPointOfInterest = point
                backCamera.focusMode = .autoFocus

                print("QuickFlip: Tap at screen: \(screenLocation), camera point: \(point)")

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    self.checkFocusCompletion(device: backCamera, startTime: startTime)
                }
            }

            backCamera.unlockForConfiguration()

        } catch {
            print("QuickFlip: Error focusing: \(error)")
            DispatchQueue.main.async {
                self.isFocusing = false
                self.focusScreenLocation = nil
            }
        }
    }

    private func checkFocusCompletion(device: AVCaptureDevice, startTime: CFAbsoluteTime) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let focusTime = CFAbsoluteTimeGetCurrent() - startTime
            print("QuickFlip: Focus completed in approximately \(String(format: "%.2f", focusTime)) seconds")

            DispatchQueue.main.async {
                self.isFocusing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.focusScreenLocation = nil
                }
            }
        }
    }

    func capturePhoto(analysisService: ImageAnalysisService) {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        scannedItem = nil

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        singlePhotoDelegate = SinglePhotoDelegate(controller: self, analysisService: analysisService)
        photoOutput.capturePhoto(with: settings, delegate: singlePhotoDelegate!)
    }

    func captureBulkPhoto(delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    func captureBarcodePhoto(analysisService: ImageAnalysisService) {
        print("QuickFlip: captureBarcodePhoto() called")
        guard !isBarcodeAnalyzing else {
            print("QuickFlip: Already analyzing, returning")
            return
        }

        print("QuickFlip: Starting barcode analysis")
        isBarcodeAnalyzing = true
        barcodeScannedItem = nil

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        barcodeCaptureDelegate = BarcodeCaptureDelegate(controller: self, analysisService: analysisService)
        print("QuickFlip: About to capture photo with delegate")
        photoOutput.capturePhoto(with: settings, delegate: barcodeCaptureDelegate!)
    }

    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Photo Delegates

class SinglePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    weak var controller: CameraController?
    let analysisService: ImageAnalysisService

    init(controller: CameraController, analysisService: ImageAnalysisService) {
        self.controller = controller
        self.analysisService = analysisService
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {

        guard let controller = controller else { return }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                controller.isAnalyzing = false
                print("QuickFlip: Failed to capture image")
            }
            return
        }

        // Store the captured image
        DispatchQueue.main.async {
            controller.lastCapturedImage = image
        }

        // Analyze using the new service
        Task {
            await controller.analyzeImage(image, with: analysisService)
        }
    }
}

class BarcodeCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    weak var controller: CameraController?
    let analysisService: ImageAnalysisService

    init(controller: CameraController, analysisService: ImageAnalysisService) {
        self.controller = controller
        self.analysisService = analysisService
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        print("QuickFlip: BarcodeCaptureDelegate photoOutput called")

        guard let controller = controller else { return }

        if let error = error {
            DispatchQueue.main.async {
                controller.isBarcodeAnalyzing = false
                print("QuickFlip: Barcode capture error: \(error)")
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                controller.isBarcodeAnalyzing = false
                print("QuickFlip: Failed to capture barcode image")
            }
            return
        }

        // Store the captured image
        DispatchQueue.main.async {
            controller.lastCapturedImage = image
        }

        // Analyze using the new service
        Task {
            await controller.analyzeBarcodeImage(image, with: analysisService)
        }
    }
}

// MARK: - Analysis Methods

extension CameraController {

    @MainActor
    func analyzeImage(_ image: UIImage, with analysisService: ImageAnalysisService) async {
        do {
            let analysis = try await analysisService.analyzeSingleItem(image)

            guard let storage = itemStorage else {
                print("QuickFlip: No item storage available")
                isAnalyzing = false
                return
            }

            let scannedItem = convertAnalysisToScannedImage(analysis: analysis, image: image)
            saveAnalyzedItem(scannedItem: scannedItem, storage: storage)
            self.scannedItem = scannedItem
            isAnalyzing = false

        } catch NetworkError.insufficientTokens(let required) {
            isAnalyzing = false
            print("QuickFlip: Need \(required) tokens for analysis")
        } catch {
            isAnalyzing = false
            print("QuickFlip: Analysis failed: \(error)")
        }
    }

    @MainActor
    func analyzeBarcodeImage(_ image: UIImage, with analysisService: ImageAnalysisService) async {
        do {
            let analysis = try await analysisService.analyzeBarcode(image)

            guard let storage = itemStorage else {
                print("QuickFlip: No item storage available")
                isBarcodeAnalyzing = false
                return
            }

            let scannedItem = convertAnalysisToScannedImage(analysis: analysis, image: image)
            saveAnalyzedItem(scannedItem: scannedItem, storage: storage)
            self.barcodeScannedItem = scannedItem
            isBarcodeAnalyzing = false

        } catch NetworkError.insufficientTokens(let required) {
            isBarcodeAnalyzing = false
            print("QuickFlip: Need \(required) tokens for barcode analysis")
        } catch {
            isBarcodeAnalyzing = false
            print("QuickFlip: Barcode analysis failed: \(error)")
        }
    }

    private func convertAnalysisToScannedImage(analysis: ItemAnalysis, image: UIImage) -> ScannedItem {
        let basePrice = extractPrice(from: analysis.estimatedValue)

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

        return ScannedItem(
            itemName: analysis.itemName,
            category: analysis.category,
            condition: analysis.condition,
            description: analysis.description,
            estimatedValue: analysis.estimatedValue,
            image: image,
            priceAnalysis: defaultAnalysis
        )
    }

    private func saveAnalyzedItem(scannedItem: ScannedItem, storage: ItemStorageService) {
        Task { @MainActor in
            storage.saveItem(scannedItem)
            print("QuickFlip: Auto-saved '\(scannedItem.itemName)' after AI analysis")
        }
    }

    private func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "45") ?? 45.0
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resize(maxDimension: CGFloat = 800) -> UIImage {
        let size = size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 { return self }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
