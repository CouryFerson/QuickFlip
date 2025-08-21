//
//  MarketplaceIntegrationManager.swift
//  QuickFlip
//
//  Enhanced marketplace integration with photo handling
//

import Foundation
import UIKit
import Photos

// MARK: - Marketplace Integration Manager

class MarketplaceIntegrationManager {

    // MARK: - Photo Save Options
    enum PhotoSaveOption {
        case ask           // Ask user with alert
        case alwaysSave    // Save automatically
        case neverSave     // Don't save, just proceed
        case userChoice    // Let user choose in UI
        case retakePhoto   // Let user take a new photo first
    }

    enum PhotoAction {
        case useExisting
        case takeNew
        case useExistingAndSave
        case takeNewAndSave
    }

    // MARK: - Universal Marketplace Posting with Photo Handling
    static func postToMarketplace(
        _ marketplace: Marketplace,
        listing: UniversalListing,
        image: UIImage,
        savePhotoOption: PhotoSaveOption = .ask
    ) {
        handlePhotoSaving(
            image: image,
            marketplace: marketplace,
            saveOption: savePhotoOption
        ) { photoSaved in
            // Proceed with posting after photo handling
            switch marketplace.integrationLevel {
            case .fullAPI:
                handleAPIPosting(marketplace, listing: listing, image: image)
            case .deepLink:
                handleDeepLinkPosting(marketplace, listing: listing, image: image, photoSaved: photoSaved)
            case .smartClipboard:
                handleSmartClipboardPosting(marketplace, listing: listing, image: image, photoSaved: photoSaved)
            }
        }
    }

    // MARK: - Enhanced Photo Handling with Retake Option
    static func handlePhotoSaving(
        image: UIImage,
        marketplace: Marketplace,
        saveOption: PhotoSaveOption,
        completion: @escaping (Bool) -> Void
    ) {
        switch saveOption {
        case .ask:
            showPhotoSaveDialog(for: marketplace, image: image, completion: completion)
        case .alwaysSave:
            savePhotoToCameraRoll(image: image, marketplace: marketplace, completion: completion)
        case .neverSave:
            completion(false)
        case .userChoice:
            completion(false)
        case .retakePhoto:
            showPhotoActionDialog(for: marketplace, currentImage: image, completion: completion)
        }
    }

    // MARK: - Photo Action Dialog (Use Existing vs Take New)
    static func showPhotoActionDialog(
        for marketplace: Marketplace,
        currentImage: UIImage,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: "📷 Photo for \(marketplace.rawValue)",
            message: "Use your existing scan photo or take a new one specifically for this listing?",
            preferredStyle: .actionSheet
        )

        // Use existing photo options
        alert.addAction(UIAlertAction(title: "💾 Use Current Photo & Save to Camera Roll", style: .default) { _ in
            savePhotoToCameraRoll(image: currentImage, marketplace: marketplace, completion: completion)
        })

        alert.addAction(UIAlertAction(title: "📱 Use Current Photo (Don't Save)", style: .default) { _ in
            completion(false)
        })

        // Take new photo options
        alert.addAction(UIAlertAction(title: "📸 Take New Photo & Save", style: .default) { _ in
            presentCameraForNewPhoto(marketplace: marketplace, saveAfterCapture: true, completion: completion)
        })

        alert.addAction(UIAlertAction(title: "📷 Take New Photo (Don't Save)", style: .default) { _ in
            presentCameraForNewPhoto(marketplace: marketplace, saveAfterCapture: false, completion: completion)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })

        // For iPad
        if let popover = alert.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }

        presentAlert(alert)
    }

    // MARK: - Camera Presentation for New Photos
    static func presentCameraForNewPhoto(
        marketplace: Marketplace,
        saveAfterCapture: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraNotAvailableAlert()
            completion(false)
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = CameraDelegate(
            marketplace: marketplace,
            shouldSave: saveAfterCapture,
            completion: completion
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(imagePicker, animated: true)
        }
    }

    static func showCameraNotAvailableAlert() {
        let alert = UIAlertController(
            title: "Camera Not Available",
            message: "Camera is not available on this device. You can use your existing photo or select one from your photo library.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }

    // MARK: - Simplified Photo Choice Dialog
    static func showSimplePhotoChoiceDialog(
        for marketplace: Marketplace,
        currentImage: UIImage,
        completion: @escaping (PhotoAction) -> Void
    ) {
        let alert = UIAlertController(
            title: "📷 Choose Photo Option",
            message: "How would you like to handle the photo for your \(marketplace.rawValue) listing?",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "💾 Save Current Photo & Post", style: .default) { _ in
            completion(.useExistingAndSave)
        })

        alert.addAction(UIAlertAction(title: "📸 Take New Photo & Save", style: .default) { _ in
            completion(.takeNewAndSave)
        })

        alert.addAction(UIAlertAction(title: "📱 Just Post (No Save)", style: .default) { _ in
            completion(.useExisting)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad
        if let popover = alert.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window.rootViewController?.view
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }

        presentAlert(alert)
    }

    // MARK: - Photo Saving to Camera Roll
    static func savePhotoToCameraRoll(
        image: UIImage,
        marketplace: Marketplace,
        completion: @escaping (Bool) -> Void
    ) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            performPhotoSave(image: image, marketplace: marketplace, completion: completion)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        performPhotoSave(image: image, marketplace: marketplace, completion: completion)
                    } else {
                        showPhotoPermissionDeniedAlert(marketplace: marketplace)
                        completion(false)
                    }
                }
            }

        case .denied, .restricted:
            showPhotoPermissionDeniedAlert(marketplace: marketplace)
            completion(false)

        @unknown default:
            completion(false)
        }
    }

    private static func performPhotoSave(
        image: UIImage,
        marketplace: Marketplace,
        completion: @escaping (Bool) -> Void
    ) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.creationRequestForAsset(from: image)
            request.creationDate = Date()
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    showPhotoSavedSuccess(marketplace: marketplace)
                    completion(true)
                } else {
                    showPhotoSaveError(marketplace: marketplace, error: error)
                    completion(false)
                }
            }
        }
    }

    // MARK: - API Integration Handler
    static func handleAPIPosting(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage) {
        switch marketplace {
        case .ebay:
            print("Posting to eBay via API...")
            // Call your existing eBay posting function

        default:
            handleDeepLinkPosting(marketplace, listing: listing, image: image, photoSaved: false)
        }
    }

    // MARK: - Deep Link Integration Handler
    static func handleDeepLinkPosting(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage, photoSaved: Bool) {
        copyOptimizedListing(for: marketplace, listing: listing)
        showSmartClipboardInstructions(for: marketplace, photoSaved: photoSaved)

        if let appURL = createAppURL(for: marketplace, listing: listing),
           UIApplication.shared.canOpenURL(appURL) {

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIApplication.shared.open(appURL)
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let url = URL(string: marketplace.webCreateURL) {
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - Smart Clipboard Handler
    static func handleSmartClipboardPosting(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage, photoSaved: Bool) {
        copyOptimizedListing(for: marketplace, listing: listing)
        showPostingInstructions(for: marketplace, photoSaved: photoSaved)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let url = URL(string: marketplace.webCreateURL) {
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - URL Creation
    static func createAppURL(for marketplace: Marketplace, listing: UniversalListing) -> URL? {
        guard let scheme = marketplace.appURLScheme else { return nil }

        switch marketplace {
        case .facebook:
            return URL(string: "fb://marketplace/create")
        case .mercari:
            return URL(string: "mercari://sell")
        case .poshmark:
            return URL(string: "poshmark://create")
        case .depop:
            return URL(string: "depop://sell")
        default:
            return URL(string: scheme)
        }
    }

    // MARK: - Optimized Text Generation
    static func copyOptimizedListing(for marketplace: Marketplace, listing: UniversalListing) {
        let optimizedText = createOptimizedText(for: marketplace, listing: listing)
        UIPasteboard.general.string = optimizedText
    }

    static func createOptimizedText(for marketplace: Marketplace, listing: UniversalListing) -> String {
        switch marketplace {
        case .facebook:
            return createFacebookText(listing)
        case .mercari:
            return createMercariText(listing)
        case .poshmark:
            return createPoshmarkText(listing)
        case .depop:
            return createDepopText(listing)
        case .stockx:
            return createStockXText(listing)
        case .etsy:
            return createEtsyText(listing)
        case .amazon:
            return createAmazonText(listing)
        case .ebay:
            return createEbayText(listing)
        }
    }

    // MARK: - Platform-Specific Text Generators

    static func createFacebookText(_ listing: UniversalListing) -> String {
        return """
        💰 \(listing.title)
        
        $\(String(format: "%.0f", listing.price)) • \(listing.condition)
        
        \(listing.description)
        
        📍 \(listing.location)
        \(listing.isShippingAvailable ? "🚚 Shipping available" : "🤝 Local pickup only")
        
        💬 Message me if interested!
        
        #\(listing.category.replacingOccurrences(of: " ", with: ""))
        """
    }

    static func createMercariText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        ✨ Condition: \(listing.condition)
        📦 \(listing.isShippingAvailable ? "Fast shipping available!" : "Local pickup")
        
        💝 Bundle for discounts!
        ⭐ Check out my other items
        
        #\(listing.category) #Mercari
        """
    }

    static func createPoshmarkText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title) 💕
        
        \(listing.description)
        
        ✨ Condition: \(listing.condition)
        💖 From smoke-free home
        📏 Measurements available upon request
        💝 Bundle 2+ items for 15% off!
        📦 Ships same/next day
        
        #poshmark #\(listing.category.lowercased())
        """
    }

    static func createDepopText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title) ✨
        
        \(listing.description)
        
        condition: \(listing.condition.lowercased()) 💫
        \(listing.isShippingAvailable ? "ships worldwide 📦" : "pickup only 📍")
        
        dm for more pics/info 💌
        no returns 🚫
        
        #depop #\(listing.category.lowercased()) #vintage #y2k
        """
    }

    static func createStockXText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        Condition: \(listing.condition)
        Size: [Add size here]
        Authentication: StockX verified
        
        Lowest ask pricing
        Fast shipping with StockX authentication
        
        #StockX #Sneakers #Authentic
        """
    }

    static func createEtsyText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        This unique \(listing.category.lowercased()) is in \(listing.condition.lowercased()) condition.
        
        ✨ Handpicked with care
        📦 Ships within 1-2 business days
        💝 Perfect for gifting
        🌟 Questions? Message me anytime!
        
        #handmade #vintage #unique #\(listing.category.lowercased())
        """
    }

    static func createAmazonText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        Condition: \(listing.condition)
        Fast shipping with Amazon Prime
        Customer satisfaction guaranteed
        
        Professional seller with high ratings
        30-day return policy
        
        Keywords: \(listing.category), \(listing.condition.lowercased())
        """
    }

    static func createEbayText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        Condition: \(listing.condition)
        \(listing.isShippingAvailable ? "Fast & Free Shipping!" : "Local pickup available")
        
        ✅ Same day handling
        ✅ 30-day returns accepted
        ✅ Top rated seller
        
        Check out my other items for combined shipping!
        """
    }

    // MARK: - User Feedback Messages

    static func showSmartClipboardInstructions(for marketplace: Marketplace, photoSaved: Bool) {
        let title = "📋 Ready to Post!"
        let photoMessage = photoSaved
            ? "✅ Photo saved to camera roll\n📱 Select it when adding photos"
            : "📷 You'll need to add photos in \(marketplace.rawValue)"

        let message = """
        ✅ Your optimized listing is copied to clipboard
        📱 \(marketplace.rawValue) will open in 2 seconds
        📝 Just paste the text and add your photos!
        
        \(photoMessage)
        
        Tip: Long-press in text fields to paste
        """

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it! 🚀", style: .default))
        presentAlert(alert)
    }

    static func showPostingInstructions(for marketplace: Marketplace, photoSaved: Bool) {
        let title = "Ready to post to \(marketplace.rawValue)! 🚀"
        let photoMessage = photoSaved
            ? "Your photo is saved to camera roll - select it when adding photos."
            : "You'll need to add photos in \(marketplace.rawValue)."

        let message = "Your optimized listing is copied to clipboard. \(marketplace.rawValue) will open in a moment - just paste and add your photos! \(photoMessage)"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        presentAlert(alert)
    }

    static func showPhotoSaveDialog(
        for marketplace: Marketplace,
        image: UIImage,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: "Save Photo for \(marketplace.rawValue)?",
            message: "\(marketplace.rawValue) can access photos from your camera roll. Save this scan photo so you can easily add it to your listing?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Save Photo", style: .default) { _ in
            savePhotoToCameraRoll(image: image, marketplace: marketplace, completion: completion)
        })

        alert.addAction(UIAlertAction(title: "Skip", style: .cancel) { _ in
            completion(false)
        })

        presentAlert(alert)
    }

    static func showPhotoSavedSuccess(marketplace: Marketplace) {
        let alert = UIAlertController(
            title: "📷 Photo Saved!",
            message: "Your scan photo is now in your camera roll. You can select it when adding photos in \(marketplace.rawValue).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Great!", style: .default))
        presentAlert(alert)
    }

    static func showPhotoPermissionDeniedAlert(marketplace: Marketplace) {
        let alert = UIAlertController(
            title: "Photos Access Needed",
            message: "To save photos for \(marketplace.rawValue), please enable Photos access in Settings > Privacy & Security > Photos > QuickFlip",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        alert.addAction(UIAlertAction(title: "Continue Without Saving", style: .cancel))
        presentAlert(alert)
    }

    static func showPhotoSaveError(marketplace: Marketplace, error: Error?) {
        let alert = UIAlertController(
            title: "Couldn't Save Photo",
            message: "There was an error saving your photo. You can still post to \(marketplace.rawValue) by taking a new photo in the app.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }

    static func showNewPhotoTakenMessage(marketplace: Marketplace) {
        let alert = UIAlertController(
            title: "📸 New Photo Ready!",
            message: "Your new photo is ready to use. You can add it manually when posting to \(marketplace.rawValue).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        presentAlert(alert)
    }

    // MARK: - UI Integration Helper for Custom Buttons
    static func handlePhotoActionChoice(
        action: PhotoAction,
        currentImage: UIImage,
        marketplace: Marketplace,
        listing: UniversalListing,
        completion: @escaping () -> Void
    ) {
        switch action {
        case .useExisting:
            postToMarketplace(marketplace, listing: listing, image: currentImage, savePhotoOption: .neverSave)
            completion()

        case .takeNew:
            presentCameraForNewPhoto(marketplace: marketplace, saveAfterCapture: false) { _ in
                completion()
            }

        case .useExistingAndSave:
            postToMarketplace(marketplace, listing: listing, image: currentImage, savePhotoOption: .alwaysSave)
            completion()

        case .takeNewAndSave:
            presentCameraForNewPhoto(marketplace: marketplace, saveAfterCapture: true) { photoSaved in
                completion()
            }
        }
    }

    private static func presentAlert(_ alert: UIAlertController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Camera Delegate for New Photos
class CameraDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let marketplace: Marketplace
    private let shouldSave: Bool
    private let completion: (Bool) -> Void

    init(marketplace: Marketplace, shouldSave: Bool, completion: @escaping (Bool) -> Void) {
        self.marketplace = marketplace
        self.shouldSave = shouldSave
        self.completion = completion
        super.init()
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                self.completion(false)
                return
            }

            if self.shouldSave {
                MarketplaceIntegrationManager.savePhotoToCameraRoll(
                    image: image,
                    marketplace: self.marketplace
                ) { success in
                    self.completion(success)
                }
            } else {
                MarketplaceIntegrationManager.showNewPhotoTakenMessage(marketplace: self.marketplace)
                self.completion(false)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.completion(false)
        }
    }
}

// MARK: - Universal Listing Model
struct UniversalListing {
    let title: String
    let description: String
    let price: Double
    let category: String
    let condition: String
    let location: String
    let isShippingAvailable: Bool
    let tags: [String]

    // Convert from your existing FacebookListing
    init(from facebookListing: FacebookListing, category: String, condition: String, location: String, shipping: Bool) {
        self.title = facebookListing.title
        self.description = facebookListing.description
        self.price = facebookListing.price
        self.category = category
        self.condition = condition
        self.location = location
        self.isShippingAvailable = shipping
        self.tags = []
    }
}
