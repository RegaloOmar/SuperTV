import SwiftUI

/// Vista reutilizable para estados vacíos y de error, consistente en toda la app
/// (Fase 4 la usa en todas las pantallas). Accesible por defecto.
public struct StatusView: View {
    public struct Action {
        public let title: String
        public let handler: () -> Void
        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    let systemImage: String
    let title: String
    let message: String?
    let action: Action?

    public init(
        systemImage: String,
        title: String,
        message: String? = nil,
        action: Action? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(DesignTokens.Palette.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(DesignTokens.Palette.textPrimary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.superTVPrimary)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message.map { "\(title). \($0)" } ?? title))
    }
}
