import Foundation
import UniformTypeIdentifiers

/**
 * Helper class for managing the contents of the sticker directory,
 * including importing stickers from the user-visible documents
 * directory to the shared app group container and querying for
 * stickers in the shared app group container.
 */
class StickerFileManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"
    private static let stickerMIMETypes = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/bmp",
        "image/webp"
    ]

    /**
     * The shared sticker file manager instance for the process.
     */
    static let main = StickerFileManager(fileManager: FileManager.default)

    private let fileManager: FileManager

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    /**
     * Returns the filesystem URL of the user-visible documents directory.
     */
    private func documentDirectoryURL() -> URL {
        return self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /**
     * Returns the filesystem URL of the root of the shared app group container.
     */
    private func sharedContainerURL() -> URL {
        return self.fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: StickerFileManager.groupIdentifier
        )!
    }

    /**
     * Returns the filesystem URL of the sticker directory in the shared app
     * group container.
     */
    private func stickerDirectoryURL() -> URL {
        return self.sharedContainerURL().appendingPathComponent(
            "Library/Application Support/com.crossbowffs.stickerboard/Stickers/",
            isDirectory: true
        )
    }

    /**
     * Creates and returns the filesystem URL of a temporary directory within
     * the shared app group container.
     */
    private func temporaryDirectoryURL() throws -> URL {
        let url = self.sharedContainerURL().appendingPathComponent(
            "tmp/\(UUID().uuidString)",
            isDirectory: true
        )
        try self.ensureDirectoryExists(url)
        return url
    }

    /**
     * Returns the filesystem URL to the readme file in the documents directory.
     */
    private func readmeFileURL() -> URL {
        return self.documentDirectoryURL().appendingPathComponent("README.txt", isDirectory: false)
    }

    /**
     * Creates a directory at the given path if it does not already exist.
     */
    private func ensureDirectoryExists(_ url: URL) throws {
        try self.fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    /**
     * Creates the parent directory containing the given path if it does
     * not already exist.
     */
    private func ensureParentDirectoryExists(_ url: URL) throws {
        let parentURL = url.deletingLastPathComponent()
        try self.ensureDirectoryExists(parentURL)
    }

    /**
     * Copies a sticker file from src to dest.
     */
    private func copySticker(src: URL, dest: URL) throws {
        try self.fileManager.copyItem(at: src, to: dest)
    }

    /**
     * Atomically moves a directory created using temporaryDirectoryURL()
     * to the shared sticker path.
     */
    private func commitStickerDirectory(tempDirURL: URL) throws {
        let stickerDirURL = self.stickerDirectoryURL()
        try self.ensureDirectoryExists(stickerDirURL)
        _ = try self.fileManager.replaceItemAt(stickerDirURL, withItemAt: tempDirURL)
    }

    /**
     * Returns a list of all files in the given directory. If withTypes
     * is specified, only files with the given MIME types will be returned.
     */
    private func recursiveFilesInDirectory(
        _ dirURL: URL,
        withTypes: [String]? = nil
    ) throws -> [URL] {
        var resourceKeys = [URLResourceKey.isRegularFileKey]
        if withTypes != nil {
            resourceKeys.append(URLResourceKey.contentTypeKey)
        }

        let dirEnumerator = self.fileManager.enumerator(
            at: dirURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .producesRelativePathURLs],
            errorHandler: { (url: URL, error: Error) -> Bool in
                print("Failed to enumerate \(url): \(error)")
                return true
            }
        )!

        var fileURLs = [URL]()
        for case let fileURL as URL in dirEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isRegularFile != true {
                continue
            }

            if withTypes != nil {
                let mimeType = resourceValues.contentType?.preferredMIMEType
                if mimeType == nil || !withTypes!.contains(mimeType!) {
                    continue
                }
            }

            fileURLs.append(fileURL)
        }

        return fileURLs
    }

    /**
     * Writes a dummy "README.txt" file to the documents directory.
     * This is needed to get the app folder to show up in the Files app;
     * if the documents directory is empty, the system will automatically
     * hide the folder.
     */
    func ensureReadmeFileExists() throws {
        let fileURL = self.readmeFileURL()
        if !self.fileManager.fileExists(atPath: fileURL.path) {
            let content = "Copy your files to this directory."
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    /**
     * Imports all images within the documents directory to the shared
     * app group container to make them visible to the keyboard extension.
     */
    func importFromDocuments() throws {
        let srcURLs = try self.recursiveFilesInDirectory(
            self.documentDirectoryURL(),
            withTypes: StickerFileManager.stickerMIMETypes
        )
        let tempDirURL = try self.temporaryDirectoryURL()
        for srcURL in srcURLs {
            print("Copying sticker \(srcURL.relativePath)")
            let destURL = tempDirURL.appendingPathComponent(srcURL.relativePath, isDirectory: false)
            try self.ensureParentDirectoryExists(destURL)
            try self.copySticker(src: srcURL, dest: destURL)
        }
        try self.commitStickerDirectory(tempDirURL: tempDirURL)
    }

    /**
     * Returns all of the stickers in the shared app group container.
     */
    func stickerPacks() throws -> [StickerPack] {
        let urls = try self.recursiveFilesInDirectory(self.stickerDirectoryURL())

        var pathMap = [String: [StickerFile]]()
        for url in urls {
            var packPath = url.deletingLastPathComponent().relativePath
            if packPath == "." {
                packPath = ""
            }

            var pack = pathMap[packPath, default: []]
            pack.append(StickerFile(name: url.lastPathComponent, url: url))
            pathMap[packPath] = pack
        }

        var ret = [StickerPack]()
        for path in pathMap.keys.sorted(by: <) {
            let files = pathMap[path]!.sorted { $0.name < $1.name }
            ret.append(StickerPack(path: path, files: files))
        }

        return ret
    }

    /**
     * Similar to stickerPacks(), but forces all of the stickers into a
     * single sticker pack as if they were in the same directory.
     *
     * TODO: For testing purposes only, to be removed
     */
    func singleStickerPack() throws -> StickerPack {
        let urls = try self.recursiveFilesInDirectory(self.stickerDirectoryURL())
        var stickers = [StickerFile]()
        for url in urls {
            stickers.append(StickerFile(name: url.lastPathComponent, url: url))
        }
        return StickerPack(path: "", files: stickers)
    }
}
