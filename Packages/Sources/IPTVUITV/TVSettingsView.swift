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
                        Label(store.cacheCleared ? "Caché limpiada" : "Limpiar caché",
                              systemImage: store.cacheCleared ? "checkmark" : "trash")
                    }
                    .disabled(store.isClearingCache)

                    Button(role: .destructive) {
                        store.send(.logoutTapped)
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
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
