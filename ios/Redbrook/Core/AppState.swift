import Foundation
import Observation
import Supabase
import SwiftUI

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

  /// True after a reset-password link signs someone in, until they choose a
  /// new password.
  var needsNewPassword = false

  func signOut() async {
    try? await supabase.auth.signOut()
  }

  /// Handles redbrook://auth-callback links from the confirm-email and
  /// reset-password emails: signs the person in and reports which it was.
  func handleAuthLink(_ url: URL) async throws -> AuthLink? {
    guard url.scheme == "redbrook", url.host == "auth-callback" else { return nil }
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let isReset = items.contains { $0.name == "next" && $0.value == "reset" }
    _ = try await supabase.auth.session(from: url)
    if isReset {
      needsNewPassword = true
      return .passwordReset
    }
    return .emailConfirmed
  }
}

enum AuthLink {
  case emailConfirmed, passwordReset
}

enum AppTab: String, Hashable {
  case home, treatments, book, appointments, more
}

/// Screens pushed from the More tab.
enum MoreRoute: String, Hashable {
  case about, contact, diary, loyalty
}

@MainActor
@Observable
final class AppRouter {
  var tab: AppTab = .home
  var morePath = NavigationPath()
  /// Bumped whenever bookings change so lists reload, like invalidating React Query keys.
  var bookingsVersion = 0

  func bookingsChanged() { bookingsVersion += 1 }

  init() {
    #if DEBUG
      // Lets the screenshot job open a given screen:
      //   -screen treatments | book | appointments | more | about | contact | privacy | records
      let args = ProcessInfo.processInfo.arguments
      if let index = args.firstIndex(of: "-screen"), index + 1 < args.count {
        let screen = args[index + 1]
        if let tab = AppTab(rawValue: screen) {
          self.tab = tab
        } else if let route = MoreRoute(rawValue: screen) {
          tab = .more
          morePath.append(route)
        } else if screen == "privacy" || screen == "records" {
          tab = .more
          morePath.append(screen == "privacy" ? PolicyPage.privacy : PolicyPage.recordsManagement)
        }
      }
    #endif
  }
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
  func error(_ error: Error) {
    // A screen that reloads (for example as sign in finishes) cancels the
    // request it had running. That isn't a real problem, so stay quiet.
    if isCancellation(error) { return }
    show(Toast(message: describe(error), isError: true))
  }

  func dismiss() { current = nil }

  private func show(_ toast: Toast) {
    current = toast
    Task {
      try? await Task.sleep(for: .seconds(4))
      if current?.id == toast.id { current = nil }
    }
  }
}

/// True for errors that only mean a request was cancelled.
func isCancellation(_ error: Error) -> Bool {
  if error is CancellationError { return true }
  if let urlError = error as? URLError, urlError.code == .cancelled { return true }
  let nsError = error as NSError
  if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled { return true }
  return String(describing: error).contains("CancellationError")
}
