import Foundation

/// Clinic details, opening hours and slot logic. Mirrors src/lib/clinic.ts in the web app.
enum Clinic {
  static let name = "Redbrook Clinic"
  static let tagline = "An independent private aesthetic clinic on the outskirts of Salisbury."
  static let address = "5 Coberley Drive, St Peter's Place, Salisbury, Wiltshire, SP2 9FD"
  static let email = "lou.oatley@gmail.com"
  static let phone = "07773 554375"

  static var emailURL: URL { URL(string: "mailto:\(email)")! }
  static var phoneURL: URL { URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")! }
  static var mapsURL: URL {
    var components = URLComponents(string: "https://maps.apple.com/")!
    components.queryItems = [URLQueryItem(name: "q", value: "\(name), \(address)")]
    return components.url!
  }

  /// Opening hours in minutes from midnight, keyed by JS-style weekday (0 = Sunday).
  static let openingHours: [Int: (open: Int, close: Int)] = [
    1: (9 * 60, 20 * 60),
    2: (9 * 60, 12 * 60),
    3: (9 * 60, 20 * 60),
    4: (9 * 60, 12 * 60),
    5: (12 * 60, 18 * 60),
    6: (13 * 60, 15 * 60),
  ]

  static let openingHoursText: [(day: String, hours: String)] = [
    ("Monday", "9am – 8pm"),
    ("Tuesday", "9am – 12pm"),
    ("Wednesday", "9am – 8pm"),
    ("Thursday", "9am – 12pm"),
    ("Friday", "12pm – 6pm"),
    ("Saturday", "1pm – 3pm"),
    ("Sunday", "Closed"),
  ]

  static let slotStepMinutes = 30

  static func hours(on date: Date) -> (open: Int, close: Int)? {
    let weekday = Calendar.current.component(.weekday, from: date) - 1
    return openingHours[weekday]
  }
}

struct Slot: Identifiable, Hashable {
  let minutes: Int
  let label: String
  let start: Date
  let end: Date
  let available: Bool
  var id: Date { start }
}

enum SlotBuilder {
  /// Builds the bookable start times for a day, given the treatment length and
  /// the ranges already taken by other appointments.
  static func slots(on day: Date, durationMinutes: Int, busy: [BusyRange], now: Date = Date()) -> [Slot] {
    guard let hours = Clinic.hours(on: day) else { return [] }
    let calendar = Calendar.current
    let midnight = calendar.startOfDay(for: day)
    var result: [Slot] = []
    var m = hours.open
    while m + durationMinutes <= hours.close {
      let start = calendar.date(byAdding: .minute, value: m, to: midnight)!
      let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
      let clashes = busy.contains { start < $0.endsAt && end > $0.startsAt }
      let inPast = start < now
      result.append(Slot(minutes: m, label: minutesToLabel(m), start: start, end: end, available: !clashes && !inPast))
      m += Clinic.slotStepMinutes
    }
    return result
  }
}

func minutesToLabel(_ minutes: Int) -> String {
  let h = minutes / 60
  let m = minutes % 60
  let suffix = h >= 12 ? "pm" : "am"
  let hour12 = h % 12 == 0 ? 12 : h % 12
  return m == 0 ? "\(hour12)\(suffix)" : "\(hour12):\(String(format: "%02d", m))\(suffix)"
}

func formatPrice(_ price: Double?, note: String?) -> String {
  if let note { return note }
  guard let price else { return "On consultation" }
  if price == 0 { return "Free" }
  return "£\(String(format: "%.0f", price))"
}

enum Fmt {
  /// Formats dates the way the web app does with date-fns (en-GB, lowercase am/pm).
  static func string(_ date: Date, _ pattern: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_GB")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = .current
    formatter.amSymbol = "am"
    formatter.pmSymbol = "pm"
    formatter.dateFormat = pattern
    return formatter.string(from: date)
  }

  /// `yyyy-MM-dd` in the device's time zone, matching toDateKey in the web app.
  static func dateKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  static func date(fromKey key: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: key)
  }

  /// ISO 8601 with milliseconds, like JavaScript's Date.toISOString().
  static func iso(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }
}

func describe(_ error: Error) -> String {
  if let localized = error as? LocalizedError, let description = localized.errorDescription {
    return description
  }
  return error.localizedDescription
}
