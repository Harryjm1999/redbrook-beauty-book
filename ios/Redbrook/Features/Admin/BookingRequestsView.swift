import SwiftUI

/// Pending requests with Accept and Deny. Mirrors src/components/BookingRequests.tsx.
struct BookingRequestsView: View {
  @Environment(AppRouter.self) private var router
  @Environment(Toaster.self) private var toaster

  let requests: [DiaryBooking]
  let isLoading: Bool

  @State private var deciding = false

  var body: some View {
    if isLoading {
      SkeletonBlock(height: 160)
    } else if requests.isEmpty {
      Text("No requests waiting right now.").mutedText(14)
    } else {
      VStack(spacing: 12) {
        ForEach(requests) { item in
          row(item)
        }
      }
    }
  }

  private func row(_ item: DiaryBooking) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      PatientContact(patient: item.patient, name: item.patientName)
      Text("\(item.booking.treatmentName) · \(Fmt.string(item.booking.startsAt, "EEE d MMM yyyy, h:mma"))")
        .mutedText(14)
        .padding(.top, 6)
      if let note = item.booking.patientNotes, !note.isEmpty {
        Text("Note: \(note)").mutedText(14).padding(.top, 6)
      }
      HStack(spacing: 8) {
        Spacer()
        Button("Accept") { decide(item, accept: true) }
          .buttonStyle(.clinic(.primary, size: .small))
        Button("Deny") { decide(item, accept: false) }
          .buttonStyle(.clinic(.outline, size: .small))
      }
      .disabled(deciding)
      .padding(.top, 14)
    }
    .cardBox(padding: 18)
  }

  private func decide(_ item: DiaryBooking, accept: Bool) {
    deciding = true
    Task {
      do {
        try await API.setStatus(
          bookingId: item.booking.id,
          status: accept ? .confirmed : .declined,
          staffNotes: accept ? API.acceptMessage : API.denyMessage
        )
        toaster.success(
          accept
            ? "Accepted — confirmation sent to the patient."
            : "Declined — the patient has been told you'll be in touch with a new time."
        )
        router.bookingsChanged()
      } catch {
        toaster.error(error)
      }
      deciding = false
    }
  }
}
