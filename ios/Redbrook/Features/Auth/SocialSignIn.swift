import AuthenticationServices
import Supabase
import SwiftUI

/// "Continue with Google" and "Sign in with Apple", using the same Lovable
/// sign-in service as the website's Google button. The service sends the result
/// to public/app-oauth-callback.html on the website, which passes it back to the
/// app through the redbrook:// address.
struct SocialSignInButtons: View {
  @Environment(\.webAuthenticationSession) private var webAuthenticationSession
  @Environment(Toaster.self) private var toaster
  @State private var busy: Provider?

  enum Provider: String {
    case google, apple
  }

  private static let website = URL(string: "https://redbrook-beauty-book.lovable.app")!
  private static let callbackScheme = "redbrook"

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 16) {
        Rectangle().fill(Palette.border).frame(height: 1)
        Text("or").labelCaps().foregroundStyle(Palette.mutedForeground)
        Rectangle().fill(Palette.border).frame(height: 1)
      }
      .padding(.bottom, 12)

      Button {
        signIn(with: .apple)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "apple.logo")
          Text(busy == .apple ? "Signing in…" : "Sign in with Apple")
        }
        .font(.system(size: 16, weight: .medium))
        .frame(maxWidth: .infinity, minHeight: 46)
        .foregroundStyle(.white)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 6))
      }
      .accessibilityLabel("Sign in with Apple")

      Button(busy == .google ? "Signing in…" : "Continue with Google") {
        signIn(with: .google)
      }
      .buttonStyle(.clinic(.outline, fullWidth: true))
    }
    .disabled(busy != nil)
  }

  private func signIn(with provider: Provider) {
    let state = UUID().uuidString
    var components = URLComponents(
      url: Self.website.appendingPathComponent("~oauth/initiate"),
      resolvingAgainstBaseURL: false
    )!
    components.queryItems = [
      URLQueryItem(name: "provider", value: provider.rawValue),
      URLQueryItem(
        name: "redirect_uri",
        value: Self.website.appendingPathComponent("app-oauth-callback.html").absoluteString
      ),
      URLQueryItem(name: "state", value: state),
    ]

    busy = provider
    Task {
      defer { busy = nil }
      do {
        let callback = try await webAuthenticationSession.authenticate(
          using: components.url!,
          callbackURLScheme: Self.callbackScheme,
          preferredBrowserSession: .ephemeral
        )
        let values = Self.parameters(in: callback)
        if let message = values["error_description"] ?? values["error"] {
          toaster.error(message)
          return
        }
        guard values["state"] == state,
          let accessToken = values["access_token"],
          let refreshToken = values["refresh_token"]
        else {
          toaster.error("Sign in didn't finish. Please try again or use your email address.")
          return
        }
        try await supabase.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        toaster.success("Welcome.")
      } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
        // The person closed the sign-in sheet.
      } catch {
        toaster.error(error)
      }
    }
  }

  /// Values from both the query string and the #fragment of the callback.
  private static func parameters(in url: URL) -> [String: String] {
    var values: [String: String] = [:]
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    for item in components?.queryItems ?? [] {
      values[item.name] = item.value
    }
    if let fragment = components?.fragment {
      var parsed = URLComponents()
      parsed.query = fragment
      for item in parsed.queryItems ?? [] {
        values[item.name] = item.value
      }
    }
    return values
  }
}
