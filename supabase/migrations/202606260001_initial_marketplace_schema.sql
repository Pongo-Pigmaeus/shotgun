-- Shotgun marketplace schema.
-- Apply locally with: supabase db reset

create extension if not exists pgcrypto with schema extensions;

create type public.ride_status as enum ('active', 'sold_out', 'canceled', 'completed');
create type public.booking_status as enum ('pending', 'confirmed', 'canceled', 'completed');
create type public.payment_status as enum ('pending', 'authorized', 'succeeded', 'failed', 'refunded', 'voided');
create type public.payment_provider as enum ('demo', 'apple_pay', 'stripe');
create type public.payment_intent_status as enum (
  'requires_payment_method',
  'requires_confirmation',
  'authorized',
  'captured',
  'canceled',
  'failed'
);
create type public.refund_status as enum ('not_needed', 'pending', 'succeeded', 'failed');
create type public.payout_status as enum ('not_started', 'pending', 'available', 'paid', 'canceled');
create type public.luggage_allowance as enum ('backpack', 'carry_on', 'checked_bag');
create type public.ride_preference as enum (
  'no_smoking',
  'pets_allowed',
  'quiet_ride',
  'music_okay',
  'women_friendly',
  'charger_available'
);
create type public.report_reason as enum (
  'unsafe_behavior',
  'wrong_vehicle',
  'harassment',
  'payment_issue',
  'no_show',
  'other'
);
create type public.support_issue_type as enum ('booking', 'safety', 'payments', 'account');
create type public.support_ticket_status as enum ('open', 'in_review', 'resolved');
create type public.notification_platform as enum ('ios', 'android', 'web');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  phone_number text,
  bio text not null default '',
  avatar_url text,
  profile_symbol_name text not null default 'person.crop.circle',
  rating numeric(3, 2) not null default 5.00 check (rating >= 0 and rating <= 5),
  review_count integer not null default 0 check (review_count >= 0),
  is_verified boolean not null default false,
  phone_verified boolean not null default false,
  stripe_customer_id text,
  stripe_connect_account_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  make text not null,
  model text not null,
  color text not null,
  year integer not null check (year between 1980 and 2100),
  plate_state text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.rides (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.profiles(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  origin text not null,
  destination text not null,
  departure_at timestamptz not null,
  pickup_notes text not null default '',
  dropoff_notes text not null default '',
  seats_available integer not null check (seats_available >= 0),
  total_seats integer not null check (total_seats > 0),
  price_per_seat_cents integer not null check (price_per_seat_cents >= 0),
  luggage_allowance public.luggage_allowance not null default 'carry_on',
  preferences public.ride_preference[] not null default '{}',
  manual_approval_enabled boolean not null default true,
  status public.ride_status not null default 'active',
  canceled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rides_seats_available_lte_total check (seats_available <= total_seats),
  constraint rides_route_not_same check (lower(trim(origin)) <> lower(trim(destination)))
);

create table public.checkout_sessions (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  rider_id uuid not null references public.profiles(id) on delete cascade,
  seats integer not null check (seats > 0),
  amount_cents integer not null check (amount_cents >= 0),
  provider public.payment_provider not null default 'stripe',
  client_secret text,
  provider_payment_intent_id text,
  intent_status public.payment_intent_status not null default 'requires_confirmation',
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  rider_id uuid not null references public.profiles(id) on delete cascade,
  seats integer not null check (seats > 0),
  status public.booking_status not null default 'pending',
  checkout_session_id uuid references public.checkout_sessions(id) on delete set null,
  approved_at timestamptz,
  canceled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  checkout_session_id uuid references public.checkout_sessions(id) on delete set null,
  booking_id uuid unique references public.bookings(id) on delete cascade,
  rider_id uuid not null references public.profiles(id) on delete cascade,
  driver_id uuid not null references public.profiles(id) on delete cascade,
  amount_cents integer not null check (amount_cents >= 0),
  provider public.payment_provider not null default 'stripe',
  status public.payment_status not null default 'pending',
  intent_status public.payment_intent_status not null default 'requires_confirmation',
  refund_status public.refund_status not null default 'not_needed',
  payout_status public.payout_status not null default 'not_started',
  provider_payment_intent_id text,
  platform_fee_cents integer not null default 0 check (platform_fee_cents >= 0),
  driver_payout_cents integer not null default 0 check (driver_payout_cents >= 0),
  authorized_at timestamptz,
  captured_at timestamptz,
  refunded_at timestamptz,
  voided_at timestamptz,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payments_fee_lte_amount check (platform_fee_cents <= amount_cents),
  constraint payments_payout_lte_amount check (driver_payout_cents <= amount_cents)
);

create table public.driver_payouts (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  driver_id uuid not null references public.profiles(id) on delete cascade,
  amount_cents integer not null check (amount_cents >= 0),
  status public.payout_status not null default 'pending',
  available_on timestamptz not null default now(),
  paid_out_at timestamptz,
  stripe_transfer_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.booking_events (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  from_status public.booking_status,
  to_status public.booking_status not null,
  note text not null default '',
  created_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  last_updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) > 0),
  sent_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  subject_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  body text not null default '',
  created_at timestamptz not null default now(),
  constraint reviews_author_not_subject check (author_id <> subject_id),
  constraint reviews_one_per_subject_per_ride unique (ride_id, author_id, subject_id)
);

create table public.trust_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  subject_id uuid references public.profiles(id) on delete set null,
  ride_id uuid references public.rides(id) on delete set null,
  reason public.report_reason not null,
  details text not null default '',
  is_emergency boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.saved_rides (
  user_id uuid not null references public.profiles(id) on delete cascade,
  ride_id uuid not null references public.rides(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, ride_id)
);

create table public.saved_routes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  origin text not null,
  destination text not null,
  created_at timestamptz not null default now(),
  constraint saved_routes_route_not_same check (lower(trim(origin)) <> lower(trim(destination))),
  constraint saved_routes_unique_user_route unique (user_id, origin, destination)
);

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider public.payment_provider not null default 'stripe',
  label text not null,
  detail text not null,
  provider_payment_method_id text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payout_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  bank_name text not null default '',
  last_four text not null default '',
  stripe_connect_account_id text,
  is_verified boolean not null default false,
  instant_payouts_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  phone_number text not null,
  relationship text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  issue_type public.support_issue_type not null,
  status public.support_ticket_status not null default 'open',
  title text not null,
  details text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notification_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform public.notification_platform not null default 'ios',
  device_token text not null,
  app_version text,
  notifications_enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notification_devices_unique_token unique (platform, device_token)
);

create index profiles_rating_idx on public.profiles (rating desc);
create index vehicles_owner_id_idx on public.vehicles (owner_id);
create index rides_search_idx on public.rides (origin, destination, departure_at) where status = 'active';
create index rides_driver_status_idx on public.rides (driver_id, status, departure_at);
create index bookings_ride_status_idx on public.bookings (ride_id, status);
create index bookings_rider_status_idx on public.bookings (rider_id, status, created_at desc);
create index payments_booking_id_idx on public.payments (booking_id);
create index payments_rider_driver_idx on public.payments (rider_id, driver_id);
create index driver_payouts_driver_status_idx on public.driver_payouts (driver_id, status, available_on);
create index conversations_booking_id_idx on public.conversations (booking_id);
create index conversation_participants_user_id_idx on public.conversation_participants (user_id);
create index messages_conversation_sent_idx on public.messages (conversation_id, sent_at);
create index reviews_subject_created_idx on public.reviews (subject_id, created_at desc);
create index trust_reports_reporter_created_idx on public.trust_reports (reporter_id, created_at desc);
create index notification_devices_user_idx on public.notification_devices (user_id);

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger vehicles_set_updated_at before update on public.vehicles
  for each row execute function public.set_updated_at();
create trigger rides_set_updated_at before update on public.rides
  for each row execute function public.set_updated_at();
create trigger bookings_set_updated_at before update on public.bookings
  for each row execute function public.set_updated_at();
create trigger payments_set_updated_at before update on public.payments
  for each row execute function public.set_updated_at();
create trigger driver_payouts_set_updated_at before update on public.driver_payouts
  for each row execute function public.set_updated_at();
create trigger payment_methods_set_updated_at before update on public.payment_methods
  for each row execute function public.set_updated_at();
create trigger payout_accounts_set_updated_at before update on public.payout_accounts
  for each row execute function public.set_updated_at();
create trigger emergency_contacts_set_updated_at before update on public.emergency_contacts
  for each row execute function public.set_updated_at();
create trigger support_tickets_set_updated_at before update on public.support_tickets
  for each row execute function public.set_updated_at();
create trigger notification_devices_set_updated_at before update on public.notification_devices
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_ride_driver(ride uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rides
    where id = ride and driver_id = auth.uid()
  );
$$;

create or replace function public.is_booking_party(booking uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.bookings b
    join public.rides r on r.id = b.ride_id
    where b.id = booking
      and (b.rider_id = auth.uid() or r.driver_id = auth.uid())
  );
$$;

create or replace function public.is_conversation_participant(conversation uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants
    where conversation_id = conversation and user_id = auth.uid()
  );
$$;

create or replace view public.ride_results
with (security_invoker = true)
as
select
  r.id,
  r.origin,
  r.destination,
  r.departure_at,
  r.pickup_notes,
  r.dropoff_notes,
  r.seats_available,
  r.total_seats,
  r.price_per_seat_cents,
  r.luggage_allowance,
  r.preferences,
  r.manual_approval_enabled,
  r.status,
  p.id as driver_id,
  p.name as driver_name,
  p.rating as driver_rating,
  p.review_count as driver_review_count,
  p.is_verified as driver_is_verified,
  v.id as vehicle_id,
  v.make as vehicle_make,
  v.model as vehicle_model,
  v.color as vehicle_color,
  v.year as vehicle_year,
  v.plate_state as vehicle_plate_state
from public.rides r
join public.profiles p on p.id = r.driver_id
join public.vehicles v on v.id = r.vehicle_id;

alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.rides enable row level security;
alter table public.checkout_sessions enable row level security;
alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.driver_payouts enable row level security;
alter table public.booking_events enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.trust_reports enable row level security;
alter table public.saved_rides enable row level security;
alter table public.saved_routes enable row level security;
alter table public.payment_methods enable row level security;
alter table public.payout_accounts enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.support_tickets enable row level security;
alter table public.notification_devices enable row level security;

create policy "Profiles are visible to signed in users"
on public.profiles for select to authenticated
using (true);

create policy "Users insert their own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "Users update their own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "Vehicles visible to owner or active ride users"
on public.vehicles for select to authenticated
using (
  owner_id = auth.uid()
  or exists (
    select 1 from public.rides r
    where r.vehicle_id = vehicles.id
      and (
        r.status = 'active'
        or r.driver_id = auth.uid()
        or exists (
          select 1 from public.bookings b
          where b.ride_id = r.id and b.rider_id = auth.uid()
        )
      )
  )
);

create policy "Drivers manage their vehicles"
on public.vehicles for all to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "Active and related rides are visible"
on public.rides for select to authenticated
using (
  status = 'active'
  or driver_id = auth.uid()
  or exists (
    select 1 from public.bookings b
    where b.ride_id = rides.id and b.rider_id = auth.uid()
  )
);

create policy "Drivers create their rides"
on public.rides for insert to authenticated
with check (driver_id = auth.uid());

create policy "Drivers update their rides"
on public.rides for update to authenticated
using (driver_id = auth.uid())
with check (driver_id = auth.uid());

create policy "Riders view their checkout sessions"
on public.checkout_sessions for select to authenticated
using (rider_id = auth.uid());

create policy "Booking parties can read bookings"
on public.bookings for select to authenticated
using (
  rider_id = auth.uid()
  or public.is_ride_driver(ride_id)
);

create policy "Booking parties can read payments"
on public.payments for select to authenticated
using (rider_id = auth.uid() or driver_id = auth.uid());

create policy "Drivers can read their payouts"
on public.driver_payouts for select to authenticated
using (driver_id = auth.uid());

create policy "Booking parties can read booking events"
on public.booking_events for select to authenticated
using (public.is_booking_party(booking_id));

create policy "Participants can read conversations"
on public.conversations for select to authenticated
using (public.is_conversation_participant(id));

create policy "Participants can read conversation participants"
on public.conversation_participants for select to authenticated
using (public.is_conversation_participant(conversation_id));

create policy "Participants can read messages"
on public.messages for select to authenticated
using (public.is_conversation_participant(conversation_id));

create policy "Participants can send messages"
on public.messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and public.is_conversation_participant(conversation_id)
);

create policy "Reviews are visible to signed in users"
on public.reviews for select to authenticated
using (true);

create policy "Completed ride parties can write reviews"
on public.reviews for insert to authenticated
with check (
  author_id = auth.uid()
  and exists (
    select 1
    from public.bookings b
    join public.rides r on r.id = b.ride_id
    where b.ride_id = reviews.ride_id
      and b.status = 'completed'
      and (b.rider_id = auth.uid() or r.driver_id = auth.uid())
      and subject_id in (b.rider_id, r.driver_id)
      and subject_id <> auth.uid()
  )
);

create policy "Reporters can create reports"
on public.trust_reports for insert to authenticated
with check (reporter_id = auth.uid());

create policy "Reporters can read their reports"
on public.trust_reports for select to authenticated
using (reporter_id = auth.uid());

create policy "Users manage saved rides"
on public.saved_rides for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users manage saved routes"
on public.saved_routes for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users manage payment methods"
on public.payment_methods for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users manage payout accounts"
on public.payout_accounts for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users manage emergency contacts"
on public.emergency_contacts for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users manage support tickets"
on public.support_tickets for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Users manage notification devices"
on public.notification_devices for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos',
  'profile-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "Profile photos are publicly readable"
on storage.objects for select to public
using (bucket_id = 'profile-photos');

create policy "Users upload their own profile photos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Users update their own profile photos"
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'profile-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Users delete their own profile photos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);
