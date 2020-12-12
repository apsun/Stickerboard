import Foundation
import UniformTypeIdentifiers

/**
 * Represents a single sticker image on disk.
 */
public struct StickerFile: CustomDebugStringConvertible {
    /**
     * The name of the sticker file, without the file extension.
     * Not usable as a filesystem path, for display purposes only.
     */
    public let name: String

    /**
     * The filesystem URL of the sticker image. Usable as a unique identifier.
     */
    public let url: URL

    /**
     * The file type of the sticker image.
     */
    public let utiType: UTType

    public init(name: String, url: URL, utiType: UTType) {
        self.name = name
        self.url = url
        self.utiType = utiType
    }

    public var debugDescription: String {
        return "StickerFile("
            + "name=\(self.name.debugDescription)"
            + ", urlPath=\(self.url.relativePath.debugDescription)"
            + ", utiType=\(self.utiType.debugDescription)"
            + ")"
    }
}

/**
 * Represents a collection of sticker files on disk.
 */
public struct StickerPack: CustomDebugStringConvertible {
    /**
     * The name of the sticker pack, without the leading path components.
     * Not usable as a filesystem path, for display purposes only. This will
     * be nil if the pack was created from the top-level directory.
     */
    public let name: String?

    /**
     * The filesystem URL of the sticker pack.
     */
    public let url: URL

    /**
     * The list of sticker files in this pack.
     */
    public let files: [StickerFile]

    public init(name: String?, url: URL, files: [StickerFile]) {
        self.name = name
        self.url = url
        self.files = files
    }

    public var debugDescription: String {
        return "StickerPack("
            + "name=\(self.name?.debugDescription ?? "(root)")"
            + ", urlPath=\(self.url.relativePath.debugDescription)"
            + ", files=\(self.files.debugDescription)"
            + ")"
    }
}
