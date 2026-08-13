import SwiftUI

/// Botón principal de SuperTV: degradado oro rosa, texto oscuro, ancho completo.
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(DesignTokens.Palette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DesignTokens.Palette.accentGradient, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
                .contentShape(Rectangle())
        }
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var superTVPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
