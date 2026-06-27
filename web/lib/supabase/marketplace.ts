import type { SupabaseClient, User } from "@supabase/supabase-js"
import type { AppUser, Booking, BookingStatus, Conversation, Message, PaymentStatus, Review, Ride, RideStatus, Vehicle } from "@/lib/types"
import { createSupabaseBrowserClient, hasSupabaseConfig } from "./client"

export type BackendMode = "not_configured" | "demo" | "connected" | "empty" | "error"

export type BackendStatus = {
  mode: BackendMode
  message: string
}

export type MarketplaceSnapshot = {
  currentUserId: string
  users: AppUser[]
  vehicles: Vehicle[]
  rides: Ride[]
  bookings: Booking[]
  conversations: Conversation[]
  reviews: Review[]
  status: BackendStatus
}

export type SupabaseAuthUser = Pick<User, "id" | "email" | "user_metadata">

export type BookRideFunctionPayload = {
  rideID: string
  seats: number
}

export type BookingActionFunctionPayload = {
  bookingID: string
  reason?: string
}

export type SendMessageFunctionPayload = {
  conversationID: string
  body: string
}

type ProfileRow = {
  id: string
  name: string
  phone_number: string | null
  bio: string
  avatar_url: string | null
  profile_symbol_name: string
  rating: number | string
  review_count: number
  is_verified: boolean
  phone_verified: boolean
}

type VehicleRow = {
  id: string
  owner_id: string
  make: string
  model: string
  color: string
  year: number
  plate_state: string
}

type RideRow = {
  id: string
  driver_id: string
  vehicle_id: string
  origin: string
  destination: string
  departure_at: string
  pickup_notes: string
  dropoff_notes: string
  seats_available: number
  total_seats: number
  price_per_seat_cents: number
  luggage_allowance: string
  preferences: string[]
  manual_approval_enabled: boolean
  status: string
}

type BookingRow = {
  id: string
  ride_id: string
  rider_id: string
  seats: number
  status: string
  created_at: string
}

type PaymentRow = {
  id: string
  booking_id: string | null
  amount_cents: number
  status: string
  note: string
}

type ConversationRow = {
  id: string
  ride_id: string
  booking_id: string | null
}

type ParticipantRow = {
  conversation_id: string
  user_id: string
}

type MessageRow = {
  id: string
  conversation_id: string
  sender_id: string
  body: string
  sent_at: string
}

type ReviewRow = {
  id: string
  author_id: string
  subject_id: string
  rating: number
  body: string
}

export function backendUnavailableStatus(): BackendStatus {
  return hasSupabaseConfig()
    ? { mode: "demo", message: "Supabase is configured. Local demo data is only the signed-out fallback." }
    : { mode: "not_configured", message: "Missing Supabase environment variables." }
}

export function getSupabaseClient() {
  if (!hasSupabaseConfig()) return null
  return createSupabaseBrowserClient()
}

export async function getSupabaseUser() {
  const supabase = getSupabaseClient()
  if (!supabase) return null
  const { data } = await supabase.auth.getUser()
  return data.user
}

export async function signInWithApple() {
  const supabase = createSupabaseBrowserClient()
  return supabase.auth.signInWithOAuth({
    provider: "apple",
    options: {
      redirectTo: typeof window === "undefined" ? undefined : window.location.origin,
    },
  })
}

export async function signInDemoUser() {
  const supabase = createSupabaseBrowserClient()
  const { data, error } = await supabase.auth.signInAnonymously()
  if (error) return { user: null, error }
  if (data.user) {
    await ensureProfile(supabase, data.user)
  }
  return { user: data.user, error: null }
}

export async function signOutSupabase() {
  const supabase = getSupabaseClient()
  if (!supabase) return
  await supabase.auth.signOut()
}

export async function bookRideWithSupabase(payload: BookRideFunctionPayload) {
  return invokeMarketplaceFunction("book-ride", payload)
}

export async function cancelBookingWithSupabase(payload: BookingActionFunctionPayload) {
  return invokeMarketplaceFunction("cancel-booking", payload)
}

export async function approveBookingWithSupabase(payload: BookingActionFunctionPayload) {
  return invokeMarketplaceFunction("approve-booking", payload)
}

export async function declineBookingWithSupabase(payload: BookingActionFunctionPayload) {
  return invokeMarketplaceFunction("decline-booking", payload)
}

export async function sendMessageWithSupabase(payload: SendMessageFunctionPayload) {
  return invokeMarketplaceFunction("send-message", payload)
}

export async function loadMarketplaceSnapshot(user: SupabaseAuthUser): Promise<MarketplaceSnapshot> {
  const supabase = createSupabaseBrowserClient()
  await ensureProfile(supabase, user)

  const [profilesResult, vehiclesResult, ridesResult, bookingsResult, paymentsResult, conversationsResult, participantsResult, messagesResult, reviewsResult] =
    await Promise.all([
      supabase.from("profiles").select("*").returns<ProfileRow[]>(),
      supabase.from("vehicles").select("*").returns<VehicleRow[]>(),
      supabase.from("rides").select("*").order("departure_at", { ascending: true }).returns<RideRow[]>(),
      supabase.from("bookings").select("*").order("created_at", { ascending: false }).returns<BookingRow[]>(),
      supabase.from("payments").select("*").returns<PaymentRow[]>(),
      supabase.from("conversations").select("*").returns<ConversationRow[]>(),
      supabase.from("conversation_participants").select("*").returns<ParticipantRow[]>(),
      supabase.from("messages").select("*").order("sent_at", { ascending: true }).returns<MessageRow[]>(),
      supabase.from("reviews").select("*").returns<ReviewRow[]>(),
    ])

  const firstError = [
    profilesResult.error,
    vehiclesResult.error,
    ridesResult.error,
    bookingsResult.error,
    paymentsResult.error,
    conversationsResult.error,
    participantsResult.error,
    messagesResult.error,
    reviewsResult.error,
  ].find(Boolean)

  if (firstError) {
    throw firstError
  }

  const profiles = profilesResult.data ?? []
  const vehicles = vehiclesResult.data ?? []
  const rides = ridesResult.data ?? []

  const paymentsByBookingId = new Map((paymentsResult.data ?? []).filter((payment) => payment.booking_id).map((payment) => [payment.booking_id as string, payment]))
  const messagesByConversationId = groupBy(messagesResult.data ?? [], (message) => message.conversation_id)
  const participantsByConversationId = groupBy(participantsResult.data ?? [], (participant) => participant.conversation_id)
  const liveRows = profiles.length + vehicles.length + rides.length + (bookingsResult.data?.length ?? 0) + (conversationsResult.data?.length ?? 0)

  return {
    currentUserId: user.id,
    users: profiles.map(mapProfile),
    vehicles: vehicles.map(mapVehicle),
    rides: rides.map(mapRide),
    bookings: (bookingsResult.data ?? []).map((booking) => mapBooking(booking, paymentsByBookingId.get(booking.id))),
    conversations: (conversationsResult.data ?? []).map((conversation) =>
      mapConversation(conversation, participantsByConversationId.get(conversation.id) ?? [], messagesByConversationId.get(conversation.id) ?? []),
    ),
    reviews: (reviewsResult.data ?? []).map(mapReview),
    status: {
      mode: liveRows === 0 || rides.length === 0 ? "empty" : "connected",
      message: rides.length === 0
        ? "Connected to Supabase. Live marketplace rows are empty."
        : "Live Supabase session and marketplace tables are connected.",
    },
  }
}

async function ensureProfile(supabase: SupabaseClient, user: SupabaseAuthUser) {
  const fullName = user.user_metadata?.full_name ?? user.user_metadata?.name ?? "Alex Morgan"
  const emailName = user.email?.split("@")[0]
  const name = typeof fullName === "string" && fullName.trim().length > 0 ? fullName : emailName ?? "Alex Morgan"

  await supabase.from("profiles").upsert(
    {
      id: user.id,
      name,
      bio: "Shotgun rider and driver.",
      profile_symbol_name: initials(name),
      is_verified: true,
    },
    { onConflict: "id" },
  )
}

async function invokeMarketplaceFunction(functionName: string, body: Record<string, unknown>) {
  const supabase = createSupabaseBrowserClient()
  const { data, error } = await supabase.functions.invoke(functionName, { body })

  if (error) {
    throw new Error(error.message || `Could not reach ${functionName}.`)
  }

  const response = data as { error?: { message?: string }; status?: string } | null
  if (response?.error?.message) {
    throw new Error(response.error.message)
  }

  return data
}

function mapProfile(row: ProfileRow): AppUser {
  return {
    id: row.id,
    name: row.name || "Shotgun user",
    firstName: (row.name || "Shotgun").split(" ")[0],
    phone: row.phone_number ?? "Phone pending",
    bio: row.bio,
    rating: Number(row.rating),
    reviews: row.review_count,
    verified: row.is_verified || row.phone_verified,
    symbol: row.profile_symbol_name?.length <= 3 ? row.profile_symbol_name : initials(row.name),
  }
}

function mapVehicle(row: VehicleRow): Vehicle {
  return {
    id: row.id,
    ownerId: row.owner_id,
    make: row.make,
    model: row.model,
    color: row.color,
    year: row.year,
    plateState: row.plate_state,
  }
}

function mapRide(row: RideRow): Ride {
  return {
    id: row.id,
    driverId: row.driver_id,
    vehicleId: row.vehicle_id,
    origin: row.origin,
    destination: row.destination,
    departureTime: formatDeparture(row.departure_at),
    pickupNotes: row.pickup_notes,
    dropoffNotes: row.dropoff_notes,
    seatsAvailable: row.seats_available,
    totalSeats: row.total_seats,
    price: Math.round(row.price_per_seat_cents / 100),
    luggage: formatEnum(row.luggage_allowance),
    preferences: row.preferences.map(formatEnum),
    manualApproval: row.manual_approval_enabled,
    status: mapRideStatus(row.status),
  }
}

function mapBooking(row: BookingRow, payment?: PaymentRow): Booking {
  return {
    id: row.id,
    rideId: row.ride_id,
    riderId: row.rider_id,
    seats: row.seats,
    status: mapBookingStatus(row.status),
    payment: {
      id: payment?.id ?? `payment-${row.id}`,
      amount: Math.round((payment?.amount_cents ?? 0) / 100),
      status: mapPaymentStatus(payment?.status ?? "pending"),
      note: payment?.note ?? "Payment pending.",
    },
    createdAt: formatDeparture(row.created_at),
  }
}

function mapConversation(row: ConversationRow, participants: ParticipantRow[], messages: MessageRow[]): Conversation {
  return {
    id: row.id,
    rideId: row.ride_id,
    bookingId: row.booking_id ?? "",
    participantIds: participants.map((participant) => participant.user_id),
    messages: messages.map(mapMessage),
  }
}

function mapMessage(row: MessageRow): Message {
  return {
    id: row.id,
    senderId: row.sender_id,
    body: row.body,
    sentAt: formatDeparture(row.sent_at),
  }
}

function mapReview(row: ReviewRow): Review {
  return {
    id: row.id,
    authorId: row.author_id,
    subjectId: row.subject_id,
    rating: row.rating,
    body: row.body,
  }
}

function mapRideStatus(status: string): RideStatus {
  if (status === "sold_out") return "sold out"
  if (status === "canceled" || status === "completed") return status
  return "active"
}

function mapBookingStatus(status: string): BookingStatus {
  if (status === "confirmed" || status === "canceled" || status === "completed") return status
  return "pending"
}

function mapPaymentStatus(status: string): PaymentStatus {
  if (status === "authorized" || status === "succeeded" || status === "failed" || status === "refunded" || status === "voided") return status
  return "pending"
}

function formatDeparture(value: string) {
  return new Intl.DateTimeFormat("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value))
}

function formatEnum(value: string) {
  return value
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ")
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  return (parts[0]?.[0] ?? "S") + (parts[1]?.[0] ?? "")
}

function groupBy<T>(items: T[], getKey: (item: T) => string) {
  return items.reduce((groups, item) => {
    const key = getKey(item)
    groups.set(key, [...(groups.get(key) ?? []), item])
    return groups
  }, new Map<string, T[]>())
}
