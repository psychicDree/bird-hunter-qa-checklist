-- Bird Hunter QA Checklist — Supabase Schema
-- Run this in your Supabase SQL Editor

-- Sessions table: each QA run is a session
create table if not exists qa_sessions (
  id         bigserial primary key,
  name       text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Test results table: one row per (session, test_id)
create table if not exists qa_test_results (
  id         bigserial primary key,
  session_id bigint not null references qa_sessions(id) on delete cascade,
  test_id    text not null,          -- e.g. "2.3"
  status     text not null default 'none',  -- none | pass | fail | skip
  note       text not null default '',
  updated_at timestamptz not null default now(),
  unique(session_id, test_id)
);

-- Index for fast session lookups
create index if not exists idx_qa_test_results_session_id on qa_test_results(session_id);

-- Helper: update updated_at on sessions automatically
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace trigger qa_sessions_updated_at
  before update on qa_sessions
  for each row execute procedure update_updated_at();

create or replace trigger qa_test_results_updated_at
  before update on qa_test_results
  for each row execute procedure update_updated_at();

-- Enable Row Level Security (open policy for anon key — tighten per your needs)
alter table qa_sessions enable row level security;
alter table qa_test_results enable row level security;

create policy "Allow all for anon" on qa_sessions for all to anon using (true) with check (true);
create policy "Allow all for anon" on qa_test_results for all to anon using (true) with check (true);
