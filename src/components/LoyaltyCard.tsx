import { useQuery } from "@tanstack/react-query";
import { Progress } from "@/components/ui/progress";
import { LoyaltyHistory } from "@/components/LoyaltyHistory";
import { POINTS_PER_VOUCHER, fetchLoyalty, progressToNext, vouchersFor } from "@/lib/loyalty";

export function LoyaltyCard({ userId }: { userId: string }) {
  const { data: tx } = useQuery({
    queryKey: ["loyalty", userId],
    queryFn: () => fetchLoyalty(userId),
    enabled: Boolean(userId),
  });
  const total = (tx ?? []).reduce((s, t) => s + t.points, 0);
  const progress = progressToNext(total);

  return (
    <div className="mt-20 border-t border-border pt-10">
      <h2 className="display-caps text-2xl">Loyalty card</h2>
      <div className="mt-6 border border-border bg-card p-6">
        <p className="text-3xl">{total} points</p>
        <p className="mt-4 text-sm">
          {progress} / {POINTS_PER_VOUCHER} points
        </p>
        <Progress value={progress} className="mt-2" />
        <p className="mt-4 text-sm">{vouchersFor(total)} £10 voucher(s) available</p>
        <p className="mt-2 text-sm text-muted-foreground">
          Earn 100 points for every £300 spent. 100 points = a £10 voucher.
        </p>
      </div>
      <h3 className="label-caps mb-3 mt-8">Points history</h3>
      <LoyaltyHistory items={tx ?? []} />
    </div>
  );
}
