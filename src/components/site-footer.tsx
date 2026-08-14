import { Link } from "@tanstack/react-router";
import { CLINIC, OPENING_HOURS_TEXT } from "@/lib/clinic";

export function SiteFooter() {
  return (
    <footer className="mt-24 bg-taupe text-taupe-foreground">
      <div className="mx-auto grid max-w-6xl gap-10 px-5 py-16 sm:grid-cols-3">
        <div>
          <h2 className="display-caps text-xl">Location</h2>
          <p className="mt-4 text-sm leading-relaxed opacity-90">{CLINIC.address}</p>
          <p className="mt-3 text-sm opacity-80">Free parking beside the clinic on Maundrell Lane.</p>
        </div>
        <div>
          <h2 className="display-caps text-xl">Hours</h2>
          <ul className="mt-4 space-y-1 text-sm opacity-90">
            {OPENING_HOURS_TEXT.map((row) => (
              <li key={row.day} className="flex justify-between gap-4">
                <span>{row.day}</span>
                <span>{row.hours}</span>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <h2 className="display-caps text-xl">Contact</h2>
          <p className="mt-4 text-sm opacity-90">
            <a href={`mailto:${CLINIC.email}`} className="underline-offset-4 hover:underline">
              {CLINIC.email}
            </a>
          </p>
          <p className="mt-1 text-sm opacity-90">
            <a href={`tel:${CLINIC.phone.replace(/\s/g, "")}`} className="underline-offset-4 hover:underline">
              {CLINIC.phone}
            </a>
          </p>
          <Link to="/treatments" className="label-caps mt-6 inline-block underline-offset-4 hover:underline">
            Treatments &amp; Fees
          </Link>
        </div>
      </div>
      <div className="border-t border-white/15 py-5 text-center text-xs opacity-75">
        © {new Date().getFullYear()} {CLINIC.name}, Salisbury.
      </div>
    </footer>
  );
}
