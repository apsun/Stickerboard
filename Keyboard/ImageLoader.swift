import Foundation
import UIKit
import UniformTypeIdentifiers

/**
 * Whether the image should be resized to fill or fit the specified size.
 */
enum ImageResizeMode {
    case fill
    case fit
}

/**
 * Synchronously loads images from disk and downsizes them to reduce
 * memory usage.
 */
class ImageLoader {
    /**
     * Returns an appropriate value for maxDimensionPixels given the
     * specified parameters.
     */
    private static func maxDimensionPixelsFor(
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        mode: ImageResizeMode
    ) -> CGFloat {
        switch mode {
        case .fill:
            return max(width, height) * scale
        case .fit:
            return min(width, height) * scale
        }
    }

    /**
     * Resizes an image using the specified parameters.
     */
    private static func resize(
        imageSource: CGImageSource,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        mode: ImageResizeMode
    ) throws -> CGImage {
        let maxDimensionPixels = ImageLoader.maxDimensionPixelsFor(
            width: width,
            height: height,
            scale: scale,
            mode: mode
        )

        // https://developer.apple.com/videos/play/wwdc2018/219/
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionPixels
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            downsampleOptions
        ) else {
            throw RuntimeError("CGImageSourceCreateThumbnailAtIndex failed")
        }
        return image
    }

    /**
     * Loads a CGImage from disk and resizes it using the specified
     * parameters.
     */
    private static func loadAndResize(
        url: URL,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        mode: ImageResizeMode
    ) throws -> CGImage {
        let imageSourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(
            url as CFURL,
            imageSourceOptions
        ) else {
            throw RuntimeError("CGImageSourceCreateWithURL failed")
        }
        return try resize(
            imageSource: imageSource,
            width: width,
            height: height,
            scale: scale,
            mode: mode
        )
    }

    /**
     * Loads an image from disk and resizes it to the given size.
     */
    static func loadImage(
        url: URL,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        mode: ImageResizeMode
    ) throws -> UIImage {
        let image = try ImageLoader.loadAndResize(
            url: url,
            width: width,
            height: height,
            scale: scale,
            mode: mode
        )
        return UIImage(cgImage: image)
    }

    /**
     * Loads an image from disk, resizes it to the given size, and
     * ensures that it has an alpha channel.
     */
    static func loadImageWithAlpha(
        url: URL,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat,
        mode: ImageResizeMode
    ) throws -> UIImage {
        let image = try ImageLoader.loadAndResize(
            url: url,
            width: width,
            height: height,
            scale: scale,
            mode: mode
        )

        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw RuntimeError("Failed to create graphics context")
        }

        context.interpolationQuality = .high
        let rect = CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height))
        context.draw(image, in: rect)
        guard let destImage = context.makeImage() else {
            throw RuntimeError("Failed to create destination image")
        }

        return UIImage(cgImage: destImage)
    }
}
