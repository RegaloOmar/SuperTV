import SwiftUI
import ComposableArchitecture
import IPTVDesignSystem

/// Formulario de conexión a un panel Xtream Codes.
public struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        Form {
            Section {
                TextField("Servidor (ej. ejemplo.com:8080)", text: $store.host)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    #endif

                TextField("Usuario", text: $store.username)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .textContentType(.username)
                    #endif

                SecureField("Contraseña", text: $store.password)
                    #if os(iOS)
                    .textContentType(.password)
                    #endif
            } header: {
                Text("Cuenta")
            } footer: {
                Text("Introduce los datos de tu proveedor IPTV (Xtream Codes).")
            }

            if let errorMessage = store.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            Section {
                Button {
                    store.send(.loginButtonTapped)
                } label: {
                    HStack {
                        Spacer()
                        if store.isLoading {
                            ProgressView()
                        } else {
                            Text("Conectar")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!store.isFormValid || store.isLoading)
            }
        }
        .navigationTitle("SuperTV")
        .disabled(store.isLoading)
        .onAppear { store.send(.onAppear) }
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
