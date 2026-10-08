import SwiftUI

/// The rest of the website's navigation: About, Contact, Clinic Diary (staff) and account.
struct MoreView: View {
  @Environment(SessionStore.self) private var session
  @Environment(AppRouter.self) private var router
  @Environment(Toaster.self) private var toaster

  @State private var showingAuth = false

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = info?["CFBundleVersion"] as? String ?? "1"
    return "\(short) (\(build))"
  }

  var body: some View {
    List {
      Section {
        NavigationLink { AboutView() } label: { row("About Us", "person.crop.circle") }
        NavigationLink { ContactView() } label: { row("Contact", "envelope") }
        Button { router.tab = .treatments } label: { row("Treatments & Fees", "list.bullet.rectangle") }
      }

      if session.user != nil {
        Section {
          Button { router.tab = .appointments } label: { row("My Appointments", "calendar") }
          if session.isStaff {
            NavigationLink { AdminView() } label: { row("Clinic Diary", "book.closed") }
          }
        }
      }

      Section {
        if let email = session.user?.email {
          Text("Signed in as \(email)")
            .font(AppFont.body(13))
            .foregroundStyle(Palette.mutedForeground)
          Button {
            Task {
              await session.signOut()
              router.tab = .home
            }
          } label: {
            row("Sign out", "rectangle.portrait.and.arrow.right")
          }
        } else {
          Button { showingAuth = true } label: { row("Sign in", "person.badge.key") }
        }
      }

      Section {
        Link(destination: Clinic.phoneURL) { row("Call the clinic", "phone") }
        Link(destination: Clinic.emailURL) { row("Email the clinic", "at") }
      } footer: {
        Text("Version \(version)")
          .font(AppFont.body(12))
          .frame(maxWidth: .infinity)
          .padding(.top, 16)
      }
    }
    .scrollContentBackground(.hidden)
    .background(Palette.background)
    .foregroundStyle(Palette.foreground)
    .clinicNavigation()
    .sheet(isPresented: $showingAuth) {
      NavigationStack {
        ScrollView { AuthView(initialMode: .signin) }
          .background(Palette.background)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Close") { showingAuth = false }
            }
          }
      }
      .overlay { ToastOverlay() }
      .environment(session)
      .environment(router)
      .environment(toaster)
    }
    .onChange(of: session.user?.id) { _, newValue in
      // Like the web app, signing in takes the patient straight to booking.
      if showingAuth, newValue != nil {
        showingAuth = false
        router.tab = .book
      }
    }
  }

  private func row(_ title: String, _ icon: String) -> some View {
    Label {
      Text(title).bodyText(16).foregroundStyle(Palette.foreground)
    } icon: {
      Image(systemName: icon).foregroundStyle(Palette.primary)
    }
  }
}
