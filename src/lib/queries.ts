import { supabase } from "@/integrations/supabase/client";

export type Treatment = {
  id: string;
  name: string;
  category: string;
  description: string | null;
  duration_minutes: number;
  price_from: number | null;
  price_note: string | null;
  is_active: boolean;
  sort_order: number;
};

export type Booking = {
  id: string;
  user_id: string;
  treatment_id: string | null;
  starts_at: string;
  ends_at: string;
  status: "pending" | "confirmed" | "declined" | "cancelled";
  patient_notes: string | null;
  staff_notes: string | null;
  created_at: string;
};

export type Profile = {
  id: string;
  full_name: string;
  email: string | null;
  phone: string | null;
};

export async function fetchTreatments(): Promise<Treatment[]> {
  const { data, error } = await supabase
    .from("treatments")
    .select("*")
    .eq("is_active", true)
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return (data ?? []) as Treatment[];
}

export async function fetchBusyRanges(dayKey: string) {
  const { data, error } = await supabase.rpc("busy_ranges", { _day: dayKey });
  if (error) throw error;
  return (data ?? []) as { starts_at: string; ends_at: string }[];
}

export async function fetchMyBookings(userId: string) {
  const { data, error } = await supabase
    .from("bookings")
    .select("*, treatments(name, duration_minutes)")
    .eq("user_id", userId)
    .order("starts_at", { ascending: true });
  if (error) throw error;
  return (data ?? []) as (Booking & { treatments: { name: string; duration_minutes: number } | null })[];
}

export async function fetchAllBookings() {
  const { data, error } = await supabase
    .from("bookings")
    .select("*, treatments(name)")
    .order("starts_at", { ascending: true });
  if (error) throw error;
  const bookings = (data ?? []) as unknown as (Booking & { treatments: { name: string } | null })[];

  const ids = [...new Set(bookings.map((b) => b.user_id))];
  const patients = new Map<string, Profile>();
  if (ids.length) {
    const { data: profiles, error: profileError } = await supabase
      .from("profiles")
      .select("id, full_name, email, phone")
      .in("id", ids);
    if (profileError) throw profileError;
    for (const p of (profiles ?? []) as Profile[]) patients.set(p.id, p);
  }

  return bookings.map((b) => ({ ...b, patient: patients.get(b.user_id) ?? null }));
}

export async function fetchMyProfile(userId: string) {
  const { data, error } = await supabase.from("profiles").select("*").eq("id", userId).maybeSingle();
  if (error) throw error;
  return (data ?? null) as Profile | null;
}

export async function fetchIsStaff(userId: string) {
  const { data, error } = await supabase.from("user_roles").select("role").eq("user_id", userId);
  if (error) throw error;
  return (data ?? []).some((r: { role: string }) => r.role === "admin" || r.role === "staff");
}

export type BlockedDate = {
  id: string;
  day: string;
  reason: string | null;
  created_at: string;
};

export async function fetchBlockedDates(): Promise<BlockedDate[]> {
  const { data, error } = await supabase
    .from("blocked_dates")
    .select("id, day, created_at, blocked_date_reasons(reason)")
    .order("day", { ascending: true });
  if (error) throw error;
  return (data ?? []).map((row) => ({
    id: row.id,
    day: row.day,
    created_at: row.created_at,
    reason:
      (Array.isArray(row.blocked_date_reasons)
        ? row.blocked_date_reasons[0]?.reason
        : (row.blocked_date_reasons as { reason: string } | null)?.reason) ?? null,
  }));
}

export async function addBlockedDates(days: string[], reason: string | null, userId: string) {
  const { data, error } = await supabase
    .from("blocked_dates")
    .upsert(
      days.map((day) => ({ day, created_by: userId })),
      { onConflict: "day" },
    )
    .select("id");
  if (error) throw error;

  const trimmed = reason?.trim();
  if (trimmed && data?.length) {
    const { error: reasonError } = await supabase
      .from("blocked_date_reasons")
      .upsert(data.map((row) => ({ blocked_date_id: row.id, reason: trimmed })), {
        onConflict: "blocked_date_id",
      });
    if (reasonError) throw reasonError;
  }
}


export async function removeBlockedDate(id: string) {
  const { error } = await supabase.from("blocked_dates").delete().eq("id", id);
  if (error) throw error;
}

const STAFF_BLOCK_NOTE = "Blocked by staff";
export { STAFF_BLOCK_NOTE };

export async function blockSlot(params: {
  userId: string;
  startsAt: string;
  endsAt: string;
}) {
  const { data, error } = await supabase
    .from("bookings")
    .insert({
      user_id: params.userId,
      starts_at: params.startsAt,
      ends_at: params.endsAt,
      status: "pending",
    })
    .select("id")
    .single();
  if (error) throw error;
  const { error: updateError } = await supabase
    .from("bookings")
    .update({ status: "confirmed", staff_notes: STAFF_BLOCK_NOTE })
    .eq("id", data.id);
  if (updateError) throw updateError;
}

export async function unblockSlot(bookingId: string) {
  const { error } = await supabase
    .from("bookings")
    .update({ status: "cancelled" })
    .eq("id", bookingId);
  if (error) throw error;
}
