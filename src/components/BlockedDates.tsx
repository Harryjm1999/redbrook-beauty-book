import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { eachDayOfInterval, format, parseISO } from "date-fns";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { addBlockedDates, fetchBlockedDates, removeBlockedDate } from "@/lib/queries";

type Props = { userId: string };

export function BlockedDates({ userId }: Props) {
  const queryClient = useQueryClient();
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [reason, setReason] = useState("");

  const { data: blocked, isLoading } = useQuery({ queryKey: ["blocked-dates"], queryFn: fetchBlockedDates });

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ["blocked-dates"] });
  };

  const add = useMutation({
    mutationFn: async () => {
      if (!from) throw new Error("Choose a date to block.");
      const start = parseISO(from);
      const end = to ? parseISO(to) : start;
      if (end < start) throw new Error("The end date must be after the start date.");
      const days = eachDayOfInterval({ start, end }).map((d) => format(d, "yyyy-MM-dd"));
      await addBlockedDates(days, reason.trim() || null, userId);
      return days.length;
    },
    onSuccess: (count) => {
      invalidate();
      setFrom("");
      setTo("");
      setReason("");
      toast.success(count === 1 ? "Date blocked." : `${count} dates blocked.`);
    },
    onError: (error: Error) => toast.error(error.message),
  });

  const remove = useMutation({
    mutationFn: (id: string) => removeBlockedDate(id),
    onSuccess: () => {
      invalidate();
      toast.success("Date reopened.");
    },
    onError: (error: Error) => toast.error(error.message),
  });

  const todayKey = format(new Date(), "yyyy-MM-dd");
  const upcoming = (blocked ?? []).filter((b) => b.day >= todayKey);

  return (
    <div className="mt-6 space-y-8">
      <p className="text-sm text-muted-foreground">
        Close off days you're already booked elsewhere (for example in Ovatu). Blocked days are greyed out for
        patients when they request an appointment.
      </p>

      <div className="border border-border bg-card p-6">
        <div className="grid gap-4 sm:grid-cols-3">
          <div>
            <Label htmlFor="block-from" className="label-caps">
              Date
            </Label>
            <Input
              id="block-from"
              type="date"
              value={from}
              min={todayKey}
              onChange={(e) => setFrom(e.target.value)}
              className="mt-2"
            />
          </div>
          <div>
            <Label htmlFor="block-to" className="label-caps">
              Until (optional)
            </Label>
            <Input
              id="block-to"
              type="date"
              value={to}
              min={from || todayKey}
              onChange={(e) => setTo(e.target.value)}
              className="mt-2"
            />
          </div>
          <div>
            <Label htmlFor="block-reason" className="label-caps">
              Reason (optional)
            </Label>
            <Input
              id="block-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Fully booked in Ovatu"
              className="mt-2"
            />
          </div>
        </div>
        <Button className="label-caps mt-5" disabled={add.isPending} onClick={() => add.mutate()}>
          {add.isPending ? "Blocking…" : "Block dates"}
        </Button>
      </div>

      <div>
        <h2 className="label-caps">Blocked dates</h2>
        {isLoading ? (
          <Skeleton className="mt-4 h-24 w-full" />
        ) : upcoming.length === 0 ? (
          <p className="mt-4 text-sm text-muted-foreground">No upcoming dates are blocked.</p>
        ) : (
          <ul className="mt-4 space-y-3">
            {upcoming.map((b) => (
              <li
                key={b.id}
                className="flex flex-wrap items-center justify-between gap-3 border border-border bg-card px-5 py-4"
              >
                <div>
                  <p className="text-sm">{format(parseISO(b.day), "EEEE d MMMM yyyy")}</p>
                  {b.reason ? <p className="mt-1 text-sm text-muted-foreground">{b.reason}</p> : null}
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  disabled={remove.isPending}
                  onClick={() => remove.mutate(b.id)}
                >
                  Reopen
                </Button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
