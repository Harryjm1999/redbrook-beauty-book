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
    .select("*, treatments(name), profiles(full_name, email, phone)")
    .order("starts_at", { ascending: true });
  if (error) throw error;
  return (data ?? []) as (Booking & {
    treatments: { name: string } | null;
    profiles: { full_name: string; email: string | null; phone: string | null } | null;
  })[];
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
