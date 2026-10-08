import SwiftUI

/// Mirrors src/routes/contact.tsx.
struct ContactView: View {
  @Environment(AppRouter.self) private var router

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("Contact us").displayCaps(30).accessibilityAddTraits(.isHeader)
        Text(
          "We are happy to answer any questions you may have about the treatments we provide. Consultations are complimentary and without obligation."
        )
        .mutedText(14)
        .padding(.top, 16)

        VStack(alignment: .leading, spacing: 48) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Get in touch").displayCaps(20).accessibilityAddTraits(.isHeader)
            Link(destination: Clinic.emailURL) {
              Label(Clinic.email, systemImage: "envelope")
            }
            .padding(.top, 8)
            Link(destination: Clinic.phoneURL) {
              Label(Clinic.phone, systemImage: "phone")
            }
            Button("Request an appointment") { router.tab = .book }
              .buttonStyle(.clinic(.primary))
              .padding(.top, 24)
          }
          .bodyText(14)
          .tint(Palette.mutedForeground)

          VStack(alignment: .leading, spacing: 16) {
            Text("Hours").displayCaps(20).accessibilityAddTraits(.isHeader)
            OpeningHoursList()
          }

          VStack(alignment: .leading, spacing: 16) {
            Text("When visiting us").displayCaps(20).accessibilityAddTraits(.isHeader)
            Link(destination: Clinic.mapsURL) {
              Label(Clinic.address, systemImage: "mappin.and.ellipse")
                .multilineTextAlignment(.leading)
            }
            .bodyText(14)
            .tint(Palette.mutedForeground)
            Text(
              "From Salisbury, take the A360 Devizes Road north out of the city and follow it for two miles. After the second roundabout (Fuggleston Red), turn left at the St Peter's Place roundabout, then take the first left onto Coberley Drive. We are just after the first left turning (Maundrell Lane) on the left side."
            )
            .mutedText(14)
            Text(
              "There is parking to the side of the property in Maundrell Lane, or you may park directly in front of the property."
            )
            .mutedText(14)
          }
        }
        .padding(.top, 48)
      }
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 20)
      .padding(.top, 48)

      SiteFooter()
    }
    .background(Palette.background)
    .clinicNavigation()
  }
}
