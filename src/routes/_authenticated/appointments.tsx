import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { format } from "date-fns";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { fetchIsStaff, fetchMyBookings, fetchMyProfile } from "@/lib/queries";

export const Route = createFileRoute("/_authenticated/appointments")({
  head: () => ({
    meta: [
      { title: "My Appointments | Redbrook Clinic" },
      {
        name: "description",
        content: "View the status of your Redbrook Clinic appointment requests and keep your contact details up to date.",
      },
      { property: "og:title", content: "My Appointments | Redbrook Clinic" },
      { property: "og:description", content: "Manage your Redbrook Clinic bookings and contact details." },
    ],
  }),
  component: AppointmentsPage,
});

const STATUS_LABEL: Record<string, string> = {
  pending: "Awaiting confirmation",
  confirmed: "Confirmed",
  declined: "Not available",
  cancelled: "Cancelled",
};

function AppointmentsPage() {
  const { user } = useAuth();
  const userId = user?.id ?? "";
  const queryClient = useQueryClient();

  const { data: bookings, isLoading } = useQuery({
    queryKey: ["my-bookings", userId],
    queryFn: () => fetchMyBookings(userId),
    enabled: Boolean(userId),
  });

  const { data: isStaff } = useQuery({
    queryKey: ["is-staff", userId],
    queryFn: () => fetchIsStaff(userId),
    enabled: Boolean(userId),
  });

  const cancel = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("bookings").update({ status: "cancelled" }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["my-bookings"] });
      queryClient.invalidateQueries({ queryKey: ["busy"] });
      toast.success("Appointment cancelled.");
    },
    onError: (error: Error) => toast.error(error.message),
  });

  return (
    <section className="mx-auto max-w-4xl px-5 py-16">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="display-caps text-3xl sm:text-4xl">My appointments</h1>
        <div className="flex gap-2">
          {isStaff ? (
            <Button asChild variant="outline" className="label-caps">
              <Link to="/admin">Clinic diary</Link>
            </Button>
          ) : null}
          <Button asChild className="label-caps">
            <Link to="/book">New request</Link>
          </Button>
        </div>
      </div>

      {isLoading ? (
        <div className="mt-12 space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-24 w-full" />
          ))}
        </div>
      ) : !bookings || bookings.length === 0 ? (
        <p className="mt-12 text-sm text-muted-foreground">
          You don't have any appointments yet.{" "}
          <Link to="/book" className="underline underline-offset-4">
            Request one now
          </Link>
          .
        </p>
      ) : (
        <ul className="mt-12 space-y-4">
          {bookings.map((booking) => (
            <li key={booking.id} className="border border-border bg-card p-6">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <h2 className="text-lg">{booking.treatments?.name ?? "Treatment"}</h2>
                  <p className="mt-1 text-sm text-muted-foreground">
                    {format(new Date(booking.starts_at), "EEEE d MMMM yyyy 'at' h:mmaaa")}
                  </p>
                  {booking.patient_notes ? (
                    <p className="mt-3 text-sm text-muted-foreground">Your note: {booking.patient_notes}</p>
                  ) : null}
                  {booking.staff_notes ? (
                    <p className="mt-2 text-sm">From the clinic: {booking.staff_notes}</p>
                  ) : null}
                </div>
                <div className="flex flex-col items-end gap-3">
                  <Badge variant={booking.status === "confirmed" ? "default" : "secondary"}>
                    {STATUS_LABEL[booking.status] ?? booking.status}
                  </Badge>
                  {booking.status === "pending" || booking.status === "confirmed" ? (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => cancel.mutate(booking.id)}
                      disabled={cancel.isPending}
                    >
                      Cancel
                    </Button>
                  ) : null}
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}

      <ProfileCard userId={userId} />
    </section>
  );
}

function ProfileCard({ userId }: { userId: string }) {
  const queryClient = useQueryClient();
  const { data: profile } = useQuery({
    queryKey: ["profile", userId],
    queryFn: () => fetchMyProfile(userId),
    enabled: Boolean(userId),
  });

  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");

  useEffect(() => {
    if (profile) {
      setFullName(profile.full_name ?? "");
      setPhone(profile.phone ?? "");
    }
  }, [profile]);

  const save = useMutation({
    mutationFn: async () => {
      const { error } = await supabase
        .from("profiles")
        .update({ full_name: fullName, phone })
        .eq("id", userId);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["profile", userId] });
      toast.success("Contact details updated.");
    },
    onError: (error: Error) => toast.error(error.message),
  });

  return (
    <div className="mt-20 border-t border-border pt-10">
      <h2 className="display-caps text-2xl">Your contact details</h2>
      <p className="mt-2 text-sm text-muted-foreground">
        We use these to confirm your appointments — please keep them up to date.
      </p>
      <div className="mt-6 grid gap-5 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="profile-name" className="label-caps">
            Full name
          </Label>
          <Input id="profile-name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
        </div>
        <div className="space-y-2">
          <Label htmlFor="profile-phone" className="label-caps">
            Contact number
          </Label>
          <Input id="profile-phone" type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} />
        </div>
      </div>
      <p className="mt-4 text-sm text-muted-foreground">Email: {profile?.email ?? "—"}</p>
      <Button className="label-caps mt-6" onClick={() => save.mutate()} disabled={save.isPending}>
        {save.isPending ? "Saving…" : "Save details"}
      </Button>
    </div>
  );
}
