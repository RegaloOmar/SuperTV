#if os(tvOS)
import SwiftUI
import ComposableArchitecture
import IPTVFeatures
import IPTVDesignSystem

/// Login de tvOS. Los `TextField` abren el teclado en pantalla del Apple TV.
struct TVAuthView: View {
    @Bindable var store: StoreOf<AuthFeature>

    var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "tv.inset.filled")
                    .font(.system(size: 80))
                    .foregroundStyle(DesignTokens.Palette.accentGradient)
                Text("SuperTV")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.textPrimary)
                Text("Connect your provider")
                    .font(.title3)
                    .foregroundStyle(DesignTokens.Palette.textSecondary)

                VStack(spacing: DesignTokens.Spacing.md) {
                    TextField("Server (e.g. example.com:8080)", text: $store.host)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                    TextField("Username", text: $store.username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $store.password)
                        .textContentType(.password)
                }

                if let errorMessage = store.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

                Button {
                    store.send(.loginButtonTapped)
                } label: {
                    if store.isLoading {
                        ProgressView().tint(DesignTokens.Palette.background)
                    } else {
                        Text("Connect").padding(.horizontal, DesignTokens.Spacing.xl)
                    }
                }
                .buttonStyle(.superTVPrimary)
                .disabled(!store.isFormValid || store.isLoading)
            }
            .frame(maxWidth: 900)
            .padding(60)
        }
    }
}
#endif
