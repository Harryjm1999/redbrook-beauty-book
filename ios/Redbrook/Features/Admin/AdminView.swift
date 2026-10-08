import SwiftUI

/// Staff-only clinic diary. Mirrors src/routes/_authenticated/admin.tsx.
struct AdminView: View {
  @Environment(SessionStore.self) private var session
  @Environment(AppRouter.self) private var router
  @Environment(Toaster.self) private var toaster

  enum Section: Hashable { case calendar, pending, upcoming }

  @State private var section: Section = .calendar
  @State private var bookings: [DiaryBooking]?
  @State private var updating = false

  private var all: [DiaryBooking] {
    (bookings ?? []).filter { !$0.booking.isStaffBlock }
  }

  private var pending: [DiaryBooking] {
    all.filter { $0.booking.status == .pending }
  }

  private var upcoming: [DiaryBooking] {
    let now = Date()
    return all.filter { $0.booking.status == .confirmed && $0.booking.startsAt >= now }
  }

  var body: some View {
    Group {
      if session.user == nil {
        ScrollView { AuthView(initialMode: .signin) }
      } else if session.isCheckingStaff {
        SkeletonBlock(height: 160).padding(20)
        Spacer()
      } else if !session.isStaff {
        staffOnly
      } else {
        diary
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Palette.background)
    .clinicNavigation()
  }

  private var staffOnly: some View {
    VStack(spacing: 16) {
      Text("Staff only").displayCaps(30).accessibilityAddTraits(.isHeader)
      Text(
        "This area is for clinic staff. If you should have access, ask the clinic owner to add your account to the staff list."
      )
      .mutedText(14)
      PolicyLinks().padding(.top, 40)
    }
    .multilineTextAlignment(.center)
    .foregroundStyle(Palette.foreground)
    .padding(.horizontal, 20)
    .padding(.vertical, 72)
  }

  private var diary: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("Clinic diary").displayCaps(30).accessibilityAddTraits(.isHeader)
        Text("Review requests, confirm appointments and see patient contact details.")
          .mutedText(14)
          .padding(.top, 16)

        Picker("Section", selection: $section) {
          Text("CALENDAR").tag(Section.calendar)
          Text("REQUESTS (\(pending.count))").tag(Section.pending)
          Text("UPCOMING (\(upcoming.count))").tag(Section.upcoming)
        }
        .pickerStyle(.segmented)
        .padding(.top, 32)

        Group {
          switch section {
          case .calendar:
            DiaryCalendarView(bookings: bookings ?? [], isLoading: bookings == nil)
          case .pending:
            BookingRequestsView(requests: pending, isLoading: bookings == nil)
          case .upcoming:
            upcomingList
          }
        }
        .padding(.top, 24)

        PolicyLinks().padding(.top, 56)
      }
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 20)
      .padding(.vertical, 48)
    }
    .task(id: router.bookingsVersion) { await load() }
    .refreshable { await load() }
  }

  @ViewBuilder
  private var upcomingList: some View {
    if bookings == nil {
      SkeletonBlock(height: 160)
    } else if upcoming.isEmpty {
      Text("Nothing here right now.").mutedText(14)
    } else {
      VStack(spacing: 16) {
        ForEach(upcoming) { item in
          upcomingRow(item)
        }
      }
    }
  }

  private func upcomingRow(_ item: DiaryBooking) -> some View {
    let booking = item.booking
    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(booking.treatmentName).bodyText(18)
        Spacer(minLength: 12)
        Badge(text: booking.statusRaw, filled: booking.status == .confirmed)
      }
      Text(
        "\(Fmt.string(booking.startsAt, "EEEE d MMMM yyyy 'at' h:mma")) – \(Fmt.string(booking.endsAt, "h:mma"))"
      )
      .mutedText(14)
      .padding(.top, 4)
      PatientContact(patient: item.patient, name: item.patientName)
        .padding(.top, 12)
      if let note = booking.patientNotes, !note.isEmpty {
        Text("Note: \(note)").mutedText(14).padding(.top, 8)
      }
      HStack(spacing: 8) {
        Spacer()
        if booking.status != .confirmed {
          Button("Confirm") { setStatus(booking, .confirmed) }
            .buttonStyle(.clinic(.primary, size: .small))
        }
        if booking.status == .pending {
          Button("Decline") { setStatus(booking, .declined) }
            .buttonStyle(.clinic(.outline, size: .small))
        }
        if booking.status == .confirmed {
          Button("Cancel") { setStatus(booking, .cancelled) }
            .buttonStyle(.clinic(.outline, size: .small))
        }
      }
      .disabled(updating)
      .padding(.top, 16)
    }
    .cardBox(padding: 22)
  }

  private func load() async {
    guard session.isStaff else { return }
    do {
      bookings = try await API.allBookings()
    } catch {
      if bookings == nil { bookings = [] }
      toaster.error(error)
    }
  }

  private func setStatus(_ booking: Booking, _ status: BookingStatus) {
    updating = true
    Task {
      do {
        try await API.setStatus(bookingId: booking.id, status: status)
        toaster.success("Booking updated.")
        router.bookingsChanged()
      } catch {
        toaster.error(error)
      }
      updating = false
    }
  }
}

/// Patient name with tap-to-call and tap-to-email links.
struct PatientContact: View {
  let patient: Profile?
  let name: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(name).bodyText(14)
      HStack(spacing: 16) {
        if let phone = patient?.phone, !phone.isEmpty,
          let url = URL(string: "tel:\(phone.filter { !$0.isWhitespace })")
        {
          Link(destination: url) { Label(phone, systemImage: "phone") }
        } else {
          Text("no phone")
        }
        if let email = patient?.email, !email.isEmpty, let url = URL(string: "mailto:\(email)") {
          Link(destination: url) { Label(email, systemImage: "envelope").lineLimit(1) }
        } else {
          Text("no email")
        }
      }
      .font(AppFont.body(13))
      .foregroundStyle(Palette.mutedForeground)
      .tint(Palette.foreground)
    }
  }
}
