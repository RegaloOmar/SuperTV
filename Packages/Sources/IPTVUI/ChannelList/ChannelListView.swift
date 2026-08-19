import SwiftUI
import IPTVFeatures
import ComposableArchitecture
import IPTVCore
import IPTVDesignSystem

/// Pantalla de categorías. Estética SuperTV: negro + oro rosa. La navegación real la
/// ejecuta el padre (StackState) al recibir el delegate `categorySelected`.
public struct ChannelListView: View {
    @Bindable var store: StoreOf<ChannelListFeature>

    public init(store: StoreOf<ChannelListFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            if store.isLoading && store.categories.isEmpty {
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignTokens.Palette.accent)
            } else if let errorMessage = store.errorMessage, store.categories.isEmpty {
                StatusView(
                    systemImage: "wifi.exclamationmark",
                    title: "Couldn't load",
                    message: errorMessage,
                    action: .init(title: "Retry") { store.send(.refresh) }
                )
            } else {
                categoryList
            }
        }
        .navigationTitle("Categories")
        .searchable(text: $store.searchText, prompt: "Search category")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    store.send(.refresh)
                }
                .disabled(store.isLoading)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape") {
                    store.send(.settingsButtonTapped)
                }
            }
        }
        .task { store.send(.onTask) }
    }

    private var categoryList: some View {
        ScrollView {
            // Cuadrícula adaptativa: 1 columna en iPhone, varias en iPad.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: DesignTokens.Spacing.md)], spacing: DesignTokens.Spacing.md) {
                ForEach(store.filteredCategories) { category in
                    Button {
                        store.send(.categoryTapped(category))
                    } label: {
                        CategoryRow(name: category.name)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Tap to see the channels")
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .overlay {
            if store.filteredCategories.isEmpty {
                StatusView(
                    systemImage: "magnifyingglass",
                    title: "No results",
                    message: store.searchText.isEmpty ? "No categories." : "Nothing matches “\(store.searchText)”."
                )
            }
        }
        .refreshable { await store.send(.refresh).finish() }
    }
}

/// Fila de categoría: icono, nombre y chevron en oro rosa.
private struct CategoryRow: View {
    let name: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.body)
                .foregroundStyle(DesignTokens.Palette.accent)
                .frame(width: 36, height: 36)
                .background(DesignTokens.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            Text(name)
                .font(.headline)
                .foregroundStyle(DesignTokens.Palette.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(DesignTokens.Palette.accent)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background(DesignTokens.Palette.surface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(DesignTokens.Palette.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
