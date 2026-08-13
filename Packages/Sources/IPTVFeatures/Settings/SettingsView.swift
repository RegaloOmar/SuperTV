import SwiftUI
import ComposableArchitecture
import IPTVCore

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    private var status: AccountStatus { store.status }

    public var body: some View {
        List {
            Section("Conexión") {
                LabeledContent("Servidor", value: store.account.host.absoluteString)
                LabeledContent("Usuario", value: store.account.username)
            }

            Section("Suscripción") {
                LabeledContent("Estado", value: status.state.rawValue)
                if let expiresAt = status.expiresAt {
                    LabeledContent("Expira", value: expiresAt.formatted(date: .abbreviated, time: .shortened))
                } else {
                    LabeledContent("Expira", value: "Sin límite")
                }
                LabeledContent("Prueba", value: status.isTrial ? "Sí" : "No")
                LabeledContent("Conexiones", value: "\(status.activeConnections) / \(status.maxConnections)")
            }

            Section {
                Button {
                    store.send(.clearCacheTapped)
                } label: {
                    HStack {
                        Text("Limpiar caché")
                        Spacer()
                        if store.isClearingCache {
                            ProgressView()
                        } else if store.cacheCleared {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                                .accessibilityLabel("Caché limpiada")
                        }
                    }
                }
                .disabled(store.isClearingCache)
            } footer: {
                Text("Elimina el catálogo guardado localmente. Se volverá a descargar al entrar.")
            }

            Section {
                Button("Cerrar sesión", role: .destructive) {
                    store.send(.logoutTapped)
                }
            }
        }
        .navigationTitle("Ajustes")
    }
}
