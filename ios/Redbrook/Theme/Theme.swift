import SwiftUI

/// Redbrook Clinic design system: warm cream, sage green, soft taupe.
/// Colours are the web app's oklch tokens (src/styles.css) converted to sRGB.
enum Palette {
  static let cream = Color(hex: 0xEFEAE0)
  static let background = Color(hex: 0xF4F0E8)
  static let foreground = Color(hex: 0x3E3A34)
  static let card = Color(hex: 0xFCFAF6)
  static let primary = Color(hex: 0x7F8275)
  static let primaryForeground = Color(hex: 0xFCFAF6)
  static let secondary = Color(hex: 0xE2DDD5)
  static let secondaryForeground = Color(hex: 0x46423A)
  static let muted = Color(hex: 0xE9E6DF)
  static let mutedForeground = Color(hex: 0x75716A)
  static let taupe = Color(hex: 0x84776F)
  static let taupeForeground = Color(hex: 0xFCFAF6)
  static let destructive = Color(hex: 0xAB413E)
  static let border = Color(hex: 0xD5D0C8)
  static let sage = primary
  static let sageForeground = primaryForeground
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1
    )
  }
}

/// Cormorant Garamond for headings, Jost for body text, as on the website.
enum AppFont {
  static func display(_ size: CGFloat) -> Font {
    .custom("CormorantGaramond-Light", size: size, relativeTo: .title)
  }

  static func body(_ size: CGFloat = 15) -> Font {
    .custom("JostRoman-Light", size: size, relativeTo: .body)
  }

  static func bodyRegular(_ size: CGFloat = 15) -> Font {
    .custom("JostRoman-Regular", size: size, relativeTo: .body)
  }

  static func label(_ size: CGFloat = 11.5) -> Font {
    .custom("JostRoman-Regular", size: size, relativeTo: .caption)
  }
}

extension View {
  /// Uppercase display heading (`display-caps` on the web).
  func displayCaps(_ size: CGFloat = 28) -> some View {
    font(AppFont.display(size))
      .textCase(.uppercase)
      .tracking(size * 0.12)
  }

  /// Small uppercase label (`label-caps` on the web).
  func labelCaps(_ size: CGFloat = 11.5) -> some View {
    font(AppFont.label(size))
      .textCase(.uppercase)
      .tracking(size * 0.18)
  }

  func bodyText(_ size: CGFloat = 15) -> some View {
    font(AppFont.body(size)).lineSpacing(4)
  }

  func mutedText(_ size: CGFloat = 15) -> some View {
    bodyText(size).foregroundStyle(Palette.mutedForeground)
  }

  /// Bordered card used for bookings and list rows.
  func cardBox(padding: CGFloat = 20) -> some View {
    self
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Palette.card)
      .overlay(Rectangle().stroke(Palette.border, lineWidth: 1))
  }

  /// Text input look (`Input` on the web).
  func clinicField() -> some View {
    self
      .font(AppFont.body(16))
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 12)
      .padding(.vertical, 11)
      .background(Palette.card)
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.border, lineWidth: 1))
  }
}

struct ClinicButtonStyle: ButtonStyle {
  enum Variant { case primary, secondary, outline, ghost, destructive }
  enum Size { case small, regular, large }

  var variant: Variant = .primary
  var size: Size = .regular
  var fullWidth = false

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .labelCaps(size == .small ? 10.5 : 11.5)
      .multilineTextAlignment(.center)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .frame(maxWidth: fullWidth ? .infinity : nil)
      .foregroundStyle(foreground)
      .background(background.opacity(configuration.isPressed ? 0.85 : 1))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(variant == .outline ? Palette.border : .clear, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 2))
      .opacity(isEnabled ? 1 : 0.5)
      .contentShape(Rectangle())
  }

  private var horizontalPadding: CGFloat {
    switch size {
    case .small: 12
    case .regular: 18
    case .large: 26
    }
  }

  private var verticalPadding: CGFloat {
    switch size {
    case .small: 8
    case .regular: 12
    case .large: 15
    }
  }

  private var foreground: Color {
    switch variant {
    case .primary: Palette.primaryForeground
    case .secondary: Palette.secondaryForeground
    case .outline, .ghost: Palette.foreground
    case .destructive: Palette.primaryForeground
    }
  }

  private var background: Color {
    switch variant {
    case .primary: Palette.primary
    case .secondary: Palette.secondary
    case .outline: Palette.background
    case .ghost: .clear
    case .destructive: Palette.destructive
    }
  }
}

extension ButtonStyle where Self == ClinicButtonStyle {
  static var clinic: ClinicButtonStyle { ClinicButtonStyle() }

  static func clinic(
    _ variant: ClinicButtonStyle.Variant,
    size: ClinicButtonStyle.Size = .regular,
    fullWidth: Bool = false
  ) -> ClinicButtonStyle {
    ClinicButtonStyle(variant: variant, size: size, fullWidth: fullWidth)
  }
}
