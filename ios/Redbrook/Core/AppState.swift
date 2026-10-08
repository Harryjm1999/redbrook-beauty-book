import Foundation
import Observation
import Supabase

/// Tracks the signed-in patient and whether they are clinic staff.
/// Mirrors the web app's useAuth hook and the is-staff query.
@MainActor
@Observable
final class SessionStore {
  private(set) var user: User?
  private(set) var isLoading = true
  private(set) var isStaff = false
  private(set) var isCheckingStaff = false

  init() {
    Task { await listen() }
  }

  private func listen() async {
    for await (_, session) in supabase.auth.authStateChanges {
      let next = session?.user
      let changed = next?.id != user?.id
      user = next
      isLoading = false
      if changed { await refreshStaff() }
    }
  }

  func refreshStaff() async {
    guard let userId = user?.id else {
      isStaff = false
      return
    }
    isCheckingStaff = true
    isStaff = (try? await API.isStaff(userId: userId)) ?? false
    isCheckingStaff = false
  }

  func signOut() async {
    try? await supabase.auth.signOut()
  }
}

enum AppTab: Hashable {
  case home, treatments, book, appointments, more
}

@MainActor
@Observable
final class AppRouter {
  var tab: AppTab = .home
  /// Bumped whenever bookings change so lists reload, like invalidating React Query keys.
  var bookingsVersion = 0

  func bookingsChanged() { bookingsVersion += 1 }
}

@MainActor
@Observable
final class Toaster {
  struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let isError: Bool
  }

  private(set) var current: Toast?

  func success(_ message: String) { show(Toast(message: message, isError: false)) }
  func error(_ message: String) { show(Toast(message: message, isError: true)) }
  func error(_ error: Error) { show(Toast(message: describe(error), isError: true)) }

  func dismiss() { current = nil }

  private func show(_ toast: Toast) {
    current = toast
    Task {
      try? await Task.sleep(for: .seconds(4))
      if current?.id == toast.id { current = nil }
    }
  }
}
