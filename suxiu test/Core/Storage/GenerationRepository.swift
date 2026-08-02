import Foundation
import SwiftData

enum GenerationRepositoryError: LocalizedError {
    case storageUnavailable

    var errorDescription: String? {
        "本地作品库暂时不可用，请重新启动应用后重试"
    }
}

@Model
final class GenerationRecord {
    @Attribute(.unique) var id: UUID
    var prompt: String
    var provider: String
    var providerTaskID: String?
    var status: String
    var progress: Double
    var localImagePath: String?
    var remoteImageURL: String?
    var isMock: Bool
    var isFavorite: Bool
    var errorCode: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), prompt: String) {
        self.id = id
        self.prompt = prompt
        self.provider = "mock"
        self.status = "pending"
        self.progress = 0
        self.isMock = true
        self.isFavorite = false
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@MainActor
final class GenerationRepository {
    static let shared = GenerationRepository()

    private let container: ModelContainer?
    private let context: ModelContext?

    private init() {
        do {
            let persistentContainer = try ModelContainer(for: GenerationRecord.self)
            container = persistentContainer
            context = ModelContext(persistentContainer)
        } catch {
            do {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                let fallbackContainer = try ModelContainer(
                    for: GenerationRecord.self,
                    configurations: configuration
                )
                container = fallbackContainer
                context = ModelContext(fallbackContainer)
            } catch {
                container = nil
                context = nil
            }
        }
    }

    func createPending(prompt: String) throws -> UUID {
        let context = try availableContext()
        let record = GenerationRecord(prompt: prompt)
        context.insert(record)
        try context.save()
        return record.id
    }

    func update(id: UUID, stage: GenerationStage) throws {
        let context = try availableContext()
        guard let record = try record(with: id) else { return }
        switch stage {
        case .idle:
            break
        case .validating:
            record.status = "pending"
        case .queued:
            record.status = "queued"
        case .generating(let progress):
            record.status = "generating"
            record.progress = progress
        case .downloading:
            record.status = "downloading"
            record.progress = 0.95
        case .saving:
            record.status = "saving"
            record.progress = 0.98
        case .completed:
            record.status = "completed"
            record.progress = 1
        case .failed:
            record.status = "failed"
        case .cancelled:
            record.status = "cancelled"
        }
        record.updatedAt = .now
        try context.save()
    }

    func complete(
        id: UUID,
        payload: GeneratedImagePayload,
        localImagePath: String
    ) throws {
        let context = try availableContext()
        guard let record = try record(with: id) else { return }
        record.provider = payload.provider
        record.providerTaskID = payload.providerTaskID
        record.localImagePath = localImagePath
        record.isMock = payload.isMock
        record.status = "completed"
        record.progress = 1
        record.updatedAt = .now
        try context.save()
    }

    func fail(id: UUID, error: Error) throws {
        let context = try availableContext()
        guard let record = try record(with: id) else { return }
        record.status = "failed"
        record.errorCode = errorCode(for: error)
        record.updatedAt = .now
        try context.save()
    }

    func completedRecords() throws -> [GenerationRecord] {
        let context = try availableContext()
        var descriptor = FetchDescriptor<GenerationRecord>(
            predicate: #Predicate { $0.status == "completed" }
        )
        descriptor.sortBy = [SortDescriptor(\.updatedAt, order: .reverse)]
        return try context.fetch(descriptor)
    }

    func setFavorite(id: UUID, isFavorite: Bool) throws {
        let context = try availableContext()
        guard let record = try record(with: id) else { return }
        record.isFavorite = isFavorite
        record.updatedAt = .now
        try context.save()
    }

    func delete(id: UUID) throws -> String? {
        let context = try availableContext()
        guard let record = try record(with: id) else { return nil }
        let relativePath = record.localImagePath
        context.delete(record)
        try context.save()
        return relativePath
    }

    private func record(with id: UUID) throws -> GenerationRecord? {
        let context = try availableContext()
        let targetID = id
        let descriptor = FetchDescriptor<GenerationRecord>(
            predicate: #Predicate { $0.id == targetID }
        )
        return try context.fetch(descriptor).first
    }

    private func availableContext() throws -> ModelContext {
        guard let context else {
            throw GenerationRepositoryError.storageUnavailable
        }
        return context
    }

    private func errorCode(for error: Error) -> String {
        guard let generationError = error as? GenerationError else {
            return "unknown"
        }
        switch generationError {
        case .emptyPrompt: return "empty_prompt"
        case .offline: return "offline"
        case .serviceUnavailable: return "service_unavailable"
        case .rateLimited: return "rate_limited"
        case .timedOut: return "timed_out"
        case .invalidResponse: return "invalid_response"
        case .missingMockAsset: return "missing_mock_asset"
        }
    }
}
