import Foundation
import UniformTypeIdentifiers

enum StickerError : Error {
    case readFailed(message: String)
}

class StickerManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"
    private static let stickerMIMETypes = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/bmp",
        "image/webp"
    ]

    private let fileManager: FileManager

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    private func documentDirectoryURL() -> URL {
        return self.fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func sharedContainerURL() -> URL {
        return self.fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: StickerManager.groupIdentifier
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

        var errors = [String]()
        let dirEnumerator = self.fileManager.enumerator(
            at: dirURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .producesRelativePathURLs],
            errorHandler: { (url: URL, error: Error) -> Bool in
                errors.append("Failed to enumerate \(url): \(error)")
                return true
            }
        )!

        if !errors.isEmpty {
            throw StickerError.readFailed(message: errors.joined(separator: "\n"))
        }

        var fileURLs = [URL]()
        for case let url as URL in dirEnumerator {
            let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isRegularFile != true {
                continue
            }

            if withTypes != nil {
                let mimeType = resourceValues.contentType?.preferredMIMEType
                if mimeType == nil || !withTypes!.contains(mimeType!) {
                    continue
                }
            }

            fileURLs.append(url)
        }

        return fileURLs
    }

    func importStickers() throws {
        let srcURLs = try self.recursiveFilesInDirectory(
            self.documentDirectoryURL(),
            withTypes: StickerManager.stickerMIMETypes
        )
        let tempDirURL = try self.temporaryDirectoryURL()
        for srcURL in srcURLs {
            print("Copying sticker \(srcURL.relativePath)")
            let destURL = tempDirURL.appendingPathComponent(srcURL.relativePath)
            try self.ensureParentDirectoryExists(destURL)
            try self.copySticker(src: srcURL, dest: destURL)
        }
        try self.commitStickerDirectory(tempDirURL: tempDirURL)
    }

    func loadStickers() throws -> [URL] {
        return try self.recursiveFilesInDirectory(
            self.stickerDirectoryURL(),
            withTypes: nil
        )
    }
}
