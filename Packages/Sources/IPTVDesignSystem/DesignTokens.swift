import SwiftUI

/// Tokens de diseño centralizados. Un único lugar para espaciados, radios, color y marca.
/// Evita números mágicos y colores sueltos repartidos por las vistas.
public enum DesignTokens {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 20
    }

    /// Paleta negro + oro rosa. Dark-first (ideal para TV/tvOS: sin "fogonazo" blanco).
    /// El oro rosa se usa como ACENTO (iconos, selección, detalles); el texto va en
    /// blanco/gris para mantener buena legibilidad y contraste.
    public enum Palette {
        // Acento — oro rosa
        public static let accent = Color(red: 0.894, green: 0.671, blue: 0.627)        // ~#E4ABA0
        public static let accentStrong = Color(red: 0.780, green: 0.541, blue: 0.498)  // ~#C78A7F
        public static let accentGradient = LinearGradient(
            colors: [accent, accentStrong],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Fondos (casi negro, por capas)
        public static let background = Color(red: 0.043, green: 0.043, blue: 0.055)     // ~#0B0B0E
        public static let surface = Color(red: 0.094, green: 0.094, blue: 0.110)        // ~#18181C
        public static let surfaceElevated = Color(red: 0.137, green: 0.137, blue: 0.157) // ~#232328

        // Texto
        public static let textPrimary = Color(red: 0.961, green: 0.961, blue: 0.973)    // ~#F5F5F8
        public static let textSecondary = Color(red: 0.635, green: 0.635, blue: 0.678)  // ~#A2A2AD

        // Líneas / separadores
        public static let hairline = Color.white.opacity(0.08)
    }

    public enum Brand {
        public static let accent = Palette.accent
    }
}
