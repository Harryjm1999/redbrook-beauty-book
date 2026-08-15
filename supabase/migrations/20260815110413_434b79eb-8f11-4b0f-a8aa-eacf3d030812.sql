-- 1. Restrict blocked_dates reads to staff
DROP POLICY IF EXISTS "Authenticated read blocked dates" ON public.blocked_dates;

CREATE POLICY "Staff read blocked dates"
ON public.blocked_dates
FOR SELECT
TO authenticated
USING (public.is_staff(auth.uid()));

-- Day-only view for patients (no reason exposed)
CREATE OR REPLACE VIEW public.blocked_days AS
SELECT day FROM public.blocked_dates;

GRANT SELECT ON public.blocked_days TO authenticated;

-- 2. Lock down SECURITY DEFINER helper functions
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.is_staff(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;