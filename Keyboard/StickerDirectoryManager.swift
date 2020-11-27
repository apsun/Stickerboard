import Foundation
import UniformTypeIdentifiers

class StickerDirectoryManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"
    private static let stickerMIMETypes = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/bmp",
        "image/webp"
    ]

    static let main = StickerDirectoryManager(fileManager: FileManager.default)

    private let fileManager: FileManager

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    private func documentDirectoryURL() -> URL {
        return self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func sharedContainerURL() -> URL {
        return self.fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: StickerDirectoryManager.groupIdentifier
        )!
    }

    private func stickerDirectoryURL() -> URL {
        return self.sharedContainerURL().appendingPathComponent(
            "Library/Application Support/com.crossbowffs.stickerboard/Stickers/",
            isDirectory: true
        )
    }

    private func temporaryDirectoryURL() throws -> URL {
        let url = self.sharedContainerURL().appendingPathComponent(
            "tmp/\(UUID().uuidString)",
            isDirectory: true
        )
        try self.ensureDirectoryExists(url)
        return url
    }

    private func readmeFileURL() -> URL {
        return self.documentDirectoryURL().appendingPathComponent("README.txt", isDirectory: false)
    }

    private func ensureDirectoryExists(_ url: URL) throws {
        try self.fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    private func ensureParentDirectoryExists(_ url: URL) throws {
        let parentURL = url.deletingLastPathComponent()
        try self.ensureDirectoryExists(parentURL)
    }

    private func copySticker(src: URL, dest: URL) throws {
        try self.fileManager.copyItem(at: src, to: dest)
    }

    private func commitStickerDirectory(tempDirURL: URL) throws {
        let stickerDirURL = self.stickerDirectoryURL()
        try self.ensureDirectoryExists(stickerDirURL)
        _ = try self.fileManager.replaceItemAt(stickerDirURL, withItemAt: tempDirURL)
    }

    private func recursiveFilesInDirectory(_ dirURL: URL, withTypes: [String]?) throws -> [URL] {
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

    func ensureReadmeFileExists() throws {
        let fileURL = self.readmeFileURL()
        if !self.fileManager.fileExists(atPath: fileURL.path) {
            let content = "Copy your files to this directory."
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func importFromDocuments() throws {
        let srcURLs = try self.recursiveFilesInDirectory(
            self.documentDirectoryURL(),
            withTypes: StickerDirectoryManager.stickerMIMETypes
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

    func importedStickerURLs() throws -> [URL] {
        return try self.recursiveFilesInDirectory(
            self.stickerDirectoryURL(),
            withTypes: nil
        )
    }
}
