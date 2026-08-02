import Foundation

actor GeneratedFileStore {
    nonisolated static let shared = GeneratedFileStore()

    private let fileManager = FileManager.default

    func save(data: Data, fileExtension: String, id: UUID) throws -> String {
        let applicationSupport = try applicationSupportURL()
        let directory = applicationSupport
            .appendingPathComponent("GeneratedWorks", isDirectory: true)

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let relativePath = "GeneratedWorks/\(id.uuidString).\(fileExtension)"
        let destination = applicationSupport.appendingPathComponent(relativePath)
        try data.write(to: destination, options: .atomic)
        return relativePath
    }

    func url(for relativePath: String) throws -> URL {
        try applicationSupportURL().appendingPathComponent(relativePath)
    }

    func delete(relativePath: String) throws {
        let fileURL = try url(for: relativePath)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    private func applicationSupportURL() throws -> URL {
        try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
}
