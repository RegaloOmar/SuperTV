#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVFeatures
import IPTVDesignSystem

/// Ajustes en tvOS: info de la cuenta, limpiar caché y cerrar sesión.
struct TVSettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    private var status: AccountStatus { store.status }

    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text("Ajustes")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)

                infoRow("Servidor", store.account.host.absoluteString)
                infoRow("Usuario", store.account.username)
                infoRow("Estado", status.state.rawValue, accent: true)
                infoRow("Conexiones", "\(status.activeConnections) / \(status.maxConnections)")

                HStack(spacing: DesignTokens.Spacing.lg) {
                    Button {
                        store.send(.clearCacheTapped)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: store.cacheCleared ? "checkmark" : "trash")
                            Text(store.cacheCleared ? "Caché limpiada" : "Limpiar caché")
                        }
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DesignTokens.Palette.textPrimary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(.card)
                    .disabled(store.isClearingCache)

                    Button {
                        store.send(.logoutTapped)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Cerrar sesión")
                        }
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(.card)
                }
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .frame(maxWidth: 1100, alignment: .leading)
            .padding(80)
        }
    }

    private func infoRow(_ label: String, _ value: String, accent: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(accent ? DesignTokens.Palette.accent : DesignTokens.Palette.textPrimary)
        }
        .font(.title3)
    }
}
#endif
