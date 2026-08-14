import { createFileRoute, Link } from "@tanstack/react-router";

import { Button } from "@/components/ui/button";
import { CLINIC, OPENING_HOURS_TEXT } from "@/lib/clinic";

export const Route = createFileRoute("/contact")({
  head: () => ({
    meta: [
      { title: "Contact & Find Us | Redbrook Clinic Salisbury" },
      {
        name: "description",
        content:
          "Redbrook Clinic, 5 Coberley Drive, St Peter's Place, Salisbury SP2 9FD. Opening hours, directions, phone and email.",
      },
      { property: "og:title", content: "Contact & Find Us | Redbrook Clinic Salisbury" },
      {
        property: "og:description",
        content: "Opening hours, directions and contact details for Redbrook Clinic in Salisbury.",
      },
    ],
  }),
  component: Contact,
});

function Contact() {
  return (
    <section className="mx-auto max-w-6xl px-5 py-20">
      <h1 className="display-caps text-3xl sm:text-4xl">Contact us</h1>
      <p className="mt-4 max-w-2xl text-sm leading-relaxed text-muted-foreground">
        We are happy to answer any questions you may have about the treatments we provide. Consultations are
        complimentary and without obligation.
      </p>

      <div className="mt-14 grid gap-12 md:grid-cols-3">
        <div>
          <h2 className="display-caps text-xl">Get in touch</h2>
          <p className="mt-4 text-sm text-muted-foreground">
            <a href={`mailto:${CLINIC.email}`} className="underline-offset-4 hover:underline">
              {CLINIC.email}
            </a>
          </p>
          <p className="mt-1 text-sm text-muted-foreground">
            <a href={`tel:${CLINIC.phone.replace(/\s/g, "")}`} className="underline-offset-4 hover:underline">
              {CLINIC.phone}
            </a>
          </p>
          <Button asChild className="label-caps mt-8">
            <Link to="/book">Request an appointment</Link>
          </Button>
        </div>

        <div>
          <h2 className="display-caps text-xl">Hours</h2>
          <ul className="mt-4 space-y-2 text-sm text-muted-foreground">
            {OPENING_HOURS_TEXT.map((row) => (
              <li key={row.day} className="flex justify-between border-b border-border pb-2">
                <span>{row.day}</span>
                <span>{row.hours}</span>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h2 className="display-caps text-xl">When visiting us</h2>
          <p className="mt-4 text-sm leading-relaxed text-muted-foreground">{CLINIC.address}</p>
          <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
            From Salisbury, take the A360 Devizes Road north out of the city and follow it for two miles. After
            the second roundabout (Fuggleston Red), turn left at the St Peter's Place roundabout, then take the
            first left onto Coberley Drive. We are just after the first left turning (Maundrell Lane) on the left
            side.
          </p>
          <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
            There is parking to the side of the property in Maundrell Lane, or you may park directly in front of
            the property.
          </p>
        </div>
      </div>
    </section>
  );
}
