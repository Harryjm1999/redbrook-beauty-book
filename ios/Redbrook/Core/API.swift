import Foundation
import Supabase

extension UUID {
  /// Lowercase form, as Postgres prints UUIDs.
  var db: String { uuidString.lowercased() }
}

/// Data access for the shared Lovable Cloud database. Mirrors src/lib/queries.ts
/// and the inline Supabase calls in the web app's pages.
enum API {
  static let staffBlockNote = "Blocked by staff"

  static let acceptMessage =
    "Your appointment is confirmed — we look forward to seeing you at Redbrook Clinic. Please let us know if anything changes."
  static let denyMessage =
    "Unfortunately this slot isn't available. We'll be in touch shortly to arrange the closest possible appointment time."

  // MARK: Treatments

  static func treatments() async throws -> [Treatment] {
    try await supabase
      .from("treatments")
      .select()
      .eq("is_active", value: true)
      .order("sort_order", ascending: true)
      .execute()
      .value
  }

  // MARK: Availability

  static func busyRanges(dayKey: String) async throws -> [BusyRange] {
    try await supabase
      .rpc("busy_ranges", params: ["_day": dayKey])
      .execute()
      .value
  }

  static func blockedDates() async throws -> [BlockedDate] {
    try await supabase
      .from("blocked_dates")
      .select("id, day, created_at, blocked_date_reasons(reason)")
      .order("day", ascending: true)
      .execute()
      .value
  }

  // MARK: Patient bookings

  private struct NewBooking: Encodable {
    let user_id: String
    let treatment_id: String?
    let starts_at: String
    let ends_at: String
    let status: String
    let patient_notes: String?
  }

  static func myBookings(userId: UUID) async throws -> [Booking] {
    try await supabase
      .from("bookings")
      .select("*, treatments(name, duration_minutes)")
      .eq("user_id", value: userId.db)
      .order("starts_at", ascending: true)
      .execute()
      .value
  }

  static func requestBooking(userId: UUID, treatment: Treatment, start: Date, notes: String?) async throws {
    let end = start.addingTimeInterval(TimeInterval(treatment.durationMinutes * 60))
    try await supabase
      .from("bookings")
      .insert(
        NewBooking(
          user_id: userId.db,
          treatment_id: treatment.id.db,
          starts_at: Fmt.iso(start),
          ends_at: Fmt.iso(end),
          status: BookingStatus.pending.rawValue,
          patient_notes: notes
        ),
        returning: .minimal
      )
      .execute()
  }

  static func setStatus(bookingId: UUID, status: BookingStatus, staffNotes: String? = nil) async throws {
    var values = ["status": status.rawValue]
    if let staffNotes { values["staff_notes"] = staffNotes }
    try await supabase
      .from("bookings")
      .update(values, returning: .minimal)
      .eq("id", value: bookingId.db)
      .execute()
  }

  /// Removes the patient's own appointments whose date has passed.
  static func removePastBookings(userId: UUID) async throws {
    try await supabase
      .from("bookings")
      .delete(returning: .minimal)
      .eq("user_id", value: userId.db)
      .lt("starts_at", value: Fmt.iso(Date()))
      .execute()
  }

  // MARK: Profile and roles

  static func myProfile(userId: UUID) async throws -> Profile? {
    let rows: [Profile] = try await supabase
      .from("profiles")
      .select()
      .eq("id", value: userId.db)
      .limit(1)
      .execute()
      .value
    return rows.first
  }

  static func updateProfile(userId: UUID, fullName: String, phone: String) async throws {
    try await supabase
      .from("profiles")
      .update(["full_name": fullName, "phone": phone], returning: .minimal)
      .eq("id", value: userId.db)
      .execute()
  }

  private struct RoleRow: Decodable {
    let role: String
  }

  static func isStaff(userId: UUID) async throws -> Bool {
    let rows: [RoleRow] = try await supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", value: userId.db)
      .execute()
      .value
    return rows.contains { $0.role == "admin" || $0.role == "staff" }
  }

  /// Permanently deletes the signed-in user's account and, through ON DELETE CASCADE,
  /// their profile and bookings. Needs the `delete_my_account` database function
  /// described in ios/README.md.
  static func deleteMyAccount() async throws {
    try await supabase.rpc("delete_my_account").execute()
  }

  // MARK: Clinic diary (staff)

  static func allBookings() async throws -> [DiaryBooking] {
    let bookings: [Booking] = try await supabase
      .from("bookings")
      .select("*, treatments(name)")
      .order("starts_at", ascending: true)
      .execute()
      .value

    let ids = Array(Set(bookings.map(\.userId)))
    var patients: [UUID: Profile] = [:]
    if !ids.isEmpty {
      let profiles: [Profile] = try await supabase
        .from("profiles")
        .select("id, full_name, email, phone")
        .in("id", values: ids.map(\.db))
        .execute()
        .value
      for profile in profiles { patients[profile.id] = profile }
    }

    return bookings.map { DiaryBooking(booking: $0, patient: patients[$0.userId]) }
  }

  private struct InsertedId: Decodable {
    let id: UUID
  }

  /// Marks a diary slot as booked. Patients' insert policy only allows pending rows,
  /// so this inserts a pending booking and then confirms it, like the web app.
  static func blockSlot(userId: UUID, start: Date, end: Date) async throws {
    let row: InsertedId = try await supabase
      .from("bookings")
      .insert(
        NewBooking(
          user_id: userId.db,
          treatment_id: nil,
          starts_at: Fmt.iso(start),
          ends_at: Fmt.iso(end),
          status: BookingStatus.pending.rawValue,
          patient_notes: nil
        )
      )
      .select("id")
      .single()
      .execute()
      .value
    try await setStatus(bookingId: row.id, status: .confirmed, staffNotes: staffBlockNote)
  }

  static func unblockSlot(bookingId: UUID) async throws {
    try await setStatus(bookingId: bookingId, status: .cancelled)
  }

  // MARK: Loyalty points

  /// A client's own points history, or every client's when `userId` is nil (staff only).
  static func loyalty(userId: UUID? = nil) async throws -> [LoyaltyTransaction] {
    var query = supabase.from("loyalty_transactions").select()
    if let userId { query = query.eq("user_id", value: userId.db) }
    return try await query.order("created_at", ascending: false).execute().value
  }

  static func allClients() async throws -> [Profile] {
    try await supabase
      .from("profiles")
      .select("id, full_name, email")
      .order("full_name", ascending: true)
      .execute()
      .value
  }

  private struct NewLoyaltyTransaction: Encodable {
    let user_id: String
    let points: Int
    let amount_spent: Double?
    let note: String?
  }

  static func addPoints(userId: UUID, points: Int, amountSpent: Double?, note: String?) async throws {
    try await supabase
      .from("loyalty_transactions")
      .insert(
        NewLoyaltyTransaction(user_id: userId.db, points: points, amount_spent: amountSpent, note: note),
        returning: .minimal
      )
      .execute()
  }

  /// Takes 100 points off the client for a £10 voucher. The database checks they have enough.
  static func redeemVoucher(userId: UUID) async throws {
    try await supabase
      .rpc("redeem_loyalty_voucher", params: ["_user_id": userId.db])
      .execute()
  }
}
