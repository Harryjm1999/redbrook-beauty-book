CREATE TABLE public.loyalty_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  points integer NOT NULL,
  amount_spent numeric NULL,
  note text NULL,
  created_by uuid NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX loyalty_transactions_user_id_idx ON public.loyalty_transactions(user_id);
GRANT SELECT, INSERT ON public.loyalty_transactions TO authenticated;
GRANT ALL ON public.loyalty_transactions TO service_role;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Clients read own loyalty" ON public.loyalty_transactions FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Staff read all loyalty" ON public.loyalty_transactions FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "Staff add loyalty" ON public.loyalty_transactions FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));

CREATE OR REPLACE FUNCTION public.redeem_loyalty_voucher(_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE _total integer;
BEGIN
  IF NOT public.is_staff(auth.uid()) THEN RAISE EXCEPTION 'Only staff can redeem vouchers'; END IF;
  SELECT COALESCE(SUM(points),0) INTO _total FROM public.loyalty_transactions WHERE user_id = _user_id;
  IF _total < 100 THEN RAISE EXCEPTION 'Not enough points to redeem a voucher'; END IF;
  INSERT INTO public.loyalty_transactions (user_id, points, note) VALUES (_user_id, -100, 'Redeemed £10 voucher');
END; $$;
REVOKE ALL ON FUNCTION public.redeem_loyalty_voucher(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_voucher(uuid) TO authenticated;