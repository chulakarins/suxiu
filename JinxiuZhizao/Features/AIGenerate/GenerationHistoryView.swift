#if os(iOS)
import SwiftUI
import UIKit

struct GenerationHistoryView: View {
    @SuxiuReduceMotion private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var records: [GenerationRecord] = []
    @State private var errorMessage: String?
    @State private var favoriteFeedbackCount = 0

    private let repository = GenerationRepository.shared
    private let fileStore = GeneratedFileStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "还没有生成作品",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("完成一次 Mock 生成后，作品会保存在这里。")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            historyRow(record)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("生成历史")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("无法读取历史记录", isPresented: errorBinding) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "请稍后重试")
            }
            .task { loadRecords() }
            .sensoryFeedback(.impact(weight: .light), trigger: favoriteFeedbackCount)
        }
    }

    private func historyRow(_ record: GenerationRecord) -> some View {
        HStack(spacing: 14) {
            HistoryThumbnail(relativePath: record.localImagePath)

            VStack(alignment: .leading, spacing: 5) {
                Text(record.prompt)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text(record.updatedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if record.isMock {
                    Text("演示素材")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }

            Spacer(minLength: 4)

            Button {
                toggleFavorite(record)
            } label: {
                Image(systemName: record.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(record.isFavorite ? .red : .secondary)
                    .contentTransition(SuxiuMotion.symbolReplacement(reduceMotion: reduceMotion))
            }
            .buttonStyle(SuxiuPressStyle(pressedScale: 0.88))
        }
        .padding(.vertical, 5)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func loadRecords() {
        do {
            records = try repository.completedRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleFavorite(_ record: GenerationRecord) {
        let newValue = !record.isFavorite
        do {
            try repository.setFavorite(id: record.id, isFavorite: newValue)
            withAnimation(SuxiuMotion.selection(reduceMotion: reduceMotion)) {
                record.isFavorite = newValue
                if let index = records.firstIndex(where: { $0.id == record.id }) {
                    records[index] = record
                }
            }
            favoriteFeedbackCount += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        let targets = offsets.map { records[$0] }
        Task {
            do {
                for record in targets {
                    if let path = try repository.delete(id: record.id) {
                        try await fileStore.delete(relativePath: path)
                    }
                }
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct HistoryThumbnail: View {
    @SuxiuReduceMotion private var reduceMotion
    let relativePath: String?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 72)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(SuxiuMotion.micro(reduceMotion: reduceMotion), value: image != nil)
        .task(id: relativePath) {
            guard let relativePath,
                  let url = try? await GeneratedFileStore.shared.url(for: relativePath) else {
                return
            }
            image = UIImage(contentsOfFile: url.path)
        }
    }
}
#endif
