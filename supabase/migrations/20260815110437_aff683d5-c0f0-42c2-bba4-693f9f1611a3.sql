DROP VIEW IF EXISTS public.blocked_days;

CREATE TABLE public.blocked_date_reasons (
  blocked_date_id uuid PRIMARY KEY REFERENCES public.blocked_dates(id) ON DELETE CASCADE,
  reason text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.blocked_date_reasons TO authenticated;
GRANT ALL ON public.blocked_date_reasons TO service_role;

ALTER TABLE public.blocked_date_reasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff manage blocked date reasons"
ON public.blocked_date_reasons
FOR ALL
TO authenticated
USING (public.is_staff(auth.uid()))
WITH CHECK (public.is_staff(auth.uid()));

CREATE TRIGGER set_blocked_date_reasons_updated_at
BEFORE UPDATE ON public.blocked_date_reasons
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.blocked_date_reasons (blocked_date_id, reason)
SELECT id, reason FROM public.blocked_dates WHERE reason IS NOT NULL AND reason <> '';

ALTER TABLE public.blocked_dates DROP COLUMN reason;

DROP POLICY IF EXISTS "Staff read blocked dates" ON public.blocked_dates;
CREATE POLICY "Authenticated read blocked days"
ON public.blocked_dates
FOR SELECT
TO authenticated
USING (true);