import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVDesignSystem

/// Pantalla de canales de una categoría.
public struct ChannelsView: View {
    @Bindable var store: StoreOf<ChannelsFeature>

    public init(store: StoreOf<ChannelsFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoading && store.channels.isEmpty {
                ProgressView("Cargando canales…")
            } else if let errorMessage = store.errorMessage, store.channels.isEmpty {
                StatusView(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo cargar",
                    message: errorMessage,
                    action: .init(title: "Reintentar") { store.send(.refresh) }
                )
            } else {
                channelList
            }
        }
        .navigationTitle(store.category.name)
        .searchable(text: $store.searchText, prompt: "Buscar canal")
        .task { store.send(.onTask) }
    }

    private var channelList: some View {
        List {
            ForEach(store.filteredChannels) { channel in
                Button {
                    store.send(.channelTapped(channel))
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        RemoteLogoView(url: channel.logoURL)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(channel.name)
                                .foregroundStyle(.primary)
                            if let number = channel.channelNumber {
                                Text("Canal \(number)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Toca para reproducir")
            }
        }
        .overlay {
            if store.filteredChannels.isEmpty {
                StatusView(
                    systemImage: "magnifyingglass",
                    title: "Sin resultados",
                    message: store.searchText.isEmpty ? "No hay canales en esta categoría." : "Nada coincide con “\(store.searchText)”."
                )
            }
        }
        .refreshable { await store.send(.refresh).finish() }
    }
}
