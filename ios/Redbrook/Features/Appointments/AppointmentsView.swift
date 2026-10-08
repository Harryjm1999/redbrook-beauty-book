import SwiftUI

/// Mirrors src/routes/_authenticated/appointments.tsx, plus in-app account deletion
/// (required by App Store Review Guideline 5.1.1(v)).
struct AppointmentsView: View {
  @Environment(SessionStore.self) private var session
  @Environment(AppRouter.self) private var router
  @Environment(Toaster.self) private var toaster

  @State private var bookings: [Booking]?
  @State private var cancelling = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("My appointments")
          .displayCaps(30)
          .accessibilityAddTraits(.isHeader)
        HStack(spacing: 8) {
          if session.isStaff {
            NavigationLink("Clinic diary") { AdminView() }
              .buttonStyle(.clinic(.outline))
          }
          Button("New request") { router.tab = .book }
            .buttonStyle(.clinic(.primary))
        }
        .padding(.top, 16)

        list.padding(.top, 40)

        ProfileSection()
          .padding(.top, 64)
      }
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 20)
      .padding(.vertical, 48)
    }
    .scrollDismissesKeyboard(.interactively)
    .background(Palette.background)
    .task(id: router.bookingsVersion) { await load() }
    .refreshable { await load() }
  }

  @ViewBuilder
  private var list: some View {
    if bookings == nil {
      VStack(spacing: 12) {
        ForEach(0..<3, id: \.self) { _ in SkeletonBlock(height: 96) }
      }
    } else if let bookings, bookings.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        Text("You don't have any appointments yet.").mutedText(14)
        Button("Request one now") { router.tab = .book }
          .font(AppFont.body(14))
          .underline()
          .foregroundStyle(Palette.foreground)
      }
    } else if let bookings {
      VStack(spacing: 16) {
        ForEach(bookings) { booking in
          row(booking)
        }
      }
    }
  }

  private func row(_ booking: Booking) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(booking.treatmentName).bodyText(18)
        Spacer(minLength: 12)
        Badge(
          text: booking.status?.patientLabel ?? booking.statusRaw,
          filled: booking.status == .confirmed
        )
      }
      Text(Fmt.string(booking.startsAt, "EEEE d MMMM yyyy 'at' h:mma"))
        .mutedText(14)
        .padding(.top, 4)
      if let note = booking.patientNotes, !note.isEmpty {
        Text("Your note: \(note)").mutedText(14).padding(.top, 12)
      }
      if let note = booking.staffNotes, !note.isEmpty {
        Text("From the clinic: \(note)").bodyText(14).padding(.top, 8)
      }
      if booking.status == .pending || booking.status == .confirmed {
        Button("Cancel") { cancel(booking) }
          .buttonStyle(.clinic(.ghost, size: .small))
          .disabled(cancelling)
          .frame(maxWidth: .infinity, alignment: .trailing)
          .padding(.top, 8)
      }
    }
    .cardBox(padding: 22)
  }

  private func load() async {
    guard let userId = session.user?.id else { return }
    do {
      bookings = try await API.myBookings(userId: userId)
    } catch {
      if bookings == nil { bookings = [] }
      toaster.error(error)
    }
  }

  private func cancel(_ booking: Booking) {
    cancelling = true
    Task {
      do {
        try await API.setStatus(bookingId: booking.id, status: .cancelled)
        toaster.success("Appointment cancelled.")
        router.bookingsChanged()
      } catch {
        toaster.error(error)
      }
      cancelling = false
    }
  }
}

private struct ProfileSection: View {
  @Environment(SessionStore.self) private var session
  @Environment(Toaster.self) private var toaster

  @State private var profile: Profile?
  @State private var fullName = ""
  @State private var phone = ""
  @State private var saving = false
  @State private var confirmingDelete = false
  @State private var deleting = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Divider1()
      Text("Your contact details")
        .displayCaps(24)
        .padding(.top, 40)
        .accessibilityAddTraits(.isHeader)
      Text("We use these to confirm your appointments — please keep them up to date.")
        .mutedText(14)
        .padding(.top, 8)

      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Full name")
          TextField("", text: $fullName)
            .textContentType(.name)
            .clinicField()
            .accessibilityLabel("Full name")
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Contact number")
          TextField("", text: $phone)
            .textContentType(.telephoneNumber)
            .keyboardType(.phonePad)
            .clinicField()
            .accessibilityLabel("Contact number")
        }
      }
      .padding(.top, 24)

      Text("Email: \(profile?.email ?? "—")")
        .mutedText(14)
        .padding(.top, 16)

      Button(saving ? "Saving…" : "Save details", action: save)
        .buttonStyle(.clinic(.primary))
        .disabled(saving)
        .padding(.top, 24)

      Divider1().padding(.top, 48)
      Text("Account").displayCaps(20).padding(.top, 32)
      HStack(spacing: 8) {
        Button("Sign out") { Task { await session.signOut() } }
          .buttonStyle(.clinic(.outline))
        Button(deleting ? "Deleting…" : "Delete account") { confirmingDelete = true }
          .buttonStyle(.clinic(.destructive))
          .disabled(deleting)
      }
      .padding(.top, 16)
    }
    .task(id: session.user?.id) { await load() }
    .alert("Delete your account?", isPresented: $confirmingDelete) {
      Button("Delete account", role: .destructive, action: deleteAccount)
      Button("Keep my account", role: .cancel) {}
    } message: {
      Text("This permanently deletes your account, contact details and appointment history. It can't be undone.")
    }
  }

  private func load() async {
    guard let userId = session.user?.id else { return }
    if let loaded = try? await API.myProfile(userId: userId) {
      profile = loaded
      fullName = loaded.fullName
      phone = loaded.phone ?? ""
    }
  }

  private func save() {
    guard let userId = session.user?.id else { return }
    saving = true
    Task {
      do {
        try await API.updateProfile(userId: userId, fullName: fullName, phone: phone)
        toaster.success("Contact details updated.")
      } catch {
        toaster.error(error)
      }
      saving = false
    }
  }

  private func deleteAccount() {
    deleting = true
    Task {
      do {
        try await API.deleteMyAccount()
        await session.signOut()
        toaster.success("Your account has been deleted.")
      } catch {
        toaster.error("We couldn't delete your account. Please try again, or contact the clinic.")
      }
      deleting = false
    }
  }
}
