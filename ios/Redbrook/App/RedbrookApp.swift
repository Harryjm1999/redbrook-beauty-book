import SwiftUI

@main
struct RedbrookApp: App {
  @State private var session = SessionStore()
  @State private var router = AppRouter()
  @State private var toaster = Toaster()

  init() {
    let tabBar = UITabBarAppearance()
    tabBar.configureWithOpaqueBackground()
    tabBar.backgroundColor = UIColor(Palette.cream)
    UITabBar.appearance().standardAppearance = tabBar
    UITabBar.appearance().scrollEdgeAppearance = tabBar

    let segmented = UISegmentedControl.appearance()
    segmented.selectedSegmentTintColor = UIColor(Palette.card)
    segmented.backgroundColor = UIColor(Palette.muted)
    if let font = UIFont(name: "JostRoman-Regular", size: 12) {
      segmented.setTitleTextAttributes([.font: font, .foregroundColor: UIColor(Palette.mutedForeground)], for: .normal)
      segmented.setTitleTextAttributes([.font: font, .foregroundColor: UIColor(Palette.foreground)], for: .selected)
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(session)
        .environment(router)
        .environment(toaster)
        .tint(Palette.primary)
        .preferredColorScheme(.light)
    }
  }
}

struct RootView: View {
  @Environment(AppRouter.self) private var router
  @Environment(SessionStore.self) private var session
  @Environment(Toaster.self) private var toaster

  var body: some View {
    @Bindable var router = router
    @Bindable var session = session

    TabView(selection: $router.tab) {
      NavigationStack { HomeView().policyDestinations() }
        .tabItem { Label("Home", systemImage: "house") }
        .tag(AppTab.home)

      NavigationStack { TreatmentsView().policyDestinations() }
        .tabItem { Label("Treatments", systemImage: "list.bullet.rectangle") }
        .tag(AppTab.treatments)

      NavigationStack { SignedInGate(mode: .signup) { BookView() }.policyDestinations() }
        .tabItem { Label("Book In", systemImage: "calendar.badge.plus") }
        .tag(AppTab.book)

      NavigationStack { SignedInGate(mode: .signin) { AppointmentsView() }.policyDestinations() }
        .tabItem { Label("Appointments", systemImage: "calendar") }
        .tag(AppTab.appointments)

      NavigationStack(path: $router.morePath) { MoreView().policyDestinations() }
        .tabItem { Label("More", systemImage: "ellipsis.circle") }
        .tag(AppTab.more)
    }
    .overlay { ToastOverlay() }
    .onOpenURL { url in
      Task {
        do {
          switch try await session.handleAuthLink(url) {
          case .emailConfirmed:
            router.tab = .appointments
            toaster.success("Your email is confirmed and you're signed in.")
          case .passwordReset, nil:
            break
          }
        } catch {
          toaster.error("That link has expired or was already used. Please sign in, or ask for a new link.")
        }
      }
    }
    .sheet(isPresented: $session.needsNewPassword) {
      NewPasswordSheet()
    }
  }
}

/// Shows the sign-in screen until a patient is signed in, like the web app's
/// `_authenticated` route guard.
struct SignedInGate<Content: View>: View {
  @Environment(SessionStore.self) private var session
  let mode: AuthMode
  @ViewBuilder let content: () -> Content

  var body: some View {
    Group {
      if session.isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Palette.background)
      } else if session.user != nil {
        content()
      } else {
        ScrollView { AuthView(initialMode: mode) }
          .background(Palette.background)
      }
    }
    .clinicNavigation()
  }
}
