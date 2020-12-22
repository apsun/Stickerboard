import Foundation
import UniformTypeIdentifiers

/**
 * Result of trying to load the sticker files.
 */
public struct StickerLoadResult {
    /**
     * These files were successfully loaded.
     */
    public var succeeded: [StickerFile]

    /**
     * These files were skipped over.
     */
    public var skipped: [StickerFile]
}

/**
 * Helper class for managing the contents of the sticker directory,
 * including importing stickers from the user-visible documents
 * directory to the shared app group container and querying for
 * stickers in the shared app group container.
 */
public class StickerFileManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"
    private static let readmeFileName = "README.txt"

    /**
     * The shared sticker file manager instance for the process.
     */
    public static let main = StickerFileManager(fileManager: FileManager.default)

    private let fileManager: FileManager

    private init(fileManager: FileManager) {
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
        return self.documentDirectoryURL().appendingPathComponent(
            StickerFileManager.readmeFileName,
            isDirectory: false
        )
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
     * Returns a list of all sticker files in the given directory.
     */
    private func recursiveStickerFilesInDirectory(
        _ dirURL: URL
    ) throws -> StickerLoadResult {
        let resourceKeys = [
            URLResourceKey.isRegularFileKey,
            URLResourceKey.contentTypeKey,
            URLResourceKey.nameKey
        ]

        if !self.fileManager.fileExists(atPath: dirURL.path) {
            return StickerLoadResult(succeeded: [], skipped: [])
        }

        var errors = [String]()
        guard let dirEnumerator = self.fileManager.enumerator(
            at: dirURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .producesRelativePathURLs],
            errorHandler: { (url: URL, error: Error) -> Bool in
                errors.append("Failed to enumerate \(url.path): \(error.localizedDescription)")
                return true
            }
        ) else {
            throw RuntimeError("Failed to create directory enumerator")
        }

        var result = StickerLoadResult(succeeded: [], skipped: [])
        for case let fileURL as URL in dirEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard
                let isRegularFile = resourceValues.isRegularFile,
                let utiType = resourceValues.contentType,
                let fileName = resourceValues.name
                else { continue }

            if !isRegularFile {
                continue
            }

            if fileName == StickerFileManager.readmeFileName {
                continue
            }

            let name = fileName.prefix(upTo: fileName.lastIndex(of: ".") ?? fileName.endIndex)
            let file = StickerFile(name: String(name), url: fileURL, utiType: utiType)

            if !ImageLoader.loadableImageFormats.contains(utiType) {
                logger.warning(
                    "Skipping \(fileURL.relativePath) because it has type \(utiType.identifier)"
                )
                result.skipped.append(file)
                continue
            }

            result.succeeded.append(file)
        }

        if !errors.isEmpty {
            throw RuntimeError(errors.joined(separator: "\n"))
        }

        return result
    }

    /**
     * Writes a dummy "README.txt" file to the documents directory.
     * This is needed to get the app folder to show up in the Files app;
     * if the documents directory is empty, the system will automatically
     * hide the folder.
     */
    public func ensureReadmeFileExists(content: String) throws {
        let fileURL = self.readmeFileURL()
        if !self.fileManager.fileExists(atPath: fileURL.path) {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    /**
     * Imports all images within the documents directory to the shared
     * app group container to make them visible to the keyboard extension.
     * Returns a list of files imported/skipped.
     */
    public func importFromDocuments() throws -> StickerLoadResult {
        let result = try self.recursiveStickerFilesInDirectory(self.documentDirectoryURL())
        let tempDirURL = try self.temporaryDirectoryURL()
        for file in result.succeeded {
            logger.info("Copying sticker \(file.url.relativePath)")
            let destURL = tempDirURL.appendingPathComponent(
                file.url.relativePath,
                isDirectory: false
            )
            try self.ensureParentDirectoryExists(destURL)
            try self.copySticker(src: file.url, dest: destURL)
        }
        try self.commitStickerDirectory(tempDirURL: tempDirURL)
        return result
    }

    /**
     * Returns all of the stickers in the shared app group container.
     */
    public func stickerPacks() throws -> [StickerPack] {
        let result = try self.recursiveStickerFilesInDirectory(self.stickerDirectoryURL())
        var filesByDir = [URL: [StickerFile]]()
        for file in result.succeeded {
            let packURL = file.url.deletingLastPathComponent()
            var pack = filesByDir[packURL, default: []]
            pack.append(file)
            filesByDir[packURL] = pack
        }

        var ret = [StickerPack]()
        let urls = filesByDir.keys.sorted { a, b in
            a.relativePath.localizedStandardCompare(b.relativePath) == .orderedAscending
        }

        for url in urls {
            let files = filesByDir[url]!.sorted { a, b in
                a.name.localizedStandardCompare(b.name) == .orderedAscending
            }

            var name: String? = url.lastPathComponent
            if name == "." {
                name = nil
            }

            let pack = StickerPack(name: name, url: url, files: files)
            ret.append(pack)
        }

        return ret
    }
}
