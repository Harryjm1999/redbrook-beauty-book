import { supabase } from "@/integrations/supabase/client";

export const POUNDS_PER_POINT = 3;
export const POINTS_PER_VOUCHER = 100;

export function pointsForSpend(pounds: number): number {
  if (!Number.isFinite(pounds) || pounds <= 0) return 0;
  return Math.floor(pounds / POUNDS_PER_POINT);
}

export function vouchersFor(total: number): number {
  return Math.max(0, Math.floor(total / POINTS_PER_VOUCHER));
}

export function progressToNext(total: number): number {
  return Math.max(0, total) % POINTS_PER_VOUCHER;
}

export type LoyaltyTransaction = {
  id: string;
  user_id: string;
  points: number;
  amount_spent: number | null;
  note: string | null;
  created_at: string;
};

export async function fetchLoyalty(userId?: string): Promise<LoyaltyTransaction[]> {
  let q = supabase.from("loyalty_transactions").select("*").order("created_at", { ascending: false });
  if (userId) q = q.eq("user_id", userId);
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as LoyaltyTransaction[];
}

export async function fetchAllProfiles() {
  const { data, error } = await supabase.from("profiles").select("id, full_name, email").order("full_name");
  if (error) throw error;
  return data ?? [];
}

export async function addPoints(p: { userId: string; points: number; amount: number | null; note: string | null }) {
  const { error } = await supabase.from("loyalty_transactions").insert({
    user_id: p.userId,
    points: p.points,
    amount_spent: p.amount,
    note: p.note,
  });
  if (error) throw error;
}

export async function redeemVoucher(userId: string) {
  const { error } = await supabase.rpc("redeem_loyalty_voucher", { _user_id: userId });
  if (error) throw error;
}
