import { createFileRoute, Link } from "@tanstack/react-router";

import treatmentImage from "@/assets/treatment.jpg";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/about")({
  head: () => ({
    meta: [
      { title: "About Louise Oatley | Redbrook Clinic Salisbury" },
      {
        name: "description",
        content:
          "Redbrook Clinic is owned and run by Louise Oatley, an aesthetics practitioner with over 30 years of experience, from a private clinic near Salisbury.",
      },
      { property: "og:title", content: "About Louise Oatley | Redbrook Clinic Salisbury" },
      {
        property: "og:description",
        content: "Over 30 years in the cosmetic industry, now practising from a private clinic in Salisbury.",
      },
    ],
  }),
  component: About,
});

const TESTIMONIALS = [
  {
    quote:
      "Currently having laser removal. I was a bit dubious to start with, but the process so far has been amazing and Louise has been lovely. Would highly recommend.",
    name: "Elie Sims",
  },
  {
    quote:
      "Fantastic service, lovely clinic and extremely professional and knowledgeable. I feel very comfortable at every visit. So many treatments available, highly recommend!",
    name: "Laura Elizabeth",
  },
  {
    quote:
      "Louise not only provides excellent treatments but she is also so friendly, she put me totally at ease. Her clinic is beautiful with a calm, relaxing atmosphere and spotlessly clean.",
    name: "Verified patient",
  },
];

function About() {
  return (
    <>
      <section className="mx-auto max-w-4xl px-5 pt-20 text-center">
        <p className="label-caps text-muted-foreground">Welcome</p>
        <h1 className="display-caps mt-4 text-3xl sm:text-4xl">About the clinic</h1>
        <p className="mt-6 text-sm leading-relaxed text-muted-foreground">
          Redbrook Clinic is a private cosmetic and aesthetics clinic operating from the outskirts of the
          historic market town of Salisbury, with easy access and parking. The clinic is owned and run by Louise
          Oatley.
        </p>
      </section>

      <section className="mx-auto mt-16 grid max-w-6xl gap-12 px-5 md:grid-cols-2 md:items-center">
        <img
          src={treatmentImage}
          alt="Louise Oatley carrying out a facial treatment at Redbrook Clinic"
          width={1200}
          height={912}
          loading="lazy"
          className="w-full object-cover"
        />
        <div>
          <h2 className="display-caps text-2xl">About Louise Oatley</h2>
          <blockquote className="mt-6 space-y-4 text-sm leading-relaxed text-muted-foreground">
            <p>
              “I have been working in the cosmetic industry since 1988. My professional career has included
              working as a private therapist to Princess Diana for several years and teaching beauty and
              aesthetics.
            </p>
            <p>
              I have been in practice for over 30 years, in that time working in high end beauty clinics and with
              cosmetic surgeons. I now run my own exclusive private clinic. I am highly qualified, fully insured
              and registered with professional bodies for the aesthetics industry.”
            </p>
          </blockquote>
          <p className="mt-6 text-sm leading-relaxed text-muted-foreground">
            Redbrook Clinic provides a highly professional yet friendly service in a relaxed, comfortable
            setting.
          </p>
        </div>
      </section>

      <section className="mt-24 bg-cream">
        <div className="mx-auto max-w-6xl px-5 py-20">
          <h2 className="display-caps text-center text-2xl sm:text-3xl">What our patients say</h2>
          <div className="mt-12 grid gap-8 md:grid-cols-3">
            {TESTIMONIALS.map((item) => (
              <figure key={item.name} className="border-t border-border pt-6">
                <blockquote className="text-sm leading-relaxed text-muted-foreground">“{item.quote}”</blockquote>
                <figcaption className="label-caps mt-4">{item.name}</figcaption>
              </figure>
            ))}
          </div>
          <div className="mt-14 text-center">
            <Button asChild size="lg" className="label-caps">
              <Link to="/book">Book an appointment</Link>
            </Button>
          </div>
        </div>
      </section>
    </>
  );
}
