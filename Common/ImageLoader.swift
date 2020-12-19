import Foundation
import UIKit
import UniformTypeIdentifiers

/**
 * Adds a Hashable implementation for CGSize.
 */
extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}

/**
 * Whether the image should be resized to fill or fit the specified size.
 */
public enum ImageResizeMode {
    case fill
    case fit
}

/**
 * Parameters for resizing an image, if desired.
 */
public struct ImageResizeParams: Hashable, CustomDebugStringConvertible {
    public let pointSize: CGSize
    public let scale: CGFloat
    public let mode: ImageResizeMode

    public init(pointSize: CGSize, scale: CGFloat, mode: ImageResizeMode) {
        self.pointSize = pointSize
        self.scale = scale
        self.mode = mode
    }

    public var debugDescription: String {
        return "ImageResizeParams("
            + "pointSize=\(self.pointSize.debugDescription)"
            + ", scale=\(self.scale)"
            + ", mode=\(self.mode)"
            + ")"
    }
}

/**
 * Synchronously loads images from disk and downsizes them to reduce
 * memory usage.
 */
public class ImageLoader {
    /**
     * These image formats are universally renderable.
     */
    public static let safeImageFormats = [
        UTType.png,
        UTType.jpeg,
    ]

    /**
     * These image formats are animated, and cannot be resized.
     */
    public static let animatedImageFormats = [
        UTType.gif,
    ]

    /**
     * These image formats can be loaded by the app, although some
     * apps may not be able to render them.
     */
    public static let loadableImageFormats = [
        UTType.png,
        UTType.jpeg,
        UTType.gif,
        UTType.bmp,
        UTType.tiff,
        UTType.webP,
        UTType.heif,
        UTType.heic,
    ]

    /**
     * Returns an appropriate value for maxDimensionPixels given the
     * specified parameters.
     */
    private static func maxDimensionPixelsFor(
        _ params: ImageResizeParams
    ) -> CGFloat {
        switch params.mode {
        case .fill:
            return max(params.pointSize.width, params.pointSize.height) * params.scale
        case .fit:
            return min(params.pointSize.width, params.pointSize.height) * params.scale
        }
    }

    /**
     * Resizes an image using the specified parameters.
     */
    private static func resize(
        imageSource: CGImageSource,
        params: ImageResizeParams
    ) throws -> CGImage {
        let maxDimensionPixels = ImageLoader.maxDimensionPixelsFor(params)

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionPixels
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            throw RuntimeError("CGImageSourceCreateThumbnailAtIndex failed")
        }
        return image
    }

    /**
     * Returns the image directly, without resizing.
     */
    private static func direct(
        imageSource: CGImageSource
    ) throws -> CGImage {
        let options = [
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, options) else {
            throw RuntimeError("CGImageSourceCreateImageAtIndex failed")
        }
        return image
    }

    /**
     * Loads a CGImage from disk, and if resizeParams is not nil,
     * also resizes it with the given parameters.
     */
    private static func loadAndMaybeResize(
        url: URL,
        resizeParams: ImageResizeParams?
    ) throws -> CGImage {
        logger.info("Loading image \(url.relativePath) using \(resizeParams.debugDescription)")

        // https://developer.apple.com/videos/play/wwdc2018/219/
        let options = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options) else {
            throw RuntimeError("CGImageSourceCreateWithURL failed")
        }

        if let resizeParams = resizeParams {
            return try resize(imageSource: imageSource, params: resizeParams)
        } else {
            return try direct(imageSource: imageSource)
        }
    }

    /**
     * Loads an image from disk and resizes it to the given size.
     */
    public static func loadImage(
        url: URL,
        resizeParams: ImageResizeParams?
    ) throws -> UIImage {
        let image = try ImageLoader.loadAndMaybeResize(
            url: url,
            resizeParams: resizeParams
        )
        return UIImage(cgImage: image)
    }

    /**
     * Loads an image from disk, resizes it to the given size, and
     * returns it as a PNG with an alpha channel.
     */
    public static func loadImageAsPNG(
        url: URL,
        resizeParams: ImageResizeParams?
    ) throws -> Data {
        let image = try ImageLoader.loadAndMaybeResize(
            url: url,
            resizeParams: resizeParams
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

        let uiImage = UIImage(cgImage: destImage)
        guard let pngData = uiImage.pngData() else {
            throw RuntimeError("Failed to convert image to PNG")
        }
        return pngData
    }
}
