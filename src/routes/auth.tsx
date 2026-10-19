import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { supabase } from "@/integrations/supabase/client";
import { lovable } from "@/integrations/lovable/index";
import { useAuth } from "@/hooks/useAuth";

type Search = { mode?: "signin" | "signup" };

export const Route = createFileRoute("/auth")({
  validateSearch: (search: Record<string, unknown>): Search => ({
    mode: search["mode"] === "signup" ? "signup" : "signin",
  }),
  head: () => ({
    meta: [
      { title: "Patient Sign In | Redbrook Clinic" },
      {
        name: "description",
        content:
          "Sign in or create a Redbrook Clinic patient account to request appointments and manage your bookings.",
      },
      { property: "og:title", content: "Patient Sign In | Redbrook Clinic" },
      { property: "og:description", content: "Manage your Redbrook Clinic appointments online." },
    ],
  }),
  component: AuthPage,
});

function AuthPage() {
  const { mode } = Route.useSearch();
  const navigate = useNavigate();
  const { user, loading } = useAuth();

  useEffect(() => {
    if (!loading && user) navigate({ to: "/book", replace: true });
  }, [loading, user, navigate]);

  return (
    <section className="mx-auto max-w-md px-5 py-20">
      <h1 className="display-caps text-center text-3xl">Patient area</h1>
      <p className="mt-3 text-center text-sm text-muted-foreground">
        Create an account with your contact details to request appointments.
      </p>

      <Tabs defaultValue={mode === "signup" ? "signup" : "signin"} className="mt-10">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="signin" className="label-caps">
            Sign in
          </TabsTrigger>
          <TabsTrigger value="signup" className="label-caps">
            Sign up
          </TabsTrigger>
        </TabsList>
        <TabsContent value="signin">
          <SignInForm />
        </TabsContent>
        <TabsContent value="signup">
          <SignUpForm />
        </TabsContent>
      </Tabs>

      <div className="mt-8">
        <div className="flex items-center gap-4">
          <span className="h-px flex-1 bg-border" />
          <span className="label-caps text-muted-foreground">or</span>
          <span className="h-px flex-1 bg-border" />
        </div>
        <AppleButton />
        <GoogleButton />
      </div>
    </section>
  );
}

function GoogleButton() {
  const [busy, setBusy] = useState(false);

  async function signInWithGoogle() {
    setBusy(true);
    const result = await lovable.auth.signInWithOAuth("google", {
      redirect_uri: window.location.origin,
    });
    if (result.error) {
      setBusy(false);
      toast.error("Google sign-in failed. Please try again or use your email address.");
      return;
    }
    if (result.redirected) return;
    setBusy(false);
  }

  return (
    <Button
      variant="outline"
      className="label-caps mt-6 w-full"
      onClick={signInWithGoogle}
      disabled={busy}
    >
      Continue with Google
    </Button>
  );
}

function AppleButton() {
  const [busy, setBusy] = useState(false);

  async function signInWithApple() {
    setBusy(true);
    const result = await lovable.auth.signInWithOAuth("apple", {
      redirect_uri: window.location.origin,
    });
    if (result.error) {
      setBusy(false);
      toast.error("Apple sign-in failed. Please try again or use your email address.");
      return;
    }
    if (result.redirected) return;
    setBusy(false);
  }

  return (
    <Button
      variant="outline"
      className="label-caps mt-6 w-full border-foreground bg-foreground text-background hover:bg-foreground/90"
      onClick={signInWithApple}
      disabled={busy}
    >
      <svg
        aria-hidden="true"
        viewBox="0 0 24 24"
        className="mr-2 h-4 w-4 fill-current"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
      </svg>
      {busy ? "Signing in…" : "Sign in with Apple"}
    </Button>
  );
}

function SignInForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Welcome back.");
  }

  return (
    <form onSubmit={onSubmit} className="mt-8 space-y-5">
      <div className="space-y-2">
        <Label htmlFor="signin-email" className="label-caps">
          Email
        </Label>
        <Input
          id="signin-email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="signin-password" className="label-caps">
          Password
        </Label>
        <Input
          id="signin-password"
          type="password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="current-password"
        />
      </div>
      <Button type="submit" className="label-caps w-full" disabled={busy}>
        {busy ? "Signing in…" : "Sign in"}
      </Button>
    </form>
  );
}

function SignUpForm() {
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: window.location.origin,
        data: { full_name: fullName, phone },
      },
    });
    setBusy(false);
    if (error) {
      toast.error(error.message);
      return;
    }
    if (!data.session) {
      setSent(true);
      toast.success("Almost there — check your email to confirm your account.");
      return;
    }
    toast.success("Account created.");
  }

  if (sent) {
    return (
      <div className="mt-8 space-y-6">
        <p className="text-sm leading-relaxed text-muted-foreground">
          We've sent a confirmation link to <strong className="text-foreground">{email}</strong>.
          Click it to activate your account, then sign in to request an appointment.
        </p>
        <ResendVerification initialEmail={email} />
      </div>
    );
  }

  return (
    <>
      <form onSubmit={onSubmit} className="mt-8 space-y-5">
        <div className="space-y-2">
          <Label htmlFor="signup-name" className="label-caps">
            Full name
          </Label>
          <Input
            id="signup-name"
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            autoComplete="name"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="signup-phone" className="label-caps">
            Contact number
          </Label>
          <Input
            id="signup-phone"
            type="tel"
            required
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            autoComplete="tel"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="signup-email" className="label-caps">
            Email
          </Label>
          <Input
            id="signup-email"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="signup-password" className="label-caps">
            Password
          </Label>
          <Input
            id="signup-password"
            type="password"
            required
            minLength={8}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="new-password"
          />
        </div>
        <Button type="submit" className="label-caps w-full" disabled={busy}>
          {busy ? "Creating account…" : "Create account"}
        </Button>
      </form>
      <div className="mt-8 border-t border-border pt-6">
        <ResendVerification initialEmail={email} />
      </div>
    </>
  );
}

function ResendVerification({ initialEmail }: { initialEmail: string }) {
  const [email, setEmail] = useState(initialEmail);
  const [busy, setBusy] = useState(false);

  async function onResend(e: React.FormEvent) {
    e.preventDefault();
    if (!email) return;
    setBusy(true);
    const { error } = await supabase.auth.resend({
      type: "signup",
      email,
      options: { emailRedirectTo: window.location.origin },
    });
    setBusy(false);
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Verification email sent. Please check your inbox and spam folder.");
  }

  return (
    <form onSubmit={onResend} className="space-y-3">
      <p className="label-caps text-muted-foreground">Didn't get your verification email?</p>
      <Label htmlFor="resend-email" className="sr-only">
        Email
      </Label>
      <Input
        id="resend-email"
        type="email"
        required
        placeholder="Your email address"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        autoComplete="email"
      />
      <Button
        type="submit"
        variant="outline"
        className="label-caps w-full"
        disabled={busy || !email}
      >
        {busy ? "Sending…" : "Resend verification email"}
      </Button>
    </form>
  );
}
