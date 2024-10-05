-- Computed name description column
create function name_description(assets) returns text as $$
  select $1.name || ' ' || $1.description;
$$ language sql immutable;

create function name_description(spaces) returns text as $$
  select $1.name || ' ' || $1.description;
$$ language sql immutable;

-- create or replace function search_assets_by_title_description(prefix text)
-- returns setof assets AS $$
-- begin
--   return query
--   select * from assets where to_tsvector('english', title) @@ to_tsquery(prefix || ':*');
-- end;
-- $$ language plpgsql;
