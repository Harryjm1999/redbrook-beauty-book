export const CLINIC = {
  name: "Redbrook Clinic",
  tagline: "An independent private aesthetic clinic on the outskirts of Salisbury.",
  address: "5 Coberley Drive, St Peter's Place, Salisbury, Wiltshire, SP2 9FD",
  email: "lou.oatley@gmail.com",
  phone: "07773 554375",
};

/** Opening hours in minutes from midnight, index = JS day (0 = Sunday). */
export const OPENING_HOURS: Record<number, { open: number; close: number } | null> = {
  0: null,
  1: { open: 9 * 60, close: 20 * 60 },
  2: { open: 9 * 60, close: 12 * 60 },
  3: { open: 9 * 60, close: 20 * 60 },
  4: { open: 9 * 60, close: 12 * 60 },
  5: { open: 12 * 60, close: 18 * 60 },
  6: { open: 13 * 60, close: 15 * 60 },
};

export const OPENING_HOURS_TEXT = [
  { day: "Monday", hours: "9am – 8pm" },
  { day: "Tuesday", hours: "9am – 12pm" },
  { day: "Wednesday", hours: "9am – 8pm" },
  { day: "Thursday", hours: "9am – 12pm" },
  { day: "Friday", hours: "12pm – 6pm" },
  { day: "Saturday", hours: "1pm – 3pm" },
  { day: "Sunday", hours: "Closed" },
];

export const SLOT_STEP_MINUTES = 30;

export function toDateKey(date: Date) {
  const y = date.getFullYear();
  const m = `${date.getMonth() + 1}`.padStart(2, "0");
  const d = `${date.getDate()}`.padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function minutesToLabel(minutes: number) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  const suffix = h >= 12 ? "pm" : "am";
  const hour12 = h % 12 === 0 ? 12 : h % 12;
  return m === 0 ? `${hour12}${suffix}` : `${hour12}:${`${m}`.padStart(2, "0")}${suffix}`;
}

export type Busy = { starts_at: string; ends_at: string };

/**
 * Builds the bookable start times for a day, given the treatment length and
 * the ranges already taken by other appointments.
 */
export function buildSlots(day: Date, durationMinutes: number, busy: Busy[]) {
  const hours = OPENING_HOURS[day.getDay()];
  if (!hours) return [];

  const busyRanges = busy.map((b) => ({
    start: new Date(b.starts_at).getTime(),
    end: new Date(b.ends_at).getTime(),
  }));

  const slots: { minutes: number; label: string; start: Date; end: Date; available: boolean }[] = [];
  const now = Date.now();

  for (let m = hours.open; m + durationMinutes <= hours.close; m += SLOT_STEP_MINUTES) {
    const start = new Date(day);
    start.setHours(0, 0, 0, 0);
    start.setMinutes(m);
    const end = new Date(start.getTime() + durationMinutes * 60_000);

    const clashes = busyRanges.some((r) => start.getTime() < r.end && end.getTime() > r.start);
    const inPast = start.getTime() < now;

    slots.push({
      minutes: m,
      label: minutesToLabel(m),
      start,
      end,
      available: !clashes && !inPast,
    });
  }

  return slots;
}

export function formatPrice(price: number | null, note: string | null) {
  if (note) return note;
  if (price === null) return "On consultation";
  if (price === 0) return "Free";
  return `£${price.toFixed(0)}`;
}
