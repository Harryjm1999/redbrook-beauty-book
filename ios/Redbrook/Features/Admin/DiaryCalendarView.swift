import SwiftUI

/// Month calendar, per-slot day view and upcoming list for staff.
/// Mirrors src/components/DiaryCalendar.tsx.
struct DiaryCalendarView: View {
  @Environment(SessionStore.self) private var session
  @Environment(AppRouter.self) private var router
  @Environment(Toaster.self) private var toaster

  let bookings: [DiaryBooking]
  let isLoading: Bool

  @State private var selected = Calendar.current.startOfDay(for: Date())
  @State private var blocked: [BlockedDate] = []
  @State private var toggling = false

  private struct DaySlot: Identifiable {
    let minutes: Int
    let label: String
    let start: Date
    let end: Date
    let booking: DiaryBooking?
    var id: Int { minutes }
  }

  private var active: [DiaryBooking] {
    bookings.filter { $0.booking.status == .confirmed || $0.booking.status == .pending }
  }

  private var confirmedKeys: Set<String> {
    Set(active.filter { $0.booking.status == .confirmed }.map { Fmt.dateKey($0.booking.startsAt) })
  }

  private var pendingKeys: Set<String> {
    Set(active.filter { $0.booking.status == .pending }.map { Fmt.dateKey($0.booking.startsAt) })
  }

  private var blockedKeys: Set<String> { Set(blocked.map(\.day)) }

  private var slots: [DaySlot] {
    guard let hours = Clinic.hours(on: selected) else { return [] }
    let calendar = Calendar.current
    let midnight = calendar.startOfDay(for: selected)
    let dayBookings = active.filter { calendar.isDate($0.booking.startsAt, inSameDayAs: selected) }
    var result: [DaySlot] = []
    var m = hours.open
    while m < hours.close {
      let start = calendar.date(byAdding: .minute, value: m, to: midnight)!
      let end = start.addingTimeInterval(TimeInterval(Clinic.slotStepMinutes * 60))
      let booking = dayBookings.first { start < $0.booking.endsAt && end > $0.booking.startsAt }
      result.append(DaySlot(minutes: m, label: minutesToLabel(m), start: start, end: end, booking: booking))
      m += Clinic.slotStepMinutes
    }
    return result
  }

  private var upcoming: [DiaryBooking] {
    let now = Date()
    return active
      .filter { !$0.booking.isStaffBlock && $0.booking.startsAt >= now }
      .sorted { $0.booking.startsAt < $1.booking.startsAt }
      .prefix(10)
      .map { $0 }
  }

  var body: some View {
    if isLoading {
      SkeletonBlock(height: 320)
    } else {
      VStack(alignment: .leading, spacing: 40) {
        VStack(alignment: .leading, spacing: 12) {
          MonthCalendar(
            selected: $selected,
            confirmed: confirmedKeys,
            pending: pendingKeys,
            blocked: blockedKeys
          )
          Text("Underlined = confirmed bookings · italic = pending requests · struck through = blocked day")
            .font(AppFont.body(12))
            .foregroundStyle(Palette.mutedForeground)
        }
        .cardBox(padding: 16)

        dayDetail
        upcomingSection
      }
      .task { await loadBlocked() }
    }
  }

  private var dayDetail: some View {
    let isBlocked = blockedKeys.contains(Fmt.dateKey(selected))
    return VStack(alignment: .leading, spacing: 0) {
      Text(Fmt.string(selected, "EEEE d MMMM yyyy")).displayCaps(20)
      if isBlocked {
        Text("This day is blocked — patients can't request it.")
          .mutedText(14)
          .padding(.top, 8)
      }
      if Clinic.hours(on: selected) == nil {
        Text("Closed on this day.").mutedText(14).padding(.top, 16)
      } else {
        VStack(spacing: 8) {
          ForEach(slots) { slot in
            slotRow(slot, dayBlocked: isBlocked)
          }
        }
        .padding(.top, 16)
      }
    }
  }

  private func slotRow(_ slot: DaySlot, dayBlocked: Bool) -> some View {
    let taken = slot.booking != nil
    let confirmed = slot.booking?.booking.status == .confirmed
    let isStaffBlock = slot.booking?.booking.isStaffBlock ?? false

    return HStack(spacing: 12) {
      Text(slot.label).labelCaps()
      Spacer()
      if let item = slot.booking, !isStaffBlock {
        VStack(alignment: .trailing, spacing: 2) {
          Text(item.patientName)
          Text(item.booking.treatmentName + (confirmed ? "" : " (request)"))
        }
        .font(AppFont.body(12))
        .multilineTextAlignment(.trailing)
      } else {
        Text(dayBlocked ? "Blocked" : isStaffBlock ? "Booked" : "Free")
          .font(AppFont.body(12))
        Toggle(
          isStaffBlock ? "Mark slot free" : "Mark slot booked",
          isOn: Binding(
            get: { isStaffBlock },
            set: { _ in toggle(slot) }
          )
        )
        .labelsHidden()
        .tint(Palette.primary)
        .disabled(toggling)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .foregroundStyle(taken || dayBlocked ? Palette.mutedForeground : Palette.foreground)
    .background(taken || dayBlocked ? Palette.muted : Palette.card)
    .overlay(Rectangle().stroke(Palette.border, lineWidth: 1))
  }

  private var upcomingSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Upcoming appointments").displayCaps(20)
      if upcoming.isEmpty {
        Text("Nothing booked in yet.").mutedText(14)
      } else {
        VStack(spacing: 8) {
          ForEach(upcoming) { item in
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 4) {
                Text(item.patientName).bodyText(16)
                Text("\(item.booking.treatmentName) · \(Fmt.string(item.booking.startsAt, "EEE d MMM yyyy, h:mma"))")
                  .mutedText(14)
              }
              Spacer(minLength: 12)
              Badge(text: item.booking.statusRaw, filled: item.booking.status == .confirmed)
            }
            .cardBox(padding: 16)
          }
        }
      }
    }
  }

  private func loadBlocked() async {
    if let rows = try? await API.blockedDates() { blocked = rows }
  }

  private func toggle(_ slot: DaySlot) {
    guard let userId = session.user?.id else { return }
    toggling = true
    Task {
      do {
        if let item = slot.booking {
          try await API.unblockSlot(bookingId: item.booking.id)
        } else {
          try await API.blockSlot(userId: userId, start: slot.start, end: slot.end)
        }
        toaster.success("Slot updated.")
        router.bookingsChanged()
      } catch {
        toaster.error(error)
      }
      toggling = false
    }
  }
}

/// Month grid starting on Monday, marking confirmed, pending and blocked days.
struct MonthCalendar: View {
  @Binding var selected: Date
  let confirmed: Set<String>
  let pending: Set<String>
  let blocked: Set<String>

  @State private var month = Calendar.current.dateInterval(of: .month, for: Date())!.start

  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    calendar.timeZone = .current
    calendar.locale = Locale(identifier: "en_GB")
    return calendar
  }

  private var days: [Date?] {
    guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
    let leading = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
    let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    return Array(repeating: nil, count: leading) + dates.map { Optional($0) }
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Button { shift(-1) } label: { Image(systemName: "chevron.left") }
          .accessibilityLabel("Previous month")
        Spacer()
        Text(Fmt.string(month, "MMMM yyyy")).bodyText(15)
        Spacer()
        Button { shift(1) } label: { Image(systemName: "chevron.right") }
          .accessibilityLabel("Next month")
      }
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 4)

      let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
      LazyVGrid(columns: columns, spacing: 6) {
        ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { symbol in
          Text(symbol)
            .font(AppFont.body(12))
            .foregroundStyle(Palette.mutedForeground)
        }
        ForEach(Array(days.enumerated()), id: \.offset) { _, date in
          if let date {
            dayCell(date)
          } else {
            Color.clear.frame(height: 36)
          }
        }
      }
    }
  }

  private func dayCell(_ date: Date) -> some View {
    let key = Fmt.dateKey(date)
    let isSelected = calendar.isDate(date, inSameDayAs: selected)
    let isToday = calendar.isDateInToday(date)
    let isConfirmed = confirmed.contains(key)
    let isPending = pending.contains(key)
    let isBlocked = blocked.contains(key)

    return Button {
      selected = calendar.startOfDay(for: date)
    } label: {
      Text("\(calendar.component(.day, from: date))")
        .font(.system(size: 15, weight: isConfirmed ? .semibold : .regular))
        .italic(isPending)
        .underline(isConfirmed)
        .strikethrough(isBlocked)
        .opacity(isBlocked ? 0.4 : 1)
        .frame(maxWidth: .infinity, minHeight: 36)
        .foregroundStyle(isSelected ? Palette.primaryForeground : Palette.foreground)
        .background(isSelected ? Palette.primary : isToday ? Palette.secondary : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(dayAccessibilityLabel(date, confirmed: isConfirmed, pending: isPending, blocked: isBlocked))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private func dayAccessibilityLabel(_ date: Date, confirmed: Bool, pending: Bool, blocked: Bool) -> String {
    var parts = [Fmt.string(date, "EEEE d MMMM")]
    if confirmed { parts.append("confirmed bookings") }
    if pending { parts.append("pending requests") }
    if blocked { parts.append("blocked") }
    return parts.joined(separator: ", ")
  }

  private func shift(_ months: Int) {
    if let next = calendar.date(byAdding: .month, value: months, to: month) {
      month = next
    }
  }
}
