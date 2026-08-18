import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var copiedValue: String?
    @State private var deleteAfterReply = true
    @State private var voiceReplies = false

    var body: some View {
        NavigationStack {
            List {
                headerSection
                planSection
                preferencesSection
                privacySection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(RizzrBackground())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: RizzrSpacing.md) {
                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rizzr")
                        .font(RizzrTypography.title)
                        .foregroundStyle(RizzrColor.textPrimary)
                    Text("Fast replies, minimal setup.")
                        .font(RizzrTypography.body)
                        .foregroundStyle(RizzrColor.textMuted)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.clear)
        }
    }

    private var planSection: some View {
        Section {
            GlassCard {
                HStack(alignment: .center, spacing: RizzrSpacing.md) {
                    VStack(alignment: .leading, spacing: RizzrSpacing.xs) {
                        Text("3 Free Replies")
                            .font(RizzrTypography.caption)
                            .foregroundStyle(RizzrColor.orbCyan)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        Text("Upgrade when you’re ready")
                            .font(RizzrTypography.bodyStrong)
                            .foregroundStyle(RizzrColor.textPrimary)
                        Text("Keep testing the core flow before locking subscriptions.")
                            .font(RizzrTypography.body)
                            .foregroundStyle(RizzrColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("Pro")
                        .font(RizzrTypography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, RizzrSpacing.md)
                        .padding(.vertical, RizzrSpacing.xs)
                        .background(
                            LinearGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Capsule()
                        )
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } header: {
            sectionLabel("Plan")
        }
    }

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $voiceReplies) {
                settingLabel(icon: "waveform", title: "Voice replies", value: voiceReplies ? "On" : "Text first")
            }
            .tint(RizzrColor.orbCoral)

            nativeRow(icon: "bolt.heart.fill", title: "Default mode", value: "Finesse")
            nativeRow(icon: "globe", title: "Language", value: "Auto")
        } header: {
            sectionLabel("Preferences")
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(isOn: $deleteAfterReply) {
                settingLabel(icon: "trash.fill", title: "Delete recordings after reply", value: deleteAfterReply ? "On" : "Off")
            }
            .tint(RizzrColor.orbCoral)

            nativeRow(icon: "lock.shield.fill", title: "No signup required", value: "On")
        } header: {
            sectionLabel("Privacy")
        }
    }

    private var aboutSection: some View {
        Section {
            infoRow(label: "App", value: "Rizzr")
            infoRow(label: "Build", value: environment.featureFlags.isEnabled(.finesse) ? "Finesse live" : "Feature gated")
            copyRow(label: "API base URL", value: environment.apiClient.baseURL.absoluteString)
        } header: {
            sectionLabel("About")
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(RizzrTypography.caption)
            .foregroundStyle(RizzrColor.orbCoral)
            .tracking(1.2)
    }

    private func settingLabel(icon: String, title: String, value: String) -> some View {
        HStack(spacing: RizzrSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RizzrColor.orbCyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RizzrTypography.body)
                    .foregroundStyle(RizzrColor.textPrimary)
                Text(value)
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.textMuted)
            }
        }
    }

    private func nativeRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: RizzrSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RizzrColor.orbCyan)
                .frame(width: 24)

            Text(title)
                .font(RizzrTypography.body)
                .foregroundStyle(RizzrColor.textPrimary)

            Spacer(minLength: 0)

            Text(value)
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.textMuted)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RizzrColor.textMuted.opacity(0.7))
        }
        .padding(.vertical, 4)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(RizzrColor.textMuted)
            Spacer(minLength: RizzrSpacing.md)
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
            HStack(spacing: RizzrSpacing.sm) {
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

                Spacer(minLength: 0)

                Text(copiedValue == value ? "Copied" : "Copy")
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.orbCyan)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy API base URL")
    }
}
