import { Link, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Menu } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { useAuth } from "@/hooks/useAuth";
import { fetchIsStaff } from "@/lib/queries";
import { supabase } from "@/integrations/supabase/client";


const NAV = [
  { to: "/", label: "Home" },
  { to: "/treatments", label: "Treatments & Fees" },
  { to: "/about", label: "About Us" },
  { to: "/contact", label: "Contact" },
] as const;

export function SiteHeader() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);

  async function signOut() {
    await queryClient.cancelQueries();
    queryClient.clear();
    await supabase.auth.signOut();
    navigate({ to: "/", replace: true });
  }

  const links = (
    <>
      {NAV.map((item) => (
        <Link
          key={item.to}
          to={item.to}
          onClick={() => setOpen(false)}
          className="label-caps text-muted-foreground transition-colors hover:text-foreground"
          activeProps={{ className: "label-caps text-foreground" }}
          activeOptions={{ exact: item.to === "/" }}
        >
          {item.label}
        </Link>
      ))}
      {user ? (
        <Link
          to="/appointments"
          onClick={() => setOpen(false)}
          className="label-caps text-muted-foreground transition-colors hover:text-foreground"
          activeProps={{ className: "label-caps text-foreground" }}
        >
          My Appointments
        </Link>
      ) : null}
    </>
  );

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-cream/90 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-4">
        <Link to="/" className="display-caps text-lg leading-none sm:text-2xl">
          Redbrook Clinic
        </Link>

        <nav className="hidden items-center gap-7 lg:flex">{links}</nav>

        <div className="flex items-center gap-2">
          {!loading && user ? (
            <>
              <Button asChild size="sm">
                <Link to="/book">Book In</Link>
              </Button>
              <Button variant="ghost" size="sm" className="hidden sm:inline-flex" onClick={signOut}>
                Sign out
              </Button>
            </>
          ) : (
            <>
              <Button asChild variant="ghost" size="sm" className="hidden sm:inline-flex">
                <Link to="/auth">Sign in</Link>
              </Button>
              <Button asChild size="sm">
                <Link to="/auth" search={{ mode: "signup" }}>
                  Book In
                </Link>
              </Button>
            </>
          )}

          <Sheet open={open} onOpenChange={setOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon" className="lg:hidden" aria-label="Open menu">
                <Menu className="size-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="right" className="bg-cream">
              <nav className="mt-10 flex flex-col gap-6 px-6">
                {links}
                {user ? (
                  <button className="label-caps text-left text-muted-foreground" onClick={signOut}>
                    Sign out
                  </button>
                ) : (
                  <Link to="/auth" onClick={() => setOpen(false)} className="label-caps text-muted-foreground">
                    Sign in
                  </Link>
                )}
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  );
}
