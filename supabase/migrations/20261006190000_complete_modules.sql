-- باغ‌یار نسخه جامع: موجودیت‌های مستقل میوه/رقم و یادآوری‌ها
create table if not exists public.crops (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null, description text, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id, name)
);
create table if not exists public.varieties (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  crop_id uuid references public.crops(id) on delete set null, name text not null, description text, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id, crop_id, name)
);
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null, reminder_date date not null, reminder_type text not null default 'general', plot_id uuid references public.plots(id) on delete set null,
  priority text not null default 'normal', completed boolean not null default false, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists varieties_user_crop_idx on public.varieties(user_id, crop_id);
create index if not exists reminders_user_date_idx on public.reminders(user_id, reminder_date);

drop trigger if exists trg_crops_updated on public.crops;
create trigger trg_crops_updated before update on public.crops for each row execute function public.set_updated_at();
drop trigger if exists trg_varieties_updated on public.varieties;
create trigger trg_varieties_updated before update on public.varieties for each row execute function public.set_updated_at();
drop trigger if exists trg_reminders_updated on public.reminders;
create trigger trg_reminders_updated before update on public.reminders for each row execute function public.set_updated_at();

alter table public.crops enable row level security;
alter table public.varieties enable row level security;
alter table public.reminders enable row level security;

do $$
declare t text;
begin
  foreach t in array array['crops','varieties','reminders'] loop
    execute format('drop policy if exists "user_select_%I" on public.%I', t, t);
    execute format('drop policy if exists "user_insert_%I" on public.%I', t, t);
    execute format('drop policy if exists "user_update_%I" on public.%I', t, t);
    execute format('drop policy if exists "user_delete_%I" on public.%I', t, t);
    execute format('create policy "user_select_%I" on public.%I for select using (auth.uid() = user_id)', t, t);
    execute format('create policy "user_insert_%I" on public.%I for insert with check (auth.uid() = user_id)', t, t);
    execute format('create policy "user_update_%I" on public.%I for update using (auth.uid() = user_id) with check (auth.uid() = user_id)', t, t);
    execute format('create policy "user_delete_%I" on public.%I for delete using (auth.uid() = user_id)', t, t);
  end loop;
end $$;
