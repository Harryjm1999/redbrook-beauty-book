import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { format, isSameDay } from "date-fns";

import { Badge } from "@/components/ui/badge";
import { Calendar } from "@/components/ui/calendar";
import { Skeleton } from "@/components/ui/skeleton";
import { OPENING_HOURS, SLOT_STEP_MINUTES, minutesToLabel, toDateKey } from "@/lib/clinic";
import { fetchBlockedDates } from "@/lib/queries";
import type { Booking, Profile } from "@/lib/queries";

type DiaryBooking = Booking & {
  treatments: { name: string } | null;
  patient: Profile | null;
};

export function DiaryCalendar({ bookings, isLoading }: { bookings: DiaryBooking[]; isLoading: boolean }) {
  const [selected, setSelected] = useState<Date>(new Date());

  const { data: blocked } = useQuery({ queryKey: ["blocked-dates"], queryFn: fetchBlockedDates });
  const blockedKeys = useMemo(() => new Set((blocked ?? []).map((b) => b.day)), [blocked]);

  const active = useMemo(
    () => bookings.filter((b) => b.status === "confirmed" || b.status === "pending"),
    [bookings],
  );

  const confirmedDays = useMemo(
    () => active.filter((b) => b.status === "confirmed").map((b) => new Date(b.starts_at)),
    [active],
  );
  const pendingDays = useMemo(
    () => active.filter((b) => b.status === "pending").map((b) => new Date(b.starts_at)),
    [active],
  );
  const blockedDays = useMemo(
    () => (blocked ?? []).map((b) => new Date(`${b.day}T00:00:00`)),
    [blocked],
  );

  const dayBookings = useMemo(
    () => active.filter((b) => isSameDay(new Date(b.starts_at), selected)),
    [active, selected],
  );

  const hours = OPENING_HOURS[selected.getDay()];
  const dayKey = toDateKey(selected);
  const isBlocked = blockedKeys.has(dayKey);

  const slots = useMemo(() => {
    if (!hours) return [];
    const out: { minutes: number; label: string; booking: DiaryBooking | null }[] = [];
    for (let m = hours.open; m < hours.close; m += SLOT_STEP_MINUTES) {
      const start = new Date(selected);
      start.setHours(0, 0, 0, 0);
      start.setMinutes(m);
      const end = new Date(start.getTime() + SLOT_STEP_MINUTES * 60_000);
      const booking =
        dayBookings.find(
          (b) =>
            start.getTime() < new Date(b.ends_at).getTime() && end.getTime() > new Date(b.starts_at).getTime(),
        ) ?? null;
      out.push({ minutes: m, label: minutesToLabel(m), booking });
    }
    return out;
  }, [hours, selected, dayBookings]);

  const upcoming = useMemo(
    () =>
      active
        .filter((b) => new Date(b.starts_at) >= new Date())
        .sort((a, b) => a.starts_at.localeCompare(b.starts_at))
        .slice(0, 10),
    [active],
  );

  if (isLoading) return <Skeleton className="mt-6 h-80 w-full" />;

  return (
    <div className="mt-6 space-y-10">
      <div className="grid gap-8 lg:grid-cols-[auto_1fr]">
        <div className="border border-border bg-card p-4">
          <Calendar
            mode="single"
            selected={selected}
            onSelect={(d) => d && setSelected(d)}
            weekStartsOn={1}
            modifiers={{ confirmed: confirmedDays, pending: pendingDays, blockedDay: blockedDays }}
            modifiersClassNames={{
              confirmed: "font-semibold underline underline-offset-4",
              pending: "italic",
              blockedDay: "line-through opacity-40",
            }}
          />
          <p className="mt-3 text-xs text-muted-foreground">
            Underlined = confirmed bookings · italic = pending requests · struck through = blocked day
          </p>
        </div>

        <div>
          <h3 className="display-caps text-xl">{format(selected, "EEEE d MMMM yyyy")}</h3>
          {isBlocked ? (
            <p className="mt-2 text-sm text-muted-foreground">This day is blocked — patients can't request it.</p>
          ) : null}
          {!hours ? (
            <p className="mt-4 text-sm text-muted-foreground">Closed on this day.</p>
          ) : (
            <ul className="mt-4 grid gap-2 sm:grid-cols-2">
              {slots.map((slot) => {
                const taken = Boolean(slot.booking);
                const confirmed = slot.booking?.status === "confirmed";
                return (
                  <li
                    key={slot.minutes}
                    className={`flex items-center justify-between gap-3 border px-4 py-3 text-sm ${
                      taken || isBlocked
                        ? "border-border bg-muted text-muted-foreground"
                        : "border-border bg-card"
                    }`}
                  >
                    <span className="label-caps">{slot.label}</span>
                    {slot.booking ? (
                      <span className="text-right text-xs">
                        {slot.booking.patient?.full_name || "Patient"}
                        <br />
                        {slot.booking.treatments?.name ?? "Treatment"}
                        {confirmed ? "" : " (request)"}
                      </span>
                    ) : (
                      <span className="text-xs">{isBlocked ? "Blocked" : "Free"}</span>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </div>

      <div>
        <h3 className="display-caps text-xl">Upcoming appointments</h3>
        {upcoming.length === 0 ? (
          <p className="mt-3 text-sm text-muted-foreground">Nothing booked in yet.</p>
        ) : (
          <ul className="mt-4 space-y-2">
            {upcoming.map((b) => (
              <li
                key={b.id}
                className="flex flex-wrap items-center justify-between gap-3 border border-border bg-card px-5 py-3"
              >
                <div>
                  <p className="text-base">{b.patient?.full_name || "Patient"}</p>
                  <p className="mt-1 text-sm text-muted-foreground">
                    {b.treatments?.name ?? "Treatment"} ·{" "}
                    {format(new Date(b.starts_at), "EEE d MMM yyyy, h:mmaaa")}
                  </p>
                </div>
                <Badge variant={b.status === "confirmed" ? "default" : "secondary"}>{b.status}</Badge>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
