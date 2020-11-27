import UIKit
import Foundation

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}

struct StickerImageParams: Hashable, CustomDebugStringConvertible {
    let imageURL: URL
    let pointSize: CGSize
    let scale: CGFloat

    init(imageURL: URL, pointSize: CGSize, scale: CGFloat) {
        self.imageURL = imageURL
        self.pointSize = pointSize
        self.scale = scale
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.imageURL.path)
        hasher.combine(self.pointSize)
        hasher.combine(self.scale)
    }

    var debugDescription: String {
        return "\(self.imageURL.relativePath) @ \(self.pointSize) \(self.scale)x"
    }
}

class StickerImageLoader {
    private let decodeQueue = DispatchQueue(
        label: "com.crossbowffs.stickerboard.decodequeue",
        qos: .userInitiated
    )
    private var cache = Cache<StickerImageParams, UIImage>()
    private var callbacks = [StickerImageParams: [(UIImage) -> Void]]()

    /**
     * Loads the specified image, downsampling it to the given size for use
     * as a thumbnail. Calls the given callback immediately if the image of
     * the given size is already in the cache; otherwise, asynchronously loads
     * the image and calls the callback once the image is ready.
     */
    func loadAsync(
        params: StickerImageParams,
        callback: ((UIImage) -> Void)? = nil
    ) {
        if let image = self.cache[params] {
            callback?(image)
            return
        }

        if callback != nil {
            var callbacks = self.callbacks[params, default: []]
            callbacks.append(callback!)
            self.callbacks[params] = callbacks
        }

        self.decodeQueue.async {
            let image = StickerImageLoader.loadSync(params: params)
            DispatchQueue.main.async {
                self.cache[params] = image
                if let callbacks = self.callbacks.removeValue(forKey: params) {
                    for callback in callbacks {
                        callback(image)
                    }
                }
            }
        }
    }

    /**
     * Cancels any asynchronous loads in progress for the specified image.
     */
    func cancelLoad(params: StickerImageParams) {
        // TODO
    }

    /**
     * Synchronously loads the specified image, downsampling it to the given
     * size for use as a thumbnail.
     *
     * https://developer.apple.com/videos/play/wwdc2018/219/
     */
    private static func loadSync(params: StickerImageParams) -> UIImage {
        let imageSourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary
        let imageSource = CGImageSourceCreateWithURL(params.imageURL as CFURL, imageSourceOptions)!
        let maxDimensionPixels = max(params.pointSize.width, params.pointSize.height) * params.scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionPixels
        ] as CFDictionary
        let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)!
        return UIImage(cgImage: image)
    }
}
