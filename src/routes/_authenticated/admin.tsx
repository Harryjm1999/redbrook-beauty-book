import { createFileRoute } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { format } from "date-fns";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { fetchAllBookings, fetchIsStaff } from "@/lib/queries";

export const Route = createFileRoute("/_authenticated/admin")({
  head: () => ({
    meta: [
      { title: "Clinic Diary | Redbrook Clinic" },
      { name: "description", content: "Staff area for reviewing and confirming Redbrook Clinic appointment requests." },
      { property: "og:title", content: "Clinic Diary | Redbrook Clinic" },
      { property: "og:description", content: "Review, confirm and manage patient appointment requests." },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: AdminPage,
});

function AdminPage() {
  const { user } = useAuth();
  const userId = user?.id ?? "";
  const queryClient = useQueryClient();

  const { data: isStaff, isLoading: checkingRole } = useQuery({
    queryKey: ["is-staff", userId],
    queryFn: () => fetchIsStaff(userId),
    enabled: Boolean(userId),
  });

  const { data: bookings, isLoading } = useQuery({
    queryKey: ["all-bookings"],
    queryFn: fetchAllBookings,
    enabled: Boolean(isStaff),
  });

  const setStatus = useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      const { error } = await supabase.from("bookings").update({ status }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["all-bookings"] });
      queryClient.invalidateQueries({ queryKey: ["busy"] });
      toast.success("Booking updated.");
    },
    onError: (error: Error) => toast.error(error.message),
  });

  if (checkingRole) {
    return (
      <section className="mx-auto max-w-5xl px-5 py-16">
        <Skeleton className="h-40 w-full" />
      </section>
    );
  }

  if (!isStaff) {
    return (
      <section className="mx-auto max-w-3xl px-5 py-24 text-center">
        <h1 className="display-caps text-3xl">Staff only</h1>
        <p className="mt-4 text-sm text-muted-foreground">
          This area is for clinic staff. If you should have access, ask the clinic owner to add your account to
          the staff list.
        </p>
      </section>
    );
  }

  const all = bookings ?? [];
  const pending = all.filter((b) => b.status === "pending");
  const upcoming = all.filter((b) => b.status === "confirmed" && new Date(b.starts_at) >= new Date());
  const past = all.filter(
    (b) => b.status !== "pending" && !(b.status === "confirmed" && new Date(b.starts_at) >= new Date()),
  );

  function renderList(list: typeof all) {
    if (isLoading) return <Skeleton className="mt-6 h-40 w-full" />;
    if (list.length === 0) return <p className="mt-6 text-sm text-muted-foreground">Nothing here right now.</p>;

    return (
      <ul className="mt-6 space-y-4">
        {list.map((booking) => (
          <li key={booking.id} className="border border-border bg-card p-6">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <h2 className="text-lg">{booking.treatments?.name ?? "Treatment"}</h2>
                <p className="mt-1 text-sm text-muted-foreground">
                  {format(new Date(booking.starts_at), "EEEE d MMMM yyyy 'at' h:mmaaa")} –{" "}
                  {format(new Date(booking.ends_at), "h:mmaaa")}
                </p>
                <p className="mt-3 text-sm">
                  {booking.patient?.full_name || "Patient"} · {booking.patient?.phone ?? "no phone"} ·{" "}
                  {booking.patient?.email ?? "no email"}
                </p>
                {booking.patient_notes ? (
                  <p className="mt-2 text-sm text-muted-foreground">Note: {booking.patient_notes}</p>
                ) : null}
              </div>
              <div className="flex flex-col items-end gap-3">
                <Badge variant={booking.status === "confirmed" ? "default" : "secondary"}>{booking.status}</Badge>
                <div className="flex gap-2">
                  {booking.status !== "confirmed" ? (
                    <Button
                      size="sm"
                      onClick={() => setStatus.mutate({ id: booking.id, status: "confirmed" })}
                      disabled={setStatus.isPending}
                    >
                      Confirm
                    </Button>
                  ) : null}
                  {booking.status === "pending" ? (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setStatus.mutate({ id: booking.id, status: "declined" })}
                      disabled={setStatus.isPending}
                    >
                      Decline
                    </Button>
                  ) : null}
                  {booking.status === "confirmed" ? (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setStatus.mutate({ id: booking.id, status: "cancelled" })}
                      disabled={setStatus.isPending}
                    >
                      Cancel
                    </Button>
                  ) : null}
                </div>
              </div>
            </div>
          </li>
        ))}
      </ul>
    );
  }

  return (
    <section className="mx-auto max-w-5xl px-5 py-16">
      <h1 className="display-caps text-3xl sm:text-4xl">Clinic diary</h1>
      <p className="mt-4 text-sm text-muted-foreground">
        Review requests, confirm appointments and see patient contact details.
      </p>

      <Tabs defaultValue="pending" className="mt-10">
        <TabsList>
          <TabsTrigger value="pending" className="label-caps">
            Requests ({pending.length})
          </TabsTrigger>
          <TabsTrigger value="upcoming" className="label-caps">
            Upcoming ({upcoming.length})
          </TabsTrigger>
          <TabsTrigger value="past" className="label-caps">
            Everything else
          </TabsTrigger>
        </TabsList>
        <TabsContent value="pending">{renderList(pending)}</TabsContent>
        <TabsContent value="upcoming">{renderList(upcoming)}</TabsContent>
        <TabsContent value="past">{renderList(past)}</TabsContent>
      </Tabs>
    </section>
  );
}
