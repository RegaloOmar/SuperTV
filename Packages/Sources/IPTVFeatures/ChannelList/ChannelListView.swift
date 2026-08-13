import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVDesignSystem

/// Pantalla de categorías. La navegación real la ejecuta el padre (StackState)
/// al recibir el delegate `categorySelected`.
public struct ChannelListView: View {
    @Bindable var store: StoreOf<ChannelListFeature>

    public init(store: StoreOf<ChannelListFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoading && store.categories.isEmpty {
                ProgressView("Cargando categorías…")
            } else if let errorMessage = store.errorMessage, store.categories.isEmpty {
                StatusView(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo cargar",
                    message: errorMessage,
                    action: .init(title: "Reintentar") { store.send(.refresh) }
                )
            } else {
                categoryList
            }
        }
        .navigationTitle("Categorías")
        .searchable(text: $store.searchText, prompt: "Buscar categoría")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Ajustes", systemImage: "gearshape") {
                    store.send(.settingsButtonTapped)
                }
            }
        }
        .task { store.send(.onTask) }
    }

    private var categoryList: some View {
        List {
            ForEach(store.filteredCategories) { category in
                Button {
                    store.send(.categoryTapped(category))
                } label: {
                    HStack {
                        Text(category.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .overlay {
            if store.filteredCategories.isEmpty {
                StatusView(
                    systemImage: "magnifyingglass",
                    title: "Sin resultados",
                    message: store.searchText.isEmpty ? "No hay categorías." : "Nada coincide con “\(store.searchText)”."
                )
            }
        }
        .refreshable { await store.send(.refresh).finish() }
    }
}
