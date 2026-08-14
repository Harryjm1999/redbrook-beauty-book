import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { addDays, format, isSameDay } from "date-fns";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { buildSlots, formatPrice, OPENING_HOURS, toDateKey } from "@/lib/clinic";
import { fetchBusyRanges, fetchTreatments } from "@/lib/queries";

export const Route = createFileRoute("/_authenticated/book")({
  head: () => ({
    meta: [
      { title: "Request an Appointment | Redbrook Clinic" },
      {
        name: "description",
        content:
          "Choose your treatment, pick an available time at Redbrook Clinic in Salisbury and send your appointment request.",
      },
      { property: "og:title", content: "Request an Appointment | Redbrook Clinic" },
      { property: "og:description", content: "See available times and request your appointment online." },
    ],
  }),
  component: BookPage,
});

const DAYS_AHEAD = 42;

function BookPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [treatmentId, setTreatmentId] = useState<string>("");
  const [day, setDay] = useState<Date | null>(null);
  const [slotIso, setSlotIso] = useState<string>("");
  const [notes, setNotes] = useState("");

  const { data: treatments, isLoading } = useQuery({ queryKey: ["treatments"], queryFn: fetchTreatments });
  const treatment = treatments?.find((t) => t.id === treatmentId) ?? null;

  const openDays = useMemo(() => {
    const list: Date[] = [];
    const today = new Date();
    for (let i = 0; i < DAYS_AHEAD; i++) {
      const d = addDays(today, i);
      if (OPENING_HOURS[d.getDay()]) list.push(d);
    }
    return list;
  }, []);

  const dayKey = day ? toDateKey(day) : null;
  const { data: busy, isFetching: loadingSlots } = useQuery({
    queryKey: ["busy", dayKey],
    queryFn: () => fetchBusyRanges(dayKey as string),
    enabled: Boolean(dayKey),
  });

  const slots = useMemo(() => {
    if (!day || !treatment) return [];
    return buildSlots(day, treatment.duration_minutes, busy ?? []);
  }, [day, treatment, busy]);

  const request = useMutation({
    mutationFn: async () => {
      if (!user || !treatment || !slotIso) throw new Error("Please choose a treatment and a time.");
      const start = new Date(slotIso);
      const end = new Date(start.getTime() + treatment.duration_minutes * 60_000);
      const { error } = await supabase.from("bookings").insert({
        user_id: user.id,
        treatment_id: treatment.id,
        starts_at: start.toISOString(),
        ends_at: end.toISOString(),
        status: "pending",
        patient_notes: notes.trim() || null,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["my-bookings"] });
      queryClient.invalidateQueries({ queryKey: ["busy"] });
      toast.success("Request sent — we'll confirm your appointment shortly.");
      navigate({ to: "/appointments" });
    },
    onError: (error: Error) => toast.error(error.message),
  });

  return (
    <section className="mx-auto max-w-4xl px-5 py-16">
      <h1 className="display-caps text-3xl sm:text-4xl">Request an appointment</h1>
      <p className="mt-4 max-w-2xl text-sm leading-relaxed text-muted-foreground">
        Pick your treatment and a time that suits you. Every request is reviewed by the clinic and confirmed by
        email — you'll see the status in{" "}
        <Link to="/appointments" className="underline underline-offset-4">
          my appointments
        </Link>
        .
      </p>

      <div className="mt-12 space-y-10">
        <div>
          <Label className="label-caps">1. Choose a treatment</Label>
          {isLoading ? (
            <Skeleton className="mt-3 h-11 w-full" />
          ) : (
            <Select
              value={treatmentId}
              onValueChange={(value) => {
                setTreatmentId(value);
                setSlotIso("");
              }}
            >
              <SelectTrigger className="mt-3 w-full">
                <SelectValue placeholder="Select a treatment or consultation" />
              </SelectTrigger>
              <SelectContent className="max-h-80">
                {(treatments ?? []).map((t) => (
                  <SelectItem key={t.id} value={t.id}>
                    {t.name} · {t.duration_minutes} min · {formatPrice(t.price_from, t.price_note)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        </div>

        <div>
          <Label className="label-caps">2. Choose a day</Label>
          <div className="mt-3 flex gap-3 overflow-x-auto pb-3">
            {openDays.map((d) => {
              const selected = day ? isSameDay(d, day) : false;
              return (
                <button
                  key={d.toISOString()}
                  type="button"
                  onClick={() => {
                    setDay(d);
                    setSlotIso("");
                  }}
                  className={`min-w-24 shrink-0 border px-4 py-3 text-center transition-colors ${
                    selected
                      ? "border-primary bg-primary text-primary-foreground"
                      : "border-border bg-card hover:bg-secondary"
                  }`}
                >
                  <span className="label-caps block">{format(d, "EEE")}</span>
                  <span className="mt-1 block text-lg">{format(d, "d")}</span>
                  <span className="block text-xs opacity-80">{format(d, "MMM")}</span>
                </button>
              );
            })}
          </div>
        </div>

        <div>
          <Label className="label-caps">3. Choose a time</Label>
          {!treatment || !day ? (
            <p className="mt-3 text-sm text-muted-foreground">
              Select a treatment and a day to see available times.
            </p>
          ) : loadingSlots ? (
            <Skeleton className="mt-3 h-24 w-full" />
          ) : slots.length === 0 ? (
            <p className="mt-3 text-sm text-muted-foreground">
              No times fit this treatment on the day chosen. Please try another day.
            </p>
          ) : (
            <div className="mt-3 flex flex-wrap gap-2">
              {slots.map((slot) => {
                const iso = slot.start.toISOString();
                const selected = slotIso === iso;
                return (
                  <button
                    key={iso}
                    type="button"
                    disabled={!slot.available}
                    onClick={() => setSlotIso(iso)}
                    className={`border px-4 py-2 text-sm transition-colors ${
                      selected
                        ? "border-primary bg-primary text-primary-foreground"
                        : slot.available
                          ? "border-border bg-card hover:bg-secondary"
                          : "cursor-not-allowed border-dashed border-border text-muted-foreground/50 line-through"
                    }`}
                  >
                    {slot.label}
                  </button>
                );
              })}
            </div>
          )}
        </div>

        <div>
          <Label htmlFor="notes" className="label-caps">
            4. Anything we should know? (optional)
          </Label>
          <Textarea
            id="notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={4}
            className="mt-3"
            placeholder="Previous treatments, medical history, preferred contact time…"
          />
        </div>

        <div className="border-t border-border pt-8">
          {treatment && slotIso ? (
            <p className="text-sm text-muted-foreground">
              Requesting <strong className="text-foreground">{treatment.name}</strong> on{" "}
              <strong className="text-foreground">
                {format(new Date(slotIso), "EEEE d MMMM 'at' h:mmaaa")}
              </strong>{" "}
              ({treatment.duration_minutes} minutes).
            </p>
          ) : null}
          <Button
            size="lg"
            className="label-caps mt-5"
            disabled={!treatment || !slotIso || request.isPending}
            onClick={() => request.mutate()}
          >
            {request.isPending ? "Sending…" : "Send request"}
          </Button>
        </div>
      </div>
    </section>
  );
}
