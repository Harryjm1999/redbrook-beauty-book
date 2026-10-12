import SwiftUI

/// Points history, newest first. Mirrors src/components/LoyaltyHistory.tsx.
struct LoyaltyHistoryList: View {
  let items: [LoyaltyTransaction]

  var body: some View {
    if items.isEmpty {
      Text("No points yet.").mutedText(14)
    } else {
      VStack(spacing: 0) {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          if index > 0 { Divider1() }
          row(item)
        }
      }
      .background(Palette.background)
      .overlay(Rectangle().stroke(Palette.border, lineWidth: 1))
    }
  }

  private func row(_ item: LoyaltyTransaction) -> some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title(item)).bodyText(14)
        Text(detail(item)).mutedText(12)
      }
      Spacer(minLength: 8)
      Text(item.points > 0 ? "+\(item.points)" : "\(item.points)")
        .font(item.points >= 0 ? AppFont.bodyRegular(14) : AppFont.body(14))
        .foregroundStyle(item.points >= 0 ? Palette.foreground : Palette.mutedForeground)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .accessibilityElement(children: .combine)
  }

  private func title(_ item: LoyaltyTransaction) -> String {
    if let note = item.note, !note.isEmpty { return note }
    return item.points >= 0 ? "Points added" : "Points used"
  }

  private func detail(_ item: LoyaltyTransaction) -> String {
    var text = Fmt.string(item.createdAt, "d MMM yyyy")
    if let spent = item.amountSpent { text += " · £" + String(format: "%.2f", spent) + " spent" }
    return text
  }
}

/// The patient's loyalty card on My Appointments. Mirrors src/components/LoyaltyCard.tsx.
struct LoyaltyCardSection: View {
  @Environment(SessionStore.self) private var session
  @Environment(AppRouter.self) private var router

  @State private var items: [LoyaltyTransaction]?

  var body: some View {
    let total = Loyalty.total(items ?? [])
    VStack(alignment: .leading, spacing: 0) {
      Divider1()
      Text("Loyalty points")
        .displayCaps(24)
        .padding(.top, 40)
        .accessibilityAddTraits(.isHeader)

      if items == nil {
        SkeletonBlock(height: 120).padding(.top, 24)
      } else {
        VStack(alignment: .leading, spacing: 0) {
          Text("\(total) points").bodyText(30)
          Text(Loyalty.vouchersLabel(total)).bodyText(14).padding(.top, 16)
          Text("100 points = a £10 voucher.").mutedText(14).padding(.top, 8)
        }
        .cardBox(padding: 24)
        .padding(.top, 24)

        FieldLabel("Points history").padding(.top, 32).padding(.bottom, 12)
        LoyaltyHistoryList(items: items ?? [])
      }
    }
    .task(id: "\(session.user?.id.uuidString ?? "")-\(router.bookingsVersion)") { await load() }
  }

  private func load() async {
    guard let userId = session.user?.id else { return }
    items = (try? await API.loyalty(userId: userId)) ?? items ?? []
  }
}

/// Staff tab for finding a client, adding points and redeeming vouchers.
/// Mirrors src/components/LoyaltyAdmin.tsx.
struct LoyaltyAdminView: View {
  @Environment(Toaster.self) private var toaster

  @State private var clients: [Profile]?
  @State private var transactions: [LoyaltyTransaction] = []
  @State private var search = ""
  @State private var selected: Profile?

  @State private var amount = ""
  @State private var points = ""
  @State private var note = ""
  @State private var saving = false
  @State private var redeeming = false
  @State private var confirmingRedeem = false

  private var totals: [UUID: Int] {
    transactions.reduce(into: [:]) { $0[$1.userId, default: 0] += $1.points }
  }

  private var matches: [Profile] {
    let term = search.trimmingCharacters(in: .whitespaces).lowercased()
    guard !term.isEmpty else { return clients ?? [] }
    return (clients ?? []).filter { "\($0.fullName) \($0.email ?? "")".lowercased().contains(term) }
  }

  var body: some View {
    Group {
      if let selected {
        detail(selected)
      } else {
        list
      }
    }
    .task { await load() }
  }

  // MARK: Client list

  private var list: some View {
    VStack(alignment: .leading, spacing: 0) {
      FieldLabel("Search customers")
      TextField("Search customers by name or email", text: $search)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .clinicField()
        .padding(.top, 8)
        .accessibilityLabel("Search customers")

      if clients == nil {
        SkeletonBlock(height: 160).padding(.top, 16)
      } else if matches.isEmpty {
        Text("No clients found.").mutedText(14).padding(.top, 16)
      } else {
        Text("\(matches.count) customer\(matches.count == 1 ? "" : "s") found")
          .mutedText(12)
          .padding(.top, 16)
        VStack(spacing: 0) {
          ForEach(Array(matches.enumerated()), id: \.element.id) { index, client in
            if index > 0 { Divider1() }
            clientRow(client)
          }
        }
        .overlay(Rectangle().stroke(Palette.border, lineWidth: 1))
        .padding(.top, 8)
      }
    }
  }

  private func clientRow(_ client: Profile) -> some View {
    let total = totals[client.id] ?? 0
    let vouchers = Loyalty.vouchers(for: total)
    return Button {
      open(client)
    } label: {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(name(client)).bodyText(14).foregroundStyle(Palette.foreground)
          Text(client.email ?? "").mutedText(12).lineLimit(1)
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 2) {
          Text("\(total) pts").bodyText(14).foregroundStyle(Palette.foreground)
          Text("\(vouchers) voucher\(vouchers == 1 ? "" : "s")").mutedText(12)
        }
        Image(systemName: "chevron.right")
          .font(.system(size: 12))
          .foregroundStyle(Palette.mutedForeground)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  // MARK: One client

  private func detail(_ client: Profile) -> some View {
    let total = totals[client.id] ?? 0
    let history = transactions.filter { $0.userId == client.id }
    let pointsValue = Int(points.trimmingCharacters(in: .whitespaces))

    return VStack(alignment: .leading, spacing: 0) {
      Button {
        selected = nil
      } label: {
        Label("All clients", systemImage: "chevron.left")
      }
      .buttonStyle(.clinic(.ghost, size: .small))

      Text(name(client)).bodyText(20).padding(.top, 24)
      Text(client.email ?? "").mutedText(14)
      Text("\(total) points · \(Loyalty.vouchersLabel(total))").bodyText(14).padding(.top, 12)

      VStack(alignment: .leading, spacing: 16) {
        Text("Add points").labelCaps()
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Amount spent (£)")
          TextField("", text: $amount)
            .keyboardType(.decimalPad)
            .clinicField()
            .accessibilityLabel("Amount spent in pounds")
            .onChange(of: amount) { _, newValue in
              guard !newValue.isEmpty else { return }
              let pounds = Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0
              points = String(Loyalty.points(forSpend: pounds))
            }
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Points")
          TextField("", text: $points)
            .keyboardType(.numbersAndPunctuation)
            .clinicField()
            .accessibilityLabel("Points")
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Note (optional)")
          TextField("e.g. Dermal filler", text: $note)
            .clinicField()
            .accessibilityLabel("Note")
        }
        Button(saving ? "Saving…" : "Save points") { save(client, points: pointsValue ?? 0) }
          .buttonStyle(.clinic(.primary))
          .disabled(pointsValue == nil || pointsValue == 0 || saving)
      }
      .cardBox(padding: 22)
      .padding(.top, 32)

      VStack(alignment: .leading, spacing: 8) {
        Text("Redeem £10 voucher").labelCaps()
        Text("Uses \(Loyalty.pointsPerVoucher) points.").mutedText(14)
        Button(redeeming ? "Redeeming…" : "Redeem voucher") { confirmingRedeem = true }
          .buttonStyle(.clinic(.outline))
          .disabled(total < Loyalty.pointsPerVoucher || redeeming)
          .padding(.top, 8)
      }
      .cardBox(padding: 22)
      .padding(.top, 16)

      FieldLabel("Points history").padding(.top, 32).padding(.bottom, 12)
      LoyaltyHistoryList(items: history)
    }
    .alert("Redeem a £10 voucher?", isPresented: $confirmingRedeem) {
      Button("Redeem voucher") { redeem(client) }
      Button("Not now", role: .cancel) {}
    } message: {
      Text("This uses 100 of \(name(client))'s points.")
    }
  }

  // MARK: Actions

  private func name(_ client: Profile) -> String {
    client.fullName.isEmpty ? "Client" : client.fullName
  }

  private func open(_ client: Profile) {
    amount = ""
    points = ""
    note = ""
    selected = client
  }

  private func load() async {
    do {
      async let loadedClients = API.allClients()
      async let loadedTransactions = API.loyalty()
      let (loadedClientRows, loadedRows) = try await (loadedClients, loadedTransactions)
      clients = loadedClientRows
      transactions = loadedRows
    } catch {
      if clients == nil { clients = [] }
      toaster.error(error)
    }
  }

  private func refreshTransactions() async {
    if let loaded = try? await API.loyalty() { transactions = loaded }
  }

  private func save(_ client: Profile, points value: Int) {
    let pounds = Double(amount.replacingOccurrences(of: ",", with: "."))
    let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
    saving = true
    Task {
      do {
        try await API.addPoints(
          userId: client.id,
          points: value,
          amountSpent: pounds,
          note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        await refreshTransactions()
        amount = ""
        points = ""
        note = ""
        toaster.success("Points added.")
      } catch {
        toaster.error(error)
      }
      saving = false
    }
  }

  private func redeem(_ client: Profile) {
    redeeming = true
    Task {
      do {
        try await API.redeemVoucher(userId: client.id)
        await refreshTransactions()
        toaster.success("£10 voucher redeemed.")
      } catch {
        toaster.error(error)
      }
      redeeming = false
    }
  }
}
