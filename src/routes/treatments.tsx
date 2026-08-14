import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { fetchTreatments, type Treatment } from "@/lib/queries";
import { formatPrice } from "@/lib/clinic";

export const Route = createFileRoute("/treatments")({
  head: () => ({
    meta: [
      { title: "Treatments & Fees | Redbrook Clinic Salisbury" },
      {
        name: "description",
        content:
          "Full list of Redbrook Clinic treatments and prices: PDO threads, plasma needling, dermal fillers, wrinkle relaxing, laser hair removal, CO2 resurfacing and more.",
      },
      { property: "og:title", content: "Treatments & Fees | Redbrook Clinic Salisbury" },
      {
        property: "og:description",
        content: "Non-surgical face and body treatments with transparent pricing in Salisbury, Wiltshire.",
      },
    ],
  }),
  component: Treatments,
});

function Treatments() {
  const { data, isLoading, isError } = useQuery({ queryKey: ["treatments"], queryFn: fetchTreatments });

  const grouped = (data ?? []).reduce<Record<string, Treatment[]>>((acc, t) => {
    (acc[t.category] ??= []).push(t);
    return acc;
  }, {});

  return (
    <section className="mx-auto max-w-5xl px-5 py-20">
      <h1 className="display-caps text-3xl sm:text-4xl">Treatments &amp; fees</h1>
      <p className="mt-4 max-w-2xl text-sm leading-relaxed text-muted-foreground">
        Consultations are complimentary — we discuss your needs and design an individual plan to suit you.
        Prices are a guide and are confirmed at consultation.
      </p>

      {isLoading ? (
        <div className="mt-12 space-y-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
        </div>
      ) : isError ? (
        <p className="mt-12 text-sm text-destructive">
          We couldn't load the treatment list. Please refresh, or call the clinic.
        </p>
      ) : (
        <div className="mt-14 space-y-16">
          {Object.entries(grouped).map(([category, items]) => (
            <div key={category}>
              <h2 className="display-caps border-b border-border pb-3 text-2xl">{category}</h2>
              <ul className="mt-6 space-y-6">
                {items.map((t) => (
                  <li key={t.id} className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                    <div className="max-w-2xl">
                      <h3 className="text-base">{t.name}</h3>
                      {t.description ? (
                        <p className="mt-1 text-sm leading-relaxed text-muted-foreground">{t.description}</p>
                      ) : null}
                      <p className="label-caps mt-2 text-muted-foreground">{t.duration_minutes} minutes</p>
                    </div>
                    <p className="shrink-0 text-sm sm:text-right">
                      {formatPrice(t.price_from, t.price_note)}
                    </p>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      )}

      <div className="mt-20 text-center">
        <Button asChild size="lg" className="label-caps">
          <Link to="/book">Request an appointment</Link>
        </Button>
      </div>
    </section>
  );
}
