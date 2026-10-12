import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { LoyaltyHistory } from "@/components/LoyaltyHistory";
import {
  POINTS_PER_VOUCHER,
  addPoints,
  fetchAllProfiles,
  fetchLoyalty,
  pointsForSpend,
  redeemVoucher,
  vouchersFor,
} from "@/lib/loyalty";

export function LoyaltyAdmin() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string | null>(null);
  const [amount, setAmount] = useState("");
  const [points, setPoints] = useState("");
  const [note, setNote] = useState("");

  const { data: profiles, isLoading } = useQuery({ queryKey: ["all-profiles"], queryFn: fetchAllProfiles });
  const { data: tx } = useQuery({ queryKey: ["loyalty", "all"], queryFn: () => fetchLoyalty() });

  const totals = useMemo(() => {
    const m = new Map<string, number>();
    for (const t of tx ?? []) m.set(t.user_id, (m.get(t.user_id) ?? 0) + t.points);
    return m;
  }, [tx]);

  const list = (profiles ?? []).filter((p) =>
    `${p.full_name} ${p.email ?? ""}`.toLowerCase().includes(search.toLowerCase()),
  );
  const client = profiles?.find((p) => p.id === selected);
  const total = selected ? (totals.get(selected) ?? 0) : 0;
  const history = (tx ?? []).filter((t) => t.user_id === selected);

  const refresh = () => qc.invalidateQueries({ queryKey: ["loyalty"] });

  const add = useMutation({
    mutationFn: () =>
      addPoints({
        userId: selected!,
        points: parseInt(points, 10),
        amount: amount ? Number(amount) : null,
        note: note.trim() || null,
      }),
    onSuccess: () => {
      refresh();
      setAmount("");
      setPoints("");
      setNote("");
      toast.success("Points added.");
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const redeem = useMutation({
    mutationFn: () => redeemVoucher(selected!),
    onSuccess: () => {
      refresh();
      toast.success("£10 voucher redeemed.");
    },
    onError: (e: Error) => toast.error(e.message),
  });

  if (client) {
    const pts = parseInt(points, 10);
    return (
      <div className="mt-6 space-y-8">
        <Button variant="ghost" size="sm" onClick={() => setSelected(null)}>
          ← All clients
        </Button>
        <div>
          <h2 className="text-xl">{client.full_name || "Client"}</h2>
          <p className="text-sm text-muted-foreground">{client.email}</p>
          <p className="mt-3 text-sm">
            {total} points · {vouchersFor(total)} £10 voucher(s) available
          </p>
        </div>

        <div className="border border-border bg-card p-6">
          <h3 className="label-caps">Add points</h3>
          <div className="mt-4 grid gap-4 sm:grid-cols-3">
            <div className="space-y-2">
              <Label htmlFor="lp-amount">Amount spent (£)</Label>
              <Input
                id="lp-amount"
                type="number"
                min="0"
                step="0.01"
                value={amount}
                onChange={(e) => {
                  setAmount(e.target.value);
                  setPoints(String(pointsForSpend(Number(e.target.value))));
                }}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="lp-points">Points</Label>
              <Input id="lp-points" type="number" step="1" value={points} onChange={(e) => setPoints(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="lp-note">Note (optional)</Label>
              <Input id="lp-note" placeholder="e.g. Dermal filler" value={note} onChange={(e) => setNote(e.target.value)} />
            </div>
          </div>
          <Button
            className="label-caps mt-4"
            disabled={!Number.isInteger(pts) || pts === 0 || add.isPending}
            onClick={() => add.mutate()}
          >
            {add.isPending ? "Saving…" : "Save points"}
          </Button>
        </div>

        <div className="border border-border bg-card p-6">
          <h3 className="label-caps">Redeem £10 voucher</h3>
          <p className="mt-2 text-sm text-muted-foreground">Uses {POINTS_PER_VOUCHER} points.</p>
          <Button
            variant="outline"
            className="label-caps mt-4"
            disabled={total < POINTS_PER_VOUCHER || redeem.isPending}
            onClick={() => {
              if (window.confirm(`Redeem a £10 voucher for ${client.full_name || "this client"}? This uses 100 points.`))
                redeem.mutate();
            }}
          >
            Redeem voucher
          </Button>
        </div>

        <div>
          <h3 className="label-caps mb-3">Points history</h3>
          <LoyaltyHistory items={history} />
        </div>
      </div>
    );
  }

  return (
    <div className="mt-6 space-y-4">
      <div className="space-y-2">
        <Label htmlFor="loyalty-search" className="label-caps">
          Search customers
        </Label>
        <Input
          id="loyalty-search"
          placeholder="Search customers by name or email"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>
      {!isLoading && list.length > 0 ? (
        <p className="text-xs text-muted-foreground">
          {list.length} customer{list.length === 1 ? "" : "s"} found
        </p>
      ) : null}

      {isLoading ? (
        <Skeleton className="h-40 w-full" />
      ) : list.length === 0 ? (
        <p className="text-sm text-muted-foreground">No clients found.</p>
      ) : (
        <ul className="divide-y divide-border border border-border">
          {list.map((p) => {
            const t = totals.get(p.id) ?? 0;
            return (
              <li key={p.id}>
                <button
                  className="flex w-full flex-wrap items-center justify-between gap-2 px-4 py-3 text-left text-sm hover:bg-muted"
                  onClick={() => setSelected(p.id)}
                >
                  <span>
                    {p.full_name || "Client"}
                    <span className="block text-xs text-muted-foreground">{p.email}</span>
                  </span>
                  <span className="text-right">
                    {t} pts
                    <span className="block text-xs text-muted-foreground">{vouchersFor(t)} voucher(s)</span>
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
