# Block dates in the clinic diary

Since Ovatu isn't exposing a calendar feed or API on your plan, the app can't read your Ovatu bookings automatically. Instead, staff get a simple tool to close off days, so patients can't request slots on days you're already busy.

## What you'll get

- A "Blocked dates" panel in the staff diary (admin page):
  - Pick a date (or a date range) and optionally add a reason, then block it.
  - See a list of upcoming blocked dates with a remove button.
- On the patient booking page, blocked days appear greyed out and unselectable, alongside days already closed by opening hours.

## Technical details

- New table `blocked_dates` (date, reason, created_by, created_at) with unique date, grants, RLS: staff full manage, all authenticated read.
- Extend the availability query so the booking day picker excludes/greys blocked dates; keep existing `busy_ranges` behaviour for times.
- Admin UI added to `src/routes/_authenticated/admin.tsx`; booking day list updated in `src/routes/_authenticated/book.tsx`.

## About Ovatu

There is a real Ovatu API, but access is account/plan gated — Ovatu support has to enable API access and issue a key for your account. If you email them and get a key, I can then replace the manual blocking with a live sync that greys out days automatically. The manual tool stays useful either way as an override.
