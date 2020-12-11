import Foundation
import UIKit

/**
 * Represents the desired image configuration to be loaded.
 */
struct AsyncImageLoaderParams: Hashable, CustomDebugStringConvertible {
    let imageURL: URL
    let resizeParams: ImageResizeParams

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.imageURL.path)
        hasher.combine(self.resizeParams)
    }

    var debugDescription: String {
        return "AsyncImageLoaderParams("
            + "path=\(self.imageURL.relativePath)"
            + ", resizeParams=\(self.resizeParams.debugDescription)"
            + ")"
    }
}

/**
 * Asynchronously loads, resizes, and caches images from disk.
 */
class AsyncImageLoader {
    typealias Callback = (Result<UIImage, Error>) -> Void
    private let decodeQueue = DispatchQueue(
        label: "com.crossbowffs.stickerboard.decodequeue",
        qos: .userInitiated
    )

    private let cache = Cache<AsyncImageLoaderParams, UIImage>()
    private var callbacks = [AsyncImageLoaderParams: [Callback]]()

    /**
     * The global shared image loader instance.
     */
    static let main = AsyncImageLoader()

    /**
     * Loads the specified image, downsampling it to the given size for use
     * as a thumbnail. Calls the given callback immediately if the image of
     * the given size is already in the cache; otherwise, asynchronously loads
     * the image and calls the callback once the image is ready.
     */
    func loadAsync(
        params: AsyncImageLoaderParams,
        callback: Callback? = nil
    ) {
        // If the image is already in our cache, just immediately invoke
        // the callback and return.
        //
        // TODO: Maybe this should be invoked asynchronously on the main
        // event loop?
        if let image = self.cache[params] {
            callback?(Result.success(image))
            return
        }

        // If someone already submitted a request for this image, just
        // piggyback off their request instead of making a new one.
        if var callbacks = self.callbacks[params] {
            if let callback = callback {
                callbacks.append(callback)
            }
            return
        }

        var callbacks = [Callback]()
        if let callback = callback {
            callbacks.append(callback)
        }
        self.callbacks[params] = callbacks

        self.decodeQueue.async {
            let result = Result {
                try ImageLoader.loadImage(
                    url: params.imageURL,
                    resizeParams: params.resizeParams
                )
            }

            DispatchQueue.main.async {
                if case let .success(image) = result {
                    self.cache[params] = image
                }

                if let callbacks = self.callbacks.removeValue(forKey: params) {
                    for callback in callbacks {
                        callback(result)
                    }
                }
            }
        }
    }

    /**
     * Cancels any asynchronous loads in progress for the specified image.
     */
    func cancelLoad(params: AsyncImageLoaderParams) {
        // TODO
    }
}
