import SwiftUI

/// The diary's Users tab: every account with its name, email and phone, and a
/// way for an admin to remove one. A removed person can sign up again later.
struct UsersAdminView: View {
  @Environment(SessionStore.self) private var session
  @Environment(Toaster.self) private var toaster

  @State private var users: [Profile]?
  @State private var search = ""
  @State private var pendingDelete: Profile?
  @State private var deletingId: UUID?

  private var matches: [Profile] {
    let term = search.trimmingCharacters(in: .whitespaces).lowercased()
    guard !term.isEmpty else { return users ?? [] }
    return (users ?? []).filter {
      "\($0.fullName) \($0.email ?? "") \($0.phone ?? "")".lowercased().contains(term)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      FieldLabel("Search users")
      TextField("Search by name, email or phone", text: $search)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .clinicField()
        .padding(.top, 8)
        .accessibilityLabel("Search users")

      if users == nil {
        SkeletonBlock(height: 160).padding(.top, 16)
      } else if matches.isEmpty {
        Text("No users found.").mutedText(14).padding(.top, 16)
      } else {
        Text("\(matches.count) user\(matches.count == 1 ? "" : "s")")
          .mutedText(12)
          .padding(.top, 16)
        VStack(spacing: 0) {
          ForEach(Array(matches.enumerated()), id: \.element.id) { index, user in
            if index > 0 { Divider1() }
            row(user)
          }
        }
        .overlay(Rectangle().stroke(Palette.border, lineWidth: 1))
        .padding(.top, 8)
      }
    }
    .task { await load() }
    .alert(
      "Remove this account?",
      isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
      presenting: pendingDelete
    ) { user in
      Button("Remove account", role: .destructive) { delete(user) }
      Button("Cancel", role: .cancel) {}
    } message: { user in
      Text(
        "This permanently deletes \(displayName(user))'s account, bookings and loyalty points. They can make a new account later if they want to."
      )
    }
  }

  private func row(_ user: Profile) -> some View {
    let isMe = user.id == session.user?.id
    return HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text(displayName(user) + (isMe ? " (you)" : "")).bodyText(14).foregroundStyle(Palette.foreground)
        if let email = user.email, !email.isEmpty {
          Text(email).mutedText(12).lineLimit(1).textSelection(.enabled)
        }
        if let phone = user.phone, !phone.isEmpty {
          Text(phone).mutedText(12).lineLimit(1).textSelection(.enabled)
        }
      }
      Spacer(minLength: 8)
      if !isMe {
        Button(deletingId == user.id ? "Removing…" : "Remove") { pendingDelete = user }
          .buttonStyle(.clinic(.destructive, size: .small))
          .disabled(deletingId != nil)
          .accessibilityLabel("Remove \(displayName(user))'s account")
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  private func displayName(_ user: Profile) -> String {
    user.fullName.isEmpty ? (user.email ?? "This person") : user.fullName
  }

  private func load() async {
    do {
      users = try await API.allUsers()
    } catch {
      users = []
      toaster.error(error)
    }
  }

  private func delete(_ user: Profile) {
    deletingId = user.id
    Task {
      do {
        try await API.deleteUser(id: user.id)
        users?.removeAll { $0.id == user.id }
        toaster.success("\(displayName(user))'s account has been removed.")
      } catch {
        toaster.error(error)
      }
      deletingId = nil
    }
  }
}
