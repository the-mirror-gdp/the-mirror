-- set up storage for imports
insert into
  storage.buckets (id, name, public)
values
  ('pc-imports', 'pc-imports', false);

CREATE POLICY "Users can access their own imports" ON storage.objects
  FOR ALL
  USING (auth.uid() = owner)
  WITH CHECK (auth.uid() = owner);
