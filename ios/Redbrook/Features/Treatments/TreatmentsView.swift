import SwiftUI

/// Mirrors src/routes/treatments.tsx.
struct TreatmentsView: View {
  @Environment(AppRouter.self) private var router

  @State private var treatments: [Treatment]?
  @State private var failed = false

  private var grouped: [(category: String, items: [Treatment])] {
    var order: [String] = []
    var groups: [String: [Treatment]] = [:]
    for treatment in treatments ?? [] {
      if groups[treatment.category] == nil { order.append(treatment.category) }
      groups[treatment.category, default: []].append(treatment)
    }
    return order.map { ($0, groups[$0] ?? []) }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("Treatments & fees")
          .displayCaps(30)
          .accessibilityAddTraits(.isHeader)
        Text(
          "Consultations are complimentary — we discuss your needs and design an individual plan to suit you. Prices are a guide and are confirmed at consultation."
        )
        .mutedText(14)
        .padding(.top, 16)

        content.padding(.top, 48)

        Button("Request an appointment") { router.tab = .book }
          .buttonStyle(.clinic(.primary, size: .large))
          .frame(maxWidth: .infinity)
          .padding(.top, 64)
      }
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 20)
      .padding(.top, 48)

      SiteFooter()
    }
    .background(Palette.background)
    .clinicNavigation()
    .task { if treatments == nil { await load() } }
    .refreshable { await load() }
  }

  @ViewBuilder
  private var content: some View {
    if failed && treatments == nil {
      Text("We couldn't load the treatment list. Please refresh, or call the clinic.")
        .bodyText(14)
        .foregroundStyle(Palette.destructive)
    } else if treatments == nil {
      VStack(spacing: 16) {
        ForEach(0..<6, id: \.self) { _ in SkeletonBlock(height: 64) }
      }
    } else {
      VStack(alignment: .leading, spacing: 56) {
        ForEach(grouped, id: \.category) { group in
          VStack(alignment: .leading, spacing: 0) {
            Text(group.category).displayCaps(22).accessibilityAddTraits(.isHeader)
            Divider1().padding(.top, 12)
            VStack(alignment: .leading, spacing: 24) {
              ForEach(group.items) { treatment in
                TreatmentRow(treatment: treatment)
              }
            }
            .padding(.top, 24)
          }
        }
      }
    }
  }

  private func load() async {
    do {
      treatments = try await API.treatments()
      failed = false
    } catch {
      failed = true
    }
  }
}

private struct TreatmentRow: View {
  let treatment: Treatment

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline) {
        Text(treatment.name).bodyText(16)
        Spacer(minLength: 12)
        Text(treatment.priceLabel)
          .bodyText(14)
          .multilineTextAlignment(.trailing)
      }
      if let description = treatment.description, !description.isEmpty {
        Text(description).mutedText(14)
      }
      Text("\(treatment.durationMinutes) minutes")
        .labelCaps()
        .foregroundStyle(Palette.mutedForeground)
        .padding(.top, 2)
    }
    .accessibilityElement(children: .combine)
  }
}
