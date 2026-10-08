import SwiftUI

struct FieldLabel: View {
  let text: String
  init(_ text: String) { self.text = text }

  var body: some View {
    Text(text)
      .labelCaps()
      .foregroundStyle(Palette.foreground)
  }
}

struct Badge: View {
  let text: String
  var filled: Bool

  var body: some View {
    Text(text)
      .font(AppFont.bodyRegular(12))
      .padding(.horizontal, 9)
      .padding(.vertical, 3)
      .foregroundStyle(filled ? Palette.primaryForeground : Palette.secondaryForeground)
      .background(filled ? Palette.primary : Palette.secondary)
      .clipShape(RoundedRectangle(cornerRadius: 2))
  }
}

/// Grey placeholder block shown while data loads (`Skeleton` on the web).
struct SkeletonBlock: View {
  var height: CGFloat
  @State private var dim = false

  var body: some View {
    Rectangle()
      .fill(Palette.muted)
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .opacity(dim ? 0.5 : 1)
      .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: dim)
      .onAppear { dim = true }
      .accessibilityLabel("Loading")
  }
}

struct Divider1: View {
  var body: some View {
    Rectangle().fill(Palette.border).frame(height: 1)
  }
}

struct OpeningHoursList: View {
  var color: Color = Palette.mutedForeground
  var showsRules = true

  var body: some View {
    VStack(spacing: 8) {
      ForEach(Clinic.openingHoursText, id: \.day) { row in
        VStack(spacing: 8) {
          HStack {
            Text(row.day)
            Spacer()
            Text(row.hours)
          }
          if showsRules { Divider1() }
        }
      }
    }
    .bodyText(14)
    .foregroundStyle(color)
  }
}

/// Multi-line text input with a placeholder (`Textarea` on the web).
struct NotesEditor: View {
  @Binding var text: String
  let placeholder: String

  var body: some View {
    ZStack(alignment: .topLeading) {
      if text.isEmpty {
        Text(placeholder)
          .font(AppFont.body(16))
          .foregroundStyle(Palette.mutedForeground)
          .padding(.horizontal, 5)
          .padding(.vertical, 8)
          .allowsHitTesting(false)
      }
      TextEditor(text: $text)
        .font(AppFont.body(16))
        .foregroundStyle(Palette.foreground)
        .scrollContentBackground(.hidden)
        .frame(minHeight: 110)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Palette.card)
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.border, lineWidth: 1))
  }
}

/// Location, hours and contact block shown at the bottom of the public pages.
struct SiteFooter: View {
  @Environment(AppRouter.self) private var router

  var body: some View {
    VStack(alignment: .leading, spacing: 36) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Location").displayCaps(20)
        Link(destination: Clinic.mapsURL) {
          Text(Clinic.address)
            .bodyText(14)
            .multilineTextAlignment(.leading)
        }
        .opacity(0.9)
        Text("Free parking beside the clinic on Maundrell Lane.")
          .bodyText(14)
          .opacity(0.8)
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("Hours").displayCaps(20)
        OpeningHoursList(color: Palette.taupeForeground, showsRules: false)
          .opacity(0.9)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Contact").displayCaps(20)
        Link(Clinic.email, destination: Clinic.emailURL).bodyText(14)
        Link(Clinic.phone, destination: Clinic.phoneURL).bodyText(14)
        Button("Treatments & Fees") { router.tab = .treatments }
          .labelCaps()
          .padding(.top, 12)
      }

      Text("© \(Fmt.string(Date(), "yyyy")) \(Clinic.name), Salisbury.")
        .font(AppFont.body(12))
        .opacity(0.75)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    .foregroundStyle(Palette.taupeForeground)
    .tint(Palette.taupeForeground)
    .padding(.horizontal, 20)
    .padding(.vertical, 48)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.taupe)
    .padding(.top, 72)
  }
}

struct ToastOverlay: View {
  @Environment(Toaster.self) private var toaster

  var body: some View {
    VStack {
      if let toast = toaster.current {
        HStack(alignment: .top, spacing: 10) {
          Image(systemName: toast.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            .foregroundStyle(toast.isError ? Palette.destructive : Palette.primary)
          Text(toast.message)
            .bodyText(14)
            .foregroundStyle(Palette.foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Palette.card)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture { toaster.dismiss() }
        .accessibilityAddTraits(.isStaticText)
      }
      Spacer()
    }
    .animation(.spring(duration: 0.35), value: toaster.current)
    .allowsHitTesting(toaster.current != nil)
  }
}

extension View {
  /// Cream navigation bar with the clinic name, like the website header.
  func clinicNavigation() -> some View {
    self
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("Redbrook Clinic")
            .displayCaps(19)
            .foregroundStyle(Palette.foreground)
            .accessibilityAddTraits(.isHeader)
        }
      }
      .toolbarBackground(Palette.cream, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .background(Palette.background)
  }
}
