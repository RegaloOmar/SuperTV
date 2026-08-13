import SwiftUI
import ComposableArchitecture
import IPTVDesignSystem

/// Formulario de conexión a un panel Xtream Codes. Estética SuperTV: negro + oro rosa.
public struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            DesignTokens.Palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    header

                    VStack(spacing: DesignTokens.Spacing.md) {
                        fieldCard {
                            TextField("Servidor (ej. ejemplo.com:8080)", text: $store.host)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                                #endif
                        }
                        fieldCard {
                            TextField("Usuario", text: $store.username)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                .textContentType(.username)
                                #endif
                        }
                        fieldCard {
                            SecureField("Contraseña", text: $store.password)
                                #if os(iOS)
                                .textContentType(.password)
                                #endif
                        }
                    }

                    if let errorMessage = store.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        store.send(.loginButtonTapped)
                    } label: {
                        if store.isLoading {
                            ProgressView().tint(DesignTokens.Palette.background)
                        } else {
                            Text("Conectar")
                        }
                    }
                    .buttonStyle(.superTVPrimary)
                    .disabled(!store.isFormValid || store.isLoading)

                    Text("Introduce los datos de tu suscripción compatible (Xtream Codes). Tus credenciales se guardan solo en tu dispositivo.")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                }
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .disabled(store.isLoading)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private var header: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "tv.inset.filled")
                .font(.system(size: 56))
                .foregroundStyle(DesignTokens.Palette.accentGradient)
            Text("SuperTV")
                .font(.largeTitle.bold())
                .foregroundStyle(DesignTokens.Palette.textPrimary)
            Text("Conecta tu proveedor")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
        }
        .padding(.top, DesignTokens.Spacing.xl)
    }

    private func fieldCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundStyle(DesignTokens.Palette.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, 14)
            .background(DesignTokens.Palette.surface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(DesignTokens.Palette.hairline, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        AuthView(
            store: Store(initialState: AuthFeature.State()) {
                AuthFeature()
            }
        )
    }
}
