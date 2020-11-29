import Foundation
import UniformTypeIdentifiers

/**
 * Represents a single sticker image on disk.
 */
struct StickerFile: CustomDebugStringConvertible {
    /**
     * The name of the sticker file, without the file extension.
     * Not usable as a filesystem path, for display purposes only.
     */
    let name: String

    /**
     * The filesystem URL of the sticker image. Usable as a unique identifier.
     */
    let url: URL

    /**
     * The file type of the sticker image.
     */
    let utiType: UTType

    var debugDescription: String {
        return "Sticker("
            + "name=\(self.name.debugDescription)"
            + ", urlPath=\(self.url.relativePath.debugDescription)"
            + ", utiType=\(self.utiType.debugDescription)"
            + ")"
    }
}

/**
 * Represents a collection of sticker files on disk.
 */
struct StickerPack: CustomDebugStringConvertible {
    /**
     * The name of the sticker pack, without the leading path components.
     * Not usable as a filesystem path, for display purposes only. This will
     * be nil if the pack was created from the top-level directory.
     */
    let name: String?

    /**
     * The filesystem URL of the sticker pack.
     */
    let url: URL

    /**
     * The list of sticker files in this pack.
     */
    let files: [StickerFile]

    var debugDescription: String {
        return "StickerPack("
            + "name=\(self.name?.debugDescription ?? "(root)")"
            + ", urlPath=\(self.url.relativePath.debugDescription)"
            + ", files=\(self.files.debugDescription)"
            + ")"
    }
}
