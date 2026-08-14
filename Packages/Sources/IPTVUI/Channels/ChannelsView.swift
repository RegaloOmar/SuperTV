import SwiftUI
import IPTVFeatures
import ComposableArchitecture
import IPTVCore
import IPTVDesignSystem

/// Pantalla de canales de una categoría. Estética SuperTV: negro + oro rosa.
public struct ChannelsView: View {
    @Bindable var store: StoreOf<ChannelsFeature>

    public init(store: StoreOf<ChannelsFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            if store.isLoading && store.channels.isEmpty {
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignTokens.Palette.accent)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Actualizar", systemImage: "arrow.clockwise") {
                    store.send(.refresh)
                }
                .disabled(store.isLoading)
            }
        }
        .task { store.send(.onTask) }
    }

    private var channelList: some View {
        ScrollView {
            // Cuadrícula adaptativa: 1 columna en iPhone, varias en iPad.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: DesignTokens.Spacing.md)], spacing: DesignTokens.Spacing.md) {
                ForEach(store.filteredChannels) { channel in
                    Button {
                        store.send(.channelTapped(channel))
                    } label: {
                        ChannelRow(channel: channel)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Toca para reproducir")
                }
            }
            .padding(DesignTokens.Spacing.md)
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

/// Fila de canal: logo grande, nombre, número en oro rosa y botón de reproducir.
private struct ChannelRow: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm + 2) {
            RemoteLogoView(url: channel.logoURL, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(channel.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let number = channel.channelNumber {
                    Text("CANAL \(number)")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.5)
                        .foregroundStyle(DesignTokens.Palette.accent)
                }
            }

            Spacer()

            Image(systemName: "play.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(DesignTokens.Palette.background)
                .frame(width: 34, height: 34)
                .background(DesignTokens.Palette.accentGradient, in: Circle())
        }
        .padding(.vertical, 10)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background(DesignTokens.Palette.surface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(DesignTokens.Palette.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
