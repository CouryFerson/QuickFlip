//
//  ImageCacheManager.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/6/25.
//
import SwiftUI
import Combine

// MARK: - Image Cache Manager
@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private var supabaseService: SupabaseService?

    @Published private(set) var isPreloading = false
    @Published private(set) var preloadProgress: Double = 0.0

    /// Get cache size information
    var cacheInfo: (memoryCount: Int, diskSizeBytes: Int) {
        let memoryCount = cache.countLimit
        let diskSize = getDiskCacheSize()
        return (memoryCount, diskSize)
    }

    private init() {
        // Set up cache configuration
        cache.countLimit = 100 // Max 100 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit

        // Create cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("ScannedItemImages")

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Interface

    func configure(with service: SupabaseService) {
        self.supabaseService = service
    }

    /// Get image from cache (memory first, then disk, then download)
    func getImage(for url: String) async -> UIImage? {
        let cacheKey = NSString(string: url)

        // 1. Check memory cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        // 2. Check disk cache
        if let diskImage = loadImageFromDisk(url: url) {
            cache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        // 3. Download and cache
        return await downloadAndCacheImage(imagePath: url)
    }

    /// Preload all images for scanned items (call this on app launch)
    func preloadImages(for items: [ScannedItem]) async {
        await MainActor.run {
            isPreloading = true
            preloadProgress = 0.0
        }

        let imagePaths = items.compactMap { $0.imageUrl } 
        let totalCount = imagePaths.count

        guard totalCount > 0 else {
            await MainActor.run {
                isPreloading = false
            }
            return
        }

        for (index, path) in imagePaths.enumerated() {
            // Download image using path (cache manager will generate signed URL internally)
            _ = await getImage(for: path)

            // Update progress
            await MainActor.run {
                preloadProgress = Double(index + 1) / Double(totalCount)
            }
        }

        await MainActor.run {
            isPreloading = false
        }
    }

    /// Clear all cached images
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func loadImageFromDisk(url: String) -> UIImage? {
        let fileName = generateFileName(from: url)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Private Methods

    private func downloadAndCacheImage(imagePath: String) async -> UIImage? {
       guard let service = supabaseService else {
           print("SupabaseService not configured")
           return nil
       }

       do {
           // Generate signed URL from the image path
           let signedUrl = try await service.createSignedUrl(for: imagePath)
           guard let imageUrl = URL(string: signedUrl) else { return nil }

           let (data, _) = try await URLSession.shared.data(from: imageUrl)
           guard let image = UIImage(data: data) else { return nil }

           // Cache in memory (use original path as key, not signed URL)
           let cacheKey = NSString(string: imagePath)
           cache.setObject(image, forKey: cacheKey)

           // Cache on disk
           saveImageToDisk(image: image, url: imagePath)

           return image
       } catch {
           print("Failed to download image from \(imagePath): \(error)")
           return nil
       }
    }

    private func saveImageToDisk(image: UIImage, url: String) {
        let fileName = generateFileName(from: url)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }

    private func generateFileName(from url: String) -> String {
        return url.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
    }

    private func getDiskCacheSize() -> Int {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return files.reduce(0) { total, fileURL in
            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + fileSize
        }
    }
}

// MARK: - Cached Image View Component
struct CachedImageView: View {
    let imageUrl: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    @StateObject private var cacheManager = ImageCacheManager.shared
    @State private var image: UIImage?
    @State private var isLoading = true

    init(
        imageUrl: String?,
        width: CGFloat = 80,
        height: CGFloat = 80,
        cornerRadius: CGFloat = 8
    ) {
        self.imageUrl = imageUrl
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let imageUrl = imageUrl else {
            isLoading = false
            return
        }

        let loadedImage = await cacheManager.getImage(for: imageUrl)

        await MainActor.run {
            self.image = loadedImage
            self.isLoading = false
        }
    }
}

// MARK: - Preloading Progress View
struct ImagePreloadingView: View {
    @StateObject private var cacheManager = ImageCacheManager.shared

    var body: some View {
        if cacheManager.isPreloading {
            VStack(spacing: 12) {
                ProgressView(value: cacheManager.preloadProgress)
                    .progressViewStyle(LinearProgressViewStyle())

                Text("Loading images... \(Int(cacheManager.preloadProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Usage Examples
extension CachedImageView {
    // Convenience initializers for common use cases
    static func thumbnail(imageUrl: String?) -> some View {
        CachedImageView(imageUrl: imageUrl, width: 60, height: 60, cornerRadius: 6)
    }

    static func listItem(imageUrl: String?) -> some View {
        CachedImageView(imageUrl: imageUrl, width: 80, height: 80, cornerRadius: 8)
    }

    static func detail(width: CGFloat, imageUrl: String?) -> some View {
        CachedImageView(imageUrl: imageUrl, width: width, height: 400, cornerRadius: 12)
    }
}
