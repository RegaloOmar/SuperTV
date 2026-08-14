#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVFeatures
import IPTVDesignSystem

/// Categorías en tvOS: rejilla de tarjetas enfocables (focus engine).
struct TVCategoriesView: View {
    @Bindable var store: StoreOf<ChannelListFeature>

    private let columns = [GridItem(.adaptive(minimum: 360), spacing: 40)]

    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            if store.isLoading && store.categories.isEmpty {
                ProgressView().controlSize(.large).tint(DesignTokens.Palette.accent)
            } else if let errorMessage = store.errorMessage, store.categories.isEmpty {
                StatusView(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo cargar",
                    message: errorMessage,
                    action: .init(title: "Reintentar") { store.send(.refresh) }
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(store.categories) { category in
                            Button {
                                store.send(.categoryTapped(category))
                            } label: {
                                TVCategoryCard(name: category.name)
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(60)
                }
            }
        }
        .navigationTitle("Categorías")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Ajustes", systemImage: "gearshape") {
                    store.send(.settingsButtonTapped)
                }
            }
        }
        .task { store.send(.onTask) }
    }
}

private struct TVCategoryCard: View {
    let name: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.Palette.accent)
            Text(name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(DesignTokens.Palette.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(DesignTokens.Palette.surface)
    }
}
#endif
