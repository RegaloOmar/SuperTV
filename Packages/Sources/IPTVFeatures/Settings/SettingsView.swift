import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVDesignSystem

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    private var status: AccountStatus { store.status }

    public var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    section("CONEXIÓN") {
                        InfoRow(label: "Servidor", value: store.account.host.absoluteString)
                        rowDivider
                        InfoRow(label: "Usuario", value: store.account.username)
                    }

                    section("SUSCRIPCIÓN") {
                        InfoRow(label: "Estado", value: status.state.rawValue, valueColor: DesignTokens.Palette.accent)
                        rowDivider
                        InfoRow(label: "Expira", value: expiresText)
                        rowDivider
                        InfoRow(label: "Prueba", value: status.isTrial ? "Sí" : "No")
                        rowDivider
                        InfoRow(label: "Conexiones", value: "\(status.activeConnections) / \(status.maxConnections)")
                    }

                    clearCacheButton
                    logoutButton
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .navigationTitle("Ajustes")
    }

    private var expiresText: String {
        guard let expiresAt = status.expiresAt else { return "Sin límite" }
        return expiresAt.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: - Componentes

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
                .padding(.leading, DesignTokens.Spacing.xs)
            VStack(spacing: 0) { content() }
                .background(DesignTokens.Palette.surface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Palette.hairline, lineWidth: 1)
                )
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(DesignTokens.Palette.hairline)
            .frame(height: 1)
            .padding(.leading, DesignTokens.Spacing.md)
    }

    private var clearCacheButton: some View {
        Button {
            store.send(.clearCacheTapped)
        } label: {
            HStack {
                Text("Limpiar caché")
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                Spacer()
                if store.isClearingCache {
                    ProgressView().tint(DesignTokens.Palette.accent)
                } else if store.cacheCleared {
                    Image(systemName: "checkmark")
                        .foregroundStyle(DesignTokens.Palette.accent)
                        .accessibilityLabel("Caché limpiada")
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Palette.surface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(DesignTokens.Palette.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(store.isClearingCache)
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            store.send(.logoutTapped)
        } label: {
            Text("Cerrar sesión")
                .font(.headline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Palette.surface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Fila etiqueta / valor para Settings.
private struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = DesignTokens.Palette.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 12)
    }
}
