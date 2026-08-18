import SwiftUI

struct SavedRepliesView: View {
    @EnvironmentObject private var store: SavedRepliesStore

    var body: some View {
        NavigationStack {
            ZStack {
                RizzrBackground()

                if store.savedReplies.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.savedReplies) { reply in
                            SavedReplyRow(reply: reply)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: store.remove)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Saved replies")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        VStack(spacing: RizzrSpacing.md) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(RizzrColor.orbCyan)

            Text("Your vault is empty")
                .font(RizzrTypography.title)
                .foregroundStyle(RizzrColor.textPrimary)

            Text("Save a reply you love and it’ll stay here on this device, ready to copy again.")
                .font(RizzrTypography.body)
                .foregroundStyle(RizzrColor.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RizzrSpacing.xl)
        }
        .padding(RizzrSpacing.xl)
    }
}

private struct SavedReplyRow: View {
    @EnvironmentObject private var store: SavedRepliesStore
    let reply: ReplySuggestion

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
                HStack {
                    Text(reply.style.rawValue.capitalized)
                        .font(RizzrTypography.caption)
                        .foregroundStyle(RizzrColor.orbCyan)
                        .textCase(.uppercase)
                        .tracking(1.1)

                    Spacer()

                    Button {
                        store.toggle(reply)
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RizzrColor.orbCoral)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove saved reply")
                }

                Text(reply.text)
                    .font(RizzrTypography.body)
                    .foregroundStyle(RizzrColor.textPrimary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, RizzrSpacing.xs)
    }
}
