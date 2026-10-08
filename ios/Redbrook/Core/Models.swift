import Foundation

/// Row types for the shared Lovable Cloud database. Mirrors src/lib/queries.ts.

struct Treatment: Decodable, Identifiable, Hashable {
  let id: UUID
  let name: String
  let category: String
  let description: String?
  let durationMinutes: Int
  let priceFrom: Double?
  let priceNote: String?
  let isActive: Bool
  let sortOrder: Int

  enum CodingKeys: String, CodingKey {
    case id, name, category, description
    case durationMinutes = "duration_minutes"
    case priceFrom = "price_from"
    case priceNote = "price_note"
    case isActive = "is_active"
    case sortOrder = "sort_order"
  }

  var priceLabel: String { formatPrice(priceFrom, note: priceNote) }
}

enum BookingStatus: String {
  case pending, confirmed, declined, cancelled

  /// Patient-facing wording from the My Appointments page.
  var patientLabel: String {
    switch self {
    case .pending: "Awaiting confirmation"
    case .confirmed: "Confirmed"
    case .declined: "Not available"
    case .cancelled: "Cancelled"
    }
  }
}

struct Booking: Decodable, Identifiable, Hashable {
  struct TreatmentRef: Decodable, Hashable {
    let name: String
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
      case name
      case durationMinutes = "duration_minutes"
    }
  }

  let id: UUID
  let userId: UUID
  let treatmentId: UUID?
  let startsAt: Date
  let endsAt: Date
  let statusRaw: String
  let patientNotes: String?
  let staffNotes: String?
  let treatment: TreatmentRef?

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case treatmentId = "treatment_id"
    case startsAt = "starts_at"
    case endsAt = "ends_at"
    case statusRaw = "status"
    case patientNotes = "patient_notes"
    case staffNotes = "staff_notes"
    case treatment = "treatments"
  }

  var status: BookingStatus? { BookingStatus(rawValue: statusRaw) }
  var treatmentName: String { treatment?.name ?? "Treatment" }
  var isStaffBlock: Bool { staffNotes == API.staffBlockNote }
}

struct Profile: Codable, Identifiable, Hashable {
  let id: UUID
  let fullName: String
  let email: String?
  let phone: String?

  enum CodingKeys: String, CodingKey {
    case id
    case fullName = "full_name"
    case email, phone
  }
}

/// A booking with the patient's contact details, as shown in the clinic diary.
struct DiaryBooking: Identifiable, Hashable {
  let booking: Booking
  let patient: Profile?
  var id: UUID { booking.id }
  var patientName: String {
    if let name = patient?.fullName, !name.isEmpty { return name }
    return "Patient"
  }
}

struct BusyRange: Decodable, Hashable {
  let startsAt: Date
  let endsAt: Date

  enum CodingKeys: String, CodingKey {
    case startsAt = "starts_at"
    case endsAt = "ends_at"
  }
}

struct BlockedDate: Decodable, Identifiable, Hashable {
  let id: UUID
  let day: String
  let reason: String?

  enum CodingKeys: String, CodingKey {
    case id, day
    case reasons = "blocked_date_reasons"
  }

  private struct ReasonRow: Decodable {
    let reason: String
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    day = try container.decode(String.self, forKey: .day)
    // The embedded relation comes back as an object or an array depending on the FK shape.
    if let rows = try? container.decodeIfPresent([ReasonRow].self, forKey: .reasons) {
      reason = rows.first?.reason
    } else if let row = try? container.decodeIfPresent(ReasonRow.self, forKey: .reasons) {
      reason = row.reason
    } else {
      reason = nil
    }
  }
}
