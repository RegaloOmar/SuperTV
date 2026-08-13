import SwiftUI

/// Tokens de diseño centralizados. Un único lugar para espaciados, radios y marca.
/// Evita números mágicos repartidos por las vistas.
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

    public enum Brand {
        public static let accent = Color.accentColor
    }
}
