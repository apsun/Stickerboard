import Foundation

/**
 * Represents a single sticker image on disk.
 */
struct StickerFile: CustomDebugStringConvertible {
    /**
     * The name of the sticker file, with the file extension.
     * Not usable as a filesystem path, for display purposes only.
     */
    let name: String

    /**
     * The filesystem URL of the sticker image.
     */
    let url: URL

    var debugDescription: String {
        return "Sticker("
            + "name=\(self.name.debugDescription)"
            + ", urlPath=\(self.url.relativePath.debugDescription)"
            + ")"
    }
}

/**
 * Represents a collection of sticker files on disk.
 */
struct StickerPack: CustomDebugStringConvertible {
    /**
     * The relative path of the sticker pack, relative to the root sticker directory.
     * Not usable as a filesystem path, for display purposes only.
     */
    let path: String

    /**
     * The list of sticker files in this pack.
     */
    let files: [StickerFile]

    var debugDescription: String {
        return "StickerPack("
            + "path=\(self.path.debugDescription)"
            + ", files=\(self.files.debugDescription)"
            + ")"
    }
}
