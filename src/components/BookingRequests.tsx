import { useMutation, useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { supabase } from "@/integrations/supabase/client";
import type { Booking, Profile } from "@/lib/queries";

export const ACCEPT_MESSAGE =
  "Your appointment is confirmed — we look forward to seeing you at Redbrook Clinic. Please let us know if anything changes.";
export const DENY_MESSAGE =
  "Unfortunately this slot isn't available. We'll be in touch shortly to arrange the closest possible appointment time.";

type RequestRow = Booking & {
  treatments: { name: string } | null;
  patient: Profile | null;
};

export function BookingRequests({ requests, isLoading }: { requests: RequestRow[]; isLoading: boolean }) {
  const queryClient = useQueryClient();

  const decide = useMutation({
    mutationFn: async ({ id, accept }: { id: string; accept: boolean }) => {
      const { error } = await supabase
        .from("bookings")
        .update({
          status: accept ? "confirmed" : "declined",
          staff_notes: accept ? ACCEPT_MESSAGE : DENY_MESSAGE,
        })
        .eq("id", id);
      if (error) throw error;
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["all-bookings"] });
      queryClient.invalidateQueries({ queryKey: ["busy"] });
      toast.success(
        variables.accept
          ? "Accepted — confirmation sent to the patient."
          : "Declined — the patient has been told you'll be in touch with a new time.",
      );
    },
    onError: (error: Error) => toast.error(error.message),
  });

  if (isLoading) return <Skeleton className="mt-6 h-40 w-full" />;
  if (requests.length === 0)
    return <p className="mt-6 text-sm text-muted-foreground">No requests waiting right now.</p>;

  return (
    <ul className="mt-6 space-y-3">
      {requests.map((booking) => (
        <li
          key={booking.id}
          className="flex flex-wrap items-center justify-between gap-4 border border-border bg-card px-5 py-4"
        >
          <div>
            <p className="text-base">{booking.patient?.full_name || "Patient"}</p>
            <p className="mt-1 text-sm text-muted-foreground">
              {booking.treatments?.name ?? "Treatment"} ·{" "}
              {format(new Date(booking.starts_at), "EEE d MMM yyyy, h:mmaaa")}
            </p>
          </div>
          <div className="flex gap-2">
            <Button
              size="sm"
              className="label-caps"
              onClick={() => decide.mutate({ id: booking.id, accept: true })}
              disabled={decide.isPending}
            >
              Accept
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="label-caps"
              onClick={() => decide.mutate({ id: booking.id, accept: false })}
              disabled={decide.isPending}
            >
              Deny
            </Button>
          </div>
        </li>
      ))}
    </ul>
  );
}
