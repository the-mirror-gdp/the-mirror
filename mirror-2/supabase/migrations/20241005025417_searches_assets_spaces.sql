create or replace function search_assets_by_name_prefix(prefix text)
returns setof assets AS $$
begin
  return query
  select * from assets where to_tsvector('english', name) @@ to_tsquery(prefix || ':*');
end;
$$ language plpgsql;

create or replace function search_spaces_by_name_prefix(prefix text)
returns setof spaces AS $$
begin
  return query
  select * from spaces where to_tsvector('english', name) @@ to_tsquery(prefix || ':*');
end;
$$ language plpgsql;
