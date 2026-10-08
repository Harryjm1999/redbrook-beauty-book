import SwiftUI

/// Mirrors src/routes/about.tsx.
struct AboutView: View {
  @Environment(AppRouter.self) private var router

  private let testimonials: [(quote: String, name: String)] = [
    (
      "Currently having laser removal. I was a bit dubious to start with, but the process so far has been amazing and Louise has been lovely. Would highly recommend.",
      "Elie Sims"
    ),
    (
      "Fantastic service, lovely clinic and extremely professional and knowledgeable. I feel very comfortable at every visit. So many treatments available, highly recommend!",
      "Laura Elizabeth"
    ),
    (
      "Louise not only provides excellent treatments but she is also so friendly, she put me totally at ease. Her clinic is beautiful with a calm, relaxing atmosphere and spotlessly clean.",
      "Verified patient"
    ),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        VStack(spacing: 16) {
          Text("Welcome").labelCaps().foregroundStyle(Palette.mutedForeground)
          Text("About the clinic").displayCaps(30).accessibilityAddTraits(.isHeader)
          Text(
            "Redbrook Clinic is a private cosmetic and aesthetics clinic operating from the outskirts of the historic market town of Salisbury, with easy access and parking. The clinic is owned and run by Louise Oatley."
          )
          .mutedText(14)
          .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .padding(.top, 48)

        VStack(alignment: .leading, spacing: 0) {
          Image("Treatment")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Louise Oatley carrying out a facial treatment at Redbrook Clinic")
          Text("About Louise Oatley")
            .displayCaps(24)
            .padding(.top, 40)
            .accessibilityAddTraits(.isHeader)
          VStack(alignment: .leading, spacing: 16) {
            Text(
              "“I have been working in the cosmetic industry since 1988. My professional career has included working as a private therapist to Princess Diana for several years and teaching beauty and aesthetics."
            )
            Text(
              "I have been in practice for over 30 years, in that time working in high end beauty clinics and with cosmetic surgeons. I now run my own exclusive private clinic. I am highly qualified, fully insured and registered with professional bodies for the aesthetics industry.”"
            )
          }
          .mutedText(14)
          .padding(.top, 24)
          Text("Redbrook Clinic provides a highly professional yet friendly service in a relaxed, comfortable setting.")
            .mutedText(14)
            .padding(.top, 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)

        VStack(spacing: 0) {
          Text("What our patients say")
            .displayCaps(24)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
          VStack(alignment: .leading, spacing: 32) {
            ForEach(testimonials, id: \.name) { item in
              VStack(alignment: .leading, spacing: 16) {
                Divider1()
                Text("“\(item.quote)”").mutedText(14).padding(.top, 8)
                Text(item.name).labelCaps()
              }
              .accessibilityElement(children: .combine)
            }
          }
          .padding(.top, 40)
          Button("Book an appointment") { router.tab = .book }
            .buttonStyle(.clinic(.primary, size: .large))
            .padding(.top, 48)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity)
        .background(Palette.cream)
        .padding(.top, 80)

        SiteFooter()
      }
      .foregroundStyle(Palette.foreground)
    }
    .background(Palette.background)
    .clinicNavigation()
  }
}
