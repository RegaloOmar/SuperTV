#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVFeatures
import IPTVDesignSystem

/// Canales de una categoría en tvOS: rejilla de tarjetas enfocables.
struct TVChannelsView: View {
    @Bindable var store: StoreOf<ChannelsFeature>

    private let columns = [GridItem(.adaptive(minimum: 420), spacing: 40)]

    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            if store.isLoading && store.channels.isEmpty {
                ProgressView().controlSize(.large).tint(DesignTokens.Palette.accent)
            } else if let errorMessage = store.errorMessage, store.channels.isEmpty {
                StatusView(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo cargar",
                    message: errorMessage,
                    action: .init(title: "Reintentar") { store.send(.refresh) }
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(store.channels) { channel in
                            Button {
                                store.send(.channelTapped(channel))
                            } label: {
                                TVChannelCard(channel: channel)
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(60)
                }
            }
        }
        .navigationTitle(store.category.name)
        .task(id: store.category.id) { store.send(.onTask) }
    }
}

private struct TVChannelCard: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 24) {
            RemoteLogoView(url: channel.logoURL, size: 90)
            VStack(alignment: .leading, spacing: 6) {
                Text(channel.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                    .lineLimit(1)
                if let number = channel.channelNumber {
                    Text("CANAL \(number)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Palette.accent)
                }
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(DesignTokens.Palette.accent)
        }
        .padding(28)
        .frame(height: 150)
        .background(DesignTokens.Palette.surface)
    }
}
#endif
