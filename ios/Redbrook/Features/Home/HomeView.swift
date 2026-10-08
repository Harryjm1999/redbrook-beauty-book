import SwiftUI

/// Mirrors src/routes/index.tsx.
struct HomeView: View {
  @Environment(AppRouter.self) private var router

  private let highlights: [(title: String, body: String)] = [
    ("PDO Threads", "A revolutionary non-surgical lift, using polydioxanone threads to lift and stimulate collagen."),
    ("Advanced Skincare", "CO2 laser resurfacing, chemical peels, microdermabrasion, micro-needling and carbon facials."),
    ("Anti Ageing", "Wrinkle relaxing injections, dermal fillers, mesotherapy, Profhilo, Sunekos and Sculptra."),
    ("Body Image", "Cryo fat freezing, laser hair removal, semi-permanent make up and weight loss support."),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        hero
        whatWeDo
        treatments
        booking
        SiteFooter()
      }
    }
    .background(Palette.background)
    .clinicNavigation()
  }

  private var hero: some View {
    ZStack {
      Image("Hero")
        .resizable()
        .scaledToFill()
        .frame(height: 480)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityLabel("Calm treatment room at Redbrook Clinic with eucalyptus in a glass vase")

      VStack(spacing: 20) {
        Text("Welcome to Redbrook Clinic")
          .displayCaps(30)
          .multilineTextAlignment(.center)
          .accessibilityAddTraits(.isHeader)
        Text(Clinic.tagline)
          .bodyText(14)
          .multilineTextAlignment(.center)
          .opacity(0.95)
        Button("Book an appointment") { router.tab = .book }
          .buttonStyle(.clinic(.secondary, size: .large))
          .padding(.top, 12)
      }
      .foregroundStyle(Palette.sageForeground)
      .padding(.horizontal, 28)
      .padding(.vertical, 40)
      .background(Palette.sage.opacity(0.9))
      .padding(.horizontal, 20)
    }
  }

  private var whatWeDo: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("What we do at the Redbrook Clinic")
        .displayCaps(24)
        .accessibilityAddTraits(.isHeader)
      Text(
        "At Redbrook Clinic we cater for all your non-surgical cosmetic and beauty treatments to help make you look the best that you possibly can. We offer the latest innovative treatments for face and body, for both men and women."
      )
      .bodyText(14)
      .opacity(0.95)
      .padding(.top, 24)
      Text(
        "We specialise in soft, subtle, natural facial rejuvenation and body contouring procedures, alongside gold standard fillers and anti-ageing consultations — all within a friendly and relaxing atmosphere."
      )
      .bodyText(14)
      .opacity(0.95)
      .padding(.top, 16)
      Button("View treatments & fees") { router.tab = .treatments }
        .buttonStyle(.clinic(.secondary))
        .padding(.top, 32)
      Image("Treatment")
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity)
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        .padding(.top, 48)
        .accessibilityLabel("A patient receiving a gentle non-surgical facial treatment")
    }
    .foregroundStyle(Palette.taupeForeground)
    .padding(.horizontal, 20)
    .padding(.vertical, 64)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.taupe)
  }

  private var treatments: some View {
    VStack(spacing: 0) {
      Text("Our treatments")
        .displayCaps(24)
        .multilineTextAlignment(.center)
        .accessibilityAddTraits(.isHeader)
      VStack(alignment: .leading, spacing: 32) {
        ForEach(highlights, id: \.title) { item in
          VStack(alignment: .leading, spacing: 12) {
            Divider1()
            Text(item.title).displayCaps(20).padding(.top, 12)
            Text(item.body).mutedText(14)
          }
        }
      }
      .padding(.top, 40)
      Button("See the full list") { router.tab = .treatments }
        .buttonStyle(.clinic(.primary, size: .large))
        .padding(.top, 48)
    }
    .foregroundStyle(Palette.foreground)
    .padding(.horizontal, 20)
    .padding(.vertical, 64)
  }

  private var booking: some View {
    VStack(alignment: .leading, spacing: 48) {
      VStack(alignment: .leading, spacing: 24) {
        Text("Booking with us").displayCaps(24).accessibilityAddTraits(.isHeader)
        Text(
          "Create an account with your contact details, choose your treatment and pick a time that suits you. Louise will review every request and confirm your appointment personally. Consultations are always complimentary."
        )
        .mutedText(14)
        Button("Request an appointment") { router.tab = .book }
          .buttonStyle(.clinic(.primary))
          .padding(.top, 8)
      }
      VStack(alignment: .leading, spacing: 24) {
        Text("Opening hours").displayCaps(24).accessibilityAddTraits(.isHeader)
        OpeningHoursList()
      }
    }
    .foregroundStyle(Palette.foreground)
    .padding(.horizontal, 20)
    .padding(.vertical, 64)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.cream)
  }
}
