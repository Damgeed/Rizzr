import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var copiedValue: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: RizzrSpacing.lg) {
                    section(title: "Build") {
                        infoRow(label: "App", value: "Rizzr")
                        infoRow(label: "Mode", value: environment.featureFlags.isEnabled(.finesse) ? "Finesse live" : "Feature gated")
                        infoRow(label: "API", value: environment.apiClient.baseURL.absoluteString)
                        infoRow(label: "Backend", value: "/health + /api/transcribe + /api/generate")
                    }

                    section(title: "Domain ready") {
                        Text("The backend and app are configured to keep domains swappable until Bud locks the final production URL.")
                            .font(RizzrTypography.body)
                            .foregroundStyle(RizzrColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    section(title: "Env copy") {
                        copyRow(label: "API base URL", value: environment.apiClient.baseURL.absoluteString)
                        copyRow(label: "Final domain status", value: "Not locked yet; swappable by build settings")
                    }
                }
                .padding(.horizontal, RizzrSpacing.md)
                .padding(.top, RizzrSpacing.lg)
                .padding(.bottom, RizzrSpacing.xxl)
            }
            .background(RizzrBackground())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
            Text(title.uppercased())
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.orbCyan)
            GlassCard {
                VStack(alignment: .leading, spacing: RizzrSpacing.md) {
                    content()
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(RizzrColor.textMuted)
            Spacer()
            Text(value)
                .foregroundStyle(RizzrColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(RizzrTypography.body)
    }

    private func copyRow(label: String, value: String) -> some View {
        Button {
            #if canImport(UIKit)
            UIPasteboard.general.string = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            copiedValue = value
            #endif
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(RizzrTypography.bodyStrong)
                        .foregroundStyle(RizzrColor.textPrimary)
                    Text(value)
                        .font(RizzrTypography.caption)
                        .foregroundStyle(RizzrColor.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Text(copiedValue == value ? "Copied" : "Copy")
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.orbCyan)
            }
        }
        .buttonStyle(.plain)
    }
}
