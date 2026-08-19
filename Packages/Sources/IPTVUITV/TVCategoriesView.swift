#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import IPTVCore
import IPTVFeatures
import IPTVDesignSystem

/// Categorías en tvOS: rejilla de tarjetas enfocables (focus engine).
struct TVCategoriesView: View {
    @Bindable var store: StoreOf<ChannelListFeature>

    // Tres columnas fijas (antes la rejilla adaptativa metía 4).
    private let columns = [
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
    ]

    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if store.isLoading && store.categories.isEmpty {
                    Spacer()
                    ProgressView().controlSize(.large).tint(DesignTokens.Palette.accent)
                    Spacer()
                } else if let errorMessage = store.errorMessage, store.categories.isEmpty {
                    Spacer()
                    StatusView(
                        systemImage: "wifi.exclamationmark",
                        title: "Couldn't load",
                        message: errorMessage,
                        action: .init(title: "Retry") { store.send(.refresh) }
                    )
                    Spacer()
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
                        .padding(.horizontal, 60)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task { store.send(.onTask) }
    }

    private var header: some View {
        HStack {
            Text("Categories")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(DesignTokens.Palette.textPrimary)
            Spacer()
            HStack(spacing: DesignTokens.Spacing.lg) {
                Button {
                    store.send(.refresh)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.card)
                .disabled(store.isLoading)

                Button {
                    store.send(.settingsButtonTapped)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.card)
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
        .padding(.bottom, 20)
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
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .background(DesignTokens.Palette.surface)
    }
}
#endif
