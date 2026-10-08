import Foundation
import Supabase

/// Lovable Cloud (Supabase) project shared with the web app.
/// These are the same public values as VITE_SUPABASE_URL and
/// VITE_SUPABASE_PUBLISHABLE_KEY in the repo's .env; the publishable key is
/// safe to ship in the app because every table is protected by row-level security.
enum SupabaseConfig {
  static let url = URL(string: "https://rcjdyvgthlwqinmaejoa.supabase.co")!
  static let publishableKey = "sb_publishable_zlUh4gUs_RLVniJ-ebG9-Q_E-Js5P1E"
}

let supabase = SupabaseClient(
  supabaseURL: SupabaseConfig.url,
  supabaseKey: SupabaseConfig.publishableKey
)
