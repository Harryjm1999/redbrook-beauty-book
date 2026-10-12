import { format } from "date-fns";
import type { LoyaltyTransaction } from "@/lib/loyalty";

export function LoyaltyHistory({ items }: { items: LoyaltyTransaction[] }) {
  if (items.length === 0) return <p className="text-sm text-muted-foreground">No points yet.</p>;
  return (
    <ul className="divide-y divide-border border border-border">
      {items.map((t) => (
        <li key={t.id} className="flex items-center justify-between gap-4 px-4 py-3 text-sm">
          <div>
            <p>{t.note || (t.points >= 0 ? "Points added" : "Points used")}</p>
            <p className="text-xs text-muted-foreground">
              {format(new Date(t.created_at), "d MMM yyyy")}
              {t.amount_spent != null ? ` · £${Number(t.amount_spent).toFixed(2)} spent` : ""}
            </p>
          </div>
          <span className={t.points >= 0 ? "font-medium" : "text-muted-foreground"}>
            {t.points > 0 ? `+${t.points}` : t.points}
          </span>
        </li>
      ))}
    </ul>
  );
}
