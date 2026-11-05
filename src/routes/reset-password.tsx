import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";

// The "reset your password" email links here (from the website and the iOS app).
// Opening the link signs the person in for long enough to choose a new password.
export const Route = createFileRoute("/reset-password")({
  head: () => ({
    meta: [{ title: "Reset Password | Redbrook Clinic" }, { name: "robots", content: "noindex" }],
  }),
  component: ResetPassword,
});

function ResetPassword() {
  const navigate = useNavigate();
  const { user, loading } = useAuth();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password.length < 8) {
      toast.error("Please use a password of at least 8 characters.");
      return;
    }
    if (password !== confirm) {
      toast.error("The two passwords don't match.");
      return;
    }
    setBusy(true);
    const { error } = await supabase.auth.updateUser({ password });
    setBusy(false);
    if (error) {
      toast.error(error.message);
      return;
    }
    setDone(true);
    toast.success("Password updated.");
  }

  return (
    <section className="mx-auto max-w-md px-5 py-20">
      <h1 className="display-caps text-center text-3xl">Reset password</h1>

      {loading ? null : done ? (
        <div className="mt-8 space-y-6 text-center">
          <p className="text-sm leading-relaxed text-muted-foreground">
            Your password has been changed. You can now sign in with it on the website or in the
            Redbrook Clinic app.
          </p>
          <Button className="label-caps w-full" onClick={() => navigate({ to: "/book" })}>
            Continue
          </Button>
        </div>
      ) : !user ? (
        <div className="mt-8 space-y-6 text-center">
          <p className="text-sm leading-relaxed text-muted-foreground">
            This reset link has expired or has already been used. Request a new one from the sign in
            page.
          </p>
          <Button asChild variant="outline" className="label-caps w-full">
            <Link to="/auth">Back to sign in</Link>
          </Button>
        </div>
      ) : (
        <form onSubmit={onSubmit} className="mt-8 space-y-5">
          <p className="text-sm leading-relaxed text-muted-foreground">
            Choose a new password for <strong className="text-foreground">{user.email}</strong>.
          </p>
          <div className="space-y-2">
            <Label htmlFor="reset-password" className="label-caps">
              New password
            </Label>
            <Input
              id="reset-password"
              type="password"
              required
              minLength={8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="new-password"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="reset-confirm" className="label-caps">
              Confirm new password
            </Label>
            <Input
              id="reset-confirm"
              type="password"
              required
              minLength={8}
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              autoComplete="new-password"
            />
          </div>
          <Button type="submit" className="label-caps w-full" disabled={busy}>
            {busy ? "Saving…" : "Save new password"}
          </Button>
        </form>
      )}
    </section>
  );
}
