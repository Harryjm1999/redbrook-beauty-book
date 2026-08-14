import { createFileRoute, Link } from "@tanstack/react-router";

import heroImage from "@/assets/hero.jpg";
import treatmentImage from "@/assets/treatment.jpg";
import { Button } from "@/components/ui/button";
import { CLINIC, OPENING_HOURS_TEXT } from "@/lib/clinic";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Redbrook Clinic | Non-Surgical Aesthetics in Salisbury" },
      {
        name: "description",
        content:
          "Independent private aesthetic clinic in Salisbury. Anti-ageing, advanced skincare, PDO threads and body treatments — request an appointment online.",
      },
      { property: "og:title", content: "Redbrook Clinic | Non-Surgical Aesthetics in Salisbury" },
      {
        property: "og:description",
        content: "Soft, subtle, natural facial rejuvenation and body contouring in Salisbury, Wiltshire.",
      },
    ],
  }),
  component: Home,
});

const HIGHLIGHTS = [
  {
    title: "PDO Threads",
    body: "A revolutionary non-surgical lift, using polydioxanone threads to lift and stimulate collagen.",
  },
  {
    title: "Advanced Skincare",
    body: "CO2 laser resurfacing, chemical peels, microdermabrasion, micro-needling and carbon facials.",
  },
  {
    title: "Anti Ageing",
    body: "Wrinkle relaxing injections, dermal fillers, mesotherapy, Profhilo, Sunekos and Sculptra.",
  },
  {
    title: "Body Image",
    body: "Cryo fat freezing, laser hair removal, semi-permanent make up and weight loss support.",
  },
];

function Home() {
  return (
    <>
      <section className="relative">
        <img
          src={heroImage}
          alt="Calm treatment room at Redbrook Clinic with eucalyptus in a glass vase"
          width={1600}
          height={1104}
          className="h-[62vh] min-h-[420px] w-full object-cover"
        />
        <div className="absolute inset-0 flex items-center justify-center px-5 sm:justify-end sm:pr-16">
          <div className="max-w-md bg-sage/90 px-8 py-10 text-center text-sage-foreground">
            <h1 className="display-caps text-3xl leading-tight sm:text-4xl">Welcome to Redbrook Clinic</h1>
            <p className="mt-5 text-sm leading-relaxed opacity-95">{CLINIC.tagline}</p>
            <Button asChild variant="secondary" size="lg" className="label-caps mt-8">
              <Link to="/book">Book an appointment</Link>
            </Button>
          </div>
        </div>
      </section>

      <section className="bg-taupe text-taupe-foreground">
        <div className="mx-auto grid max-w-6xl items-center gap-12 px-5 py-20 md:grid-cols-2">
          <div>
            <h2 className="display-caps text-2xl sm:text-3xl">What we do at the Redbrook Clinic</h2>
            <p className="mt-6 text-sm leading-relaxed opacity-95">
              At Redbrook Clinic we cater for all your non-surgical cosmetic and beauty treatments to help make
              you look the best that you possibly can. We offer the latest innovative treatments for face and
              body, for both men and women.
            </p>
            <p className="mt-4 text-sm leading-relaxed opacity-95">
              We specialise in soft, subtle, natural facial rejuvenation and body contouring procedures,
              alongside gold standard fillers and anti-ageing consultations — all within a friendly and relaxing
              atmosphere.
            </p>
            <Button asChild variant="secondary" className="label-caps mt-8">
              <Link to="/treatments">View treatments &amp; fees</Link>
            </Button>
          </div>
          <img
            src={treatmentImage}
            alt="A patient receiving a gentle non-surgical facial treatment"
            width={1200}
            height={912}
            loading="lazy"
            className="w-full object-cover shadow-sm"
          />
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-5 py-20">
        <h2 className="display-caps text-center text-2xl sm:text-3xl">Our treatments</h2>
        <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {HIGHLIGHTS.map((item) => (
            <article key={item.title} className="border-t border-border pt-6">
              <h3 className="display-caps text-xl">{item.title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-muted-foreground">{item.body}</p>
            </article>
          ))}
        </div>
        <div className="mt-14 text-center">
          <Button asChild size="lg" className="label-caps">
            <Link to="/treatments">See the full list</Link>
          </Button>
        </div>
      </section>

      <section className="bg-cream">
        <div className="mx-auto grid max-w-6xl gap-12 px-5 py-20 md:grid-cols-2">
          <div>
            <h2 className="display-caps text-2xl sm:text-3xl">Booking with us</h2>
            <p className="mt-6 text-sm leading-relaxed text-muted-foreground">
              Create an account with your contact details, choose your treatment and pick a time that suits you.
              Louise will review every request and confirm your appointment personally. Consultations are always
              complimentary.
            </p>
            <Button asChild className="label-caps mt-8">
              <Link to="/book">Request an appointment</Link>
            </Button>
          </div>
          <div>
            <h2 className="display-caps text-2xl sm:text-3xl">Opening hours</h2>
            <ul className="mt-6 space-y-2 text-sm text-muted-foreground">
              {OPENING_HOURS_TEXT.map((row) => (
                <li key={row.day} className="flex justify-between border-b border-border pb-2">
                  <span>{row.day}</span>
                  <span>{row.hours}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>
    </>
  );
}
