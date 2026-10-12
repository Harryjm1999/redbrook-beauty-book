create policy "Patients delete own past bookings"
  on public.bookings
  for delete
  to authenticated
  using (auth.uid() = user_id and starts_at < now());