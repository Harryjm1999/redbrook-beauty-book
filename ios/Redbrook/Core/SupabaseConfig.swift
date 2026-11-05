import Foundation
import Supabase

/// Lovable Cloud (Supabase) project shared with the web app.
/// These are the same public values as VITE_SUPABASE_URL and
/// VITE_SUPABASE_PUBLISHABLE_KEY in the repo's .env; the publishable key is
/// safe to ship in the app because every table is protected by row-level security.
enum SupabaseConfig {
  static let url = URL(string: "https://rcjdyvgthlwqinmaejoa.supabase.co")!
  static let publishableKey = "sb_publishable_zlUh4gUs_RLVniJ-ebG9-Q_E-Js5P1E"
  /// The published Lovable website, which hosts the sign-in return page and the
  /// password reset page.
  static let website = URL(string: "https://redbrook-beauty-book.lovable.app")!

  /// Where the confirm-email link sends people who signed up in the app. The
  /// page (public/app-auth-callback.html) opens the app at redbrook://auth-callback,
  /// which signs them in.
  static let emailConfirmedRedirect = URL(string: "\(website.absoluteString)/app-auth-callback.html")!
  /// Same page for the reset-password email; the app then asks for a new password.
  static let passwordResetRedirect = URL(string: "\(website.absoluteString)/app-auth-callback.html?next=reset")!
}

let supabase = SupabaseClient(
  supabaseURL: SupabaseConfig.url,
  supabaseKey: SupabaseConfig.publishableKey
)
