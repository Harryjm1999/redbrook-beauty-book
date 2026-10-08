import SwiftUI

/// Mirrors src/routes/_authenticated/book.tsx.
struct BookView: View {
  @Environment(SessionStore.self) private var session
  @Environment(AppRouter.self) private var router
  @Environment(Toaster.self) private var toaster

  private static let daysAhead = 42

  @State private var treatments: [Treatment]?
  @State private var blocked: [String: String?] = [:]
  @State private var treatmentId: UUID?
  @State private var day: Date?
  @State private var busy: [BusyRange] = []
  @State private var loadingSlots = false
  @State private var slotStart: Date?
  @State private var notes = ""
  @State private var sending = false

  private var treatment: Treatment? {
    treatments?.first { $0.id == treatmentId }
  }

  private var openDays: [Date] {
    let calendar = Clinic.calendar
    let today = calendar.startOfDay(for: Date())
    return (0..<Self.daysAhead)
      .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
      .filter { Clinic.hours(on: $0) != nil }
  }

  private var slots: [Slot] {
    guard let day, let treatment else { return [] }
    return SlotBuilder.slots(on: day, durationMinutes: treatment.durationMinutes, busy: busy)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text("Request an appointment")
          .displayCaps(30)
          .accessibilityAddTraits(.isHeader)
        Text(
          "Pick your treatment and a time that suits you. Every request is reviewed by the clinic and confirmed by email — you'll see the status in My Appointments."
        )
        .mutedText(14)
        .padding(.top, 16)

        VStack(alignment: .leading, spacing: 40) {
          treatmentStep
          dayStep
          timeStep
          notesStep
          summary
        }
        .padding(.top, 48)

        PolicyLinks().padding(.top, 56)
      }
      .foregroundStyle(Palette.foreground)
      .padding(.horizontal, 20)
      .padding(.vertical, 48)
    }
    .scrollDismissesKeyboard(.interactively)
    .background(Palette.background)
    .task { await loadOptions() }
    .task(id: day) { await loadBusy() }
    .refreshable {
      await loadOptions()
      await loadBusy()
    }
  }

  // MARK: Steps

  private var treatmentStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      FieldLabel("1. Choose a treatment")
      if let treatments {
        Menu {
          Picker("Treatment", selection: $treatmentId) {
            ForEach(treatments) { t in
              Text("\(t.name) · \(t.durationMinutes) min · \(t.priceLabel)").tag(Optional(t.id))
            }
          }
        } label: {
          HStack {
            Text(treatment.map { "\($0.name) · \($0.durationMinutes) min · \($0.priceLabel)" }
              ?? "Select a treatment or consultation")
              .foregroundStyle(treatment == nil ? Palette.mutedForeground : Palette.foreground)
              .multilineTextAlignment(.leading)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
              .font(.footnote)
              .foregroundStyle(Palette.mutedForeground)
          }
          .clinicField()
        }
        .onChange(of: treatmentId) { slotStart = nil }
      } else {
        SkeletonBlock(height: 44)
      }
    }
  }

  private var dayStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      FieldLabel("2. Choose a day")
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(openDays, id: \.self) { d in
            dayButton(d)
          }
        }
        .padding(.bottom, 4)
      }
    }
  }

  private func dayButton(_ d: Date) -> some View {
    let key = Fmt.dateKey(d)
    let isBlocked = blocked[key] != nil
    let selected = day.map { Clinic.calendar.isDate($0, inSameDayAs: d) } ?? false

    return Button {
      day = d
      slotStart = nil
    } label: {
      VStack(spacing: 4) {
        Text(Fmt.string(d, "EEE")).labelCaps()
        Text(Fmt.string(d, "d")).bodyText(18)
        Text(Fmt.string(d, "MMM")).font(AppFont.body(12)).opacity(0.8)
      }
      .strikethrough(isBlocked)
      .frame(minWidth: 72)
      .padding(.vertical, 12)
      .foregroundStyle(
        isBlocked ? Palette.mutedForeground.opacity(0.5) : selected ? Palette.primaryForeground : Palette.foreground
      )
      .background(isBlocked ? Palette.muted : selected ? Palette.primary : Palette.card)
      .overlay(
        Rectangle().strokeBorder(
          selected ? Palette.primary : Palette.border,
          style: StrokeStyle(lineWidth: 1, dash: isBlocked ? [4] : [])
        )
      )
    }
    .buttonStyle(.plain)
    .disabled(isBlocked)
    .accessibilityLabel(Fmt.string(d, "EEEE d MMMM") + (isBlocked ? ", unavailable" : ""))
    .accessibilityHint(isBlocked ? ((blocked[key] ?? nil) ?? "Fully booked") : "")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  @ViewBuilder
  private var timeStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      FieldLabel("3. Choose a time")
      if treatment == nil || day == nil {
        Text("Select a treatment and a day to see available times.").mutedText(14)
      } else if loadingSlots {
        SkeletonBlock(height: 96)
      } else if slots.isEmpty {
        Text("No times fit this treatment on the day chosen. Please try another day.").mutedText(14)
      } else {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], alignment: .leading, spacing: 8) {
          ForEach(slots) { slot in
            slotButton(slot)
          }
        }
      }
    }
  }

  private func slotButton(_ slot: Slot) -> some View {
    let selected = slotStart == slot.start
    return Button {
      slotStart = slot.start
    } label: {
      Text(slot.label)
        .bodyText(14)
        .strikethrough(!slot.available)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .foregroundStyle(
          selected
            ? Palette.primaryForeground
            : slot.available ? Palette.foreground : Palette.mutedForeground.opacity(0.5)
        )
        .background(selected ? Palette.primary : slot.available ? Palette.card : Color.clear)
        .overlay(
          Rectangle().strokeBorder(
            selected ? Palette.primary : Palette.border,
            style: StrokeStyle(lineWidth: 1, dash: slot.available ? [] : [4])
          )
        )
    }
    .buttonStyle(.plain)
    .disabled(!slot.available)
    .accessibilityLabel(slot.label + (slot.available ? "" : ", unavailable"))
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var notesStep: some View {
    VStack(alignment: .leading, spacing: 12) {
      FieldLabel("4. Anything we should know? (optional)")
      NotesEditor(text: $notes, placeholder: "Previous treatments, medical history, preferred contact time…")
    }
  }

  private var summary: some View {
    VStack(alignment: .leading, spacing: 20) {
      Divider1()
      if let treatment, let slotStart {
        summaryText(treatment: treatment, start: slotStart)
          .mutedText(14)
      }
      Button(sending ? "Sending…" : "Send request", action: send)
        .buttonStyle(.clinic(.primary, size: .large))
        .disabled(treatment == nil || slotStart == nil || sending)
    }
    .padding(.top, 8)
  }

  private func summaryText(treatment: Treatment, start: Date) -> Text {
    let name = Text(treatment.name).foregroundColor(Palette.foreground).font(AppFont.bodyRegular(14))
    let when = Text(Fmt.string(start, "EEEE d MMMM 'at' h:mma"))
      .foregroundColor(Palette.foreground)
      .font(AppFont.bodyRegular(14))
    let length = Text(" (\(treatment.durationMinutes) minutes).")
    return Text("Requesting ") + name + Text(" on ") + when + length
  }

  // MARK: Data

  private func loadOptions() async {
    do {
      async let treatmentList = API.treatments()
      async let blockedList = API.blockedDates()
      let (t, b) = try await (treatmentList, blockedList)
      treatments = t
      var map: [String: String?] = [:]
      for row in b { map[row.day] = row.reason }
      blocked = map
    } catch {
      toaster.error(error)
    }
  }

  private func loadBusy() async {
    guard let day else { return }
    loadingSlots = true
    defer { loadingSlots = false }
    do {
      busy = try await API.busyRanges(dayKey: Fmt.dateKey(day))
    } catch {
      busy = []
      toaster.error(error)
    }
  }

  private func send() {
    guard let userId = session.user?.id, let treatment, let slotStart else {
      toaster.error("Please choose a treatment and a time.")
      return
    }
    sending = true
    let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    Task {
      do {
        try await API.requestBooking(
          userId: userId,
          treatment: treatment,
          start: slotStart,
          notes: trimmed.isEmpty ? nil : trimmed
        )
        toaster.success("Request sent — we'll confirm your appointment shortly.")
        router.bookingsChanged()
        treatmentId = nil
        day = nil
        self.slotStart = nil
        notes = ""
        busy = []
        router.tab = .appointments
      } catch {
        toaster.error(error)
      }
      sending = false
    }
  }
}
