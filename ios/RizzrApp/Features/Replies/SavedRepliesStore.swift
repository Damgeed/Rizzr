import Foundation

@MainActor
final class SavedRepliesStore: ObservableObject {
    @Published private(set) var savedReplies: [ReplySuggestion]

    private let userDefaults: UserDefaults
    private let storageKey = "rizzr.savedReplies.v1"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ReplySuggestion].self, from: data) {
            savedReplies = decoded
        } else {
            savedReplies = []
        }
    }

    func isSaved(_ reply: ReplySuggestion) -> Bool {
        savedReplies.contains(where: { $0.id == reply.id && $0.text == reply.text })
    }

    func toggle(_ reply: ReplySuggestion) {
        if isSaved(reply) {
            remove(reply)
        } else {
            save(reply)
        }
    }

    func save(_ reply: ReplySuggestion) {
        guard !isSaved(reply) else { return }
        savedReplies.insert(reply, at: 0)
        persist()
    }

    func remove(_ reply: ReplySuggestion) {
        savedReplies.removeAll { $0.id == reply.id && $0.text == reply.text }
        persist()
    }

    func remove(at offsets: IndexSet) {
        savedReplies.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(savedReplies) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
