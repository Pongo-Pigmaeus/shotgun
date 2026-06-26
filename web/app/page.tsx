"use client"

import {
  Apple,
  BadgeCheck,
  Bell,
  CalendarDays,
  Car,
  Check,
  ChevronRight,
  CircleDollarSign,
  Clock,
  CreditCard,
  Flag,
  Gauge,
  Heart,
  Inbox,
  IdCard,
  LifeBuoy,
  LockKeyhole,
  MapPin,
  MessageCircle,
  Moon,
  Phone,
  Receipt,
  Route,
  Search,
  Send,
  Settings,
  ShieldAlert,
  ShieldCheck,
  Siren,
  SlidersHorizontal,
  Smartphone,
  Star,
  Ticket,
  Trash2,
  TriangleAlert,
  UserRound,
  Users,
  Wallet,
  X,
} from "lucide-react"
import { type ElementType, type FormEvent, useMemo, useState } from "react"
import {
  cities,
  conversations as seedConversations,
  currentUserId,
  popularRoutes,
  reviews as seedReviews,
  rides as seedRides,
  users,
  vehicles,
  bookings as seedBookings,
} from "@/lib/mock-data"
import type { Booking, BookingStatus, Conversation, PaymentStatus, Review, Ride } from "@/lib/types"

type Tab = "search" | "trips" | "drive" | "inbox" | "safety" | "profile" | "settings"
type ThemeChoice = "system" | "light" | "dark"

type SearchState = {
  origin: string
  destination: string
  date: string
  seats: number
}

type ListingDraft = {
  origin: string
  destination: string
  departureTime: string
  pickupNotes: string
  dropoffNotes: string
  seatsAvailable: number
  price: number
  luggage: string
  preferences: string[]
  manualApproval: boolean
}

const navItems: { id: Tab; label: string; icon: ElementType }[] = [
  { id: "search", label: "Search", icon: Search },
  { id: "trips", label: "Trips", icon: Ticket },
  { id: "drive", label: "Drive", icon: Car },
  { id: "inbox", label: "Inbox", icon: Inbox },
  { id: "safety", label: "Safety", icon: ShieldAlert },
  { id: "profile", label: "Profile", icon: UserRound },
  { id: "settings", label: "Settings", icon: Settings },
]

export default function ShotgunWebApp() {
  const [activeTab, setActiveTab] = useState<Tab>("search")
  const [isSignedIn, setIsSignedIn] = useState(false)
  const [authMode, setAuthMode] = useState<"apple" | "demo">("demo")
  const [searchState, setSearchState] = useState<SearchState>({
    origin: "New York, NY",
    destination: "Newport, RI",
    date: "Tomorrow",
    seats: 1,
  })
  const [rides, setRides] = useState<Ride[]>(seedRides)
  const [bookings, setBookings] = useState<Booking[]>(seedBookings)
  const [conversations, setConversations] = useState<Conversation[]>(seedConversations)
  const [reviews, setReviews] = useState<Review[]>(seedReviews)
  const [reports, setReports] = useState<string[]>([])
  const [selectedRideId, setSelectedRideId] = useState<string>("nyc-newport")
  const [checkoutRide, setCheckoutRide] = useState<Ride | null>(null)
  const [bookingSeats, setBookingSeats] = useState(1)
  const [savedRideIds, setSavedRideIds] = useState<string[]>(["nyc-newport"])
  const [quietMode, setQuietMode] = useState(false)
  const [notifications, setNotifications] = useState(true)
  const [theme, setTheme] = useState<ThemeChoice>("system")
  const [driverViewUserId, setDriverViewUserId] = useState(currentUserId)
  const [notice, setNotice] = useState("")

  const selectedRide = rides.find((ride) => ride.id === selectedRideId) ?? rides[0]
  const results = useMemo(() => {
    return rides.filter((ride) => {
      return (
        ride.status === "active" &&
        ride.seatsAvailable >= searchState.seats &&
        cityMatches(ride.origin, searchState.origin) &&
        cityMatches(ride.destination, searchState.destination)
      )
    })
  }, [rides, searchState])

  function signIn(mode: "apple" | "demo") {
    setAuthMode(mode)
    setIsSignedIn(true)
    setNotice(mode === "apple" ? "Signed in with Apple placeholder." : "Demo mode ready.")
  }

  function signOut() {
    setIsSignedIn(false)
    setActiveTab("search")
    setNotice("")
  }

  function bookRide(ride: Ride) {
    if (bookingSeats < 1 || bookingSeats > ride.seatsAvailable) return

    const bookingStatus: BookingStatus = ride.manualApproval ? "pending" : "confirmed"
    const paymentStatus: PaymentStatus = ride.manualApproval ? "authorized" : "succeeded"
    const booking: Booking = {
      id: `booking-${Date.now()}`,
      rideId: ride.id,
      riderId: currentUserId,
      seats: bookingSeats,
      status: bookingStatus,
      payment: {
        id: `payment-${Date.now()}`,
        amount: ride.price * bookingSeats + serviceFee(ride.price * bookingSeats),
        status: paymentStatus,
        note: ride.manualApproval
          ? "Stripe authorization held until driver approval."
          : "Stripe checkout captured in demo mode.",
      },
      createdAt: "Just now",
    }

    setBookings((current) => [booking, ...current])
    setRides((current) =>
      current.map((item) => {
        if (item.id !== ride.id) return item
        const seatsAvailable = item.seatsAvailable - bookingSeats
        return {
          ...item,
          seatsAvailable,
          status: seatsAvailable === 0 ? "sold out" : item.status,
        }
      }),
    )
    setConversations((current) => [
      {
        id: `conversation-${Date.now()}`,
        rideId: ride.id,
        bookingId: booking.id,
        participantIds: [currentUserId, ride.driverId],
        messages: [
          {
            id: `message-${Date.now()}`,
            senderId: ride.driverId,
            body: ride.manualApproval
              ? "Thanks for the request. I will review it shortly."
              : "Thanks for booking. I will send exact pickup details the morning of the ride.",
            sentAt: "Now",
          },
        ],
      },
      ...current,
    ])
    setDriverViewUserId(ride.driverId)
    setNotice(`${userById(ride.driverId).firstName}'s driver dashboard now shows this booking.`)
    setCheckoutRide(null)
    setActiveTab("trips")
  }

  function createRideListing(draft: ListingDraft) {
    const vehicle = vehicles.find((item) => item.ownerId === currentUserId) ?? vehicles[0]
    const ride: Ride = {
      id: `ride-${Date.now()}`,
      driverId: currentUserId,
      vehicleId: vehicle.id,
      origin: draft.origin,
      destination: draft.destination,
      departureTime: draft.departureTime,
      pickupNotes: draft.pickupNotes,
      dropoffNotes: draft.dropoffNotes,
      seatsAvailable: draft.seatsAvailable,
      totalSeats: draft.seatsAvailable,
      price: draft.price,
      luggage: draft.luggage,
      preferences: draft.preferences,
      manualApproval: draft.manualApproval,
      status: "active",
    }

    setRides((current) => [ride, ...current])
    setDriverViewUserId(currentUserId)
    setSelectedRideId(ride.id)
    setNotice("Your new listing is live in demo mode.")
    setActiveTab("drive")
  }

  function acceptBooking(bookingId: string) {
    setBookings((current) =>
      current.map((booking) =>
        booking.id === bookingId
          ? {
              ...booking,
              status: "confirmed",
              payment: {
                ...booking.payment,
                status: "succeeded",
                note: "Payment captured. Driver payout pending.",
              },
            }
          : booking,
      ),
    )
  }

  function cancelBooking(bookingId: string) {
    const booking = bookings.find((item) => item.id === bookingId)
    if (!booking) return
    setBookings((current) =>
      current.map((item) =>
        item.id === bookingId
          ? {
              ...item,
              status: "canceled",
              payment: {
                ...item.payment,
                status: item.payment.status === "authorized" ? "voided" : "refunded",
                note: item.payment.status === "authorized" ? "Authorization voided." : "Refund recorded.",
              },
            }
          : item,
      ),
    )
    setRides((current) =>
      current.map((ride) =>
        ride.id === booking.rideId
          ? { ...ride, seatsAvailable: Math.min(ride.totalSeats, ride.seatsAvailable + booking.seats), status: "active" }
          : ride,
      ),
    )
  }

  function completeBooking(bookingId: string) {
    const booking = bookings.find((item) => item.id === bookingId)
    if (!booking) return
    setBookings((current) =>
      current.map((item) => (item.id === bookingId ? { ...item, status: "completed" } : item)),
    )
    setNotice("Trip marked completed. Reviews are now available.")
  }

  function addReview(bookingId: string, rating: number, body: string) {
    const booking = bookings.find((item) => item.id === bookingId)
    const ride = booking ? rides.find((item) => item.id === booking.rideId) : undefined
    if (!booking || !ride || !body.trim()) return
    const review: Review = {
      id: `review-${bookingId}-${Date.now()}`,
      authorId: currentUserId,
      subjectId: ride.driverId,
      rating,
      body: body.trim(),
    }
    setReviews((current) => [review, ...current])
    setNotice("Review posted.")
  }

  function sendMessage(conversationId: string, body: string) {
    if (!body.trim()) return
    setConversations((current) =>
      current.map((conversation) =>
        conversation.id === conversationId
          ? {
              ...conversation,
              messages: [
                ...conversation.messages,
                {
                  id: `message-${Date.now()}`,
                  senderId: currentUserId,
                  body: body.trim(),
                  sentAt: "Now",
                },
              ],
            }
          : conversation,
      ),
    )
  }

  function cancelRide(rideId: string) {
    setRides((current) =>
      current.map((ride) => (ride.id === rideId ? { ...ride, status: "canceled", seatsAvailable: 0 } : ride)),
    )
    setBookings((current) =>
      current.map((booking) =>
        booking.rideId === rideId && (booking.status === "pending" || booking.status === "confirmed")
          ? {
              ...booking,
              status: "canceled",
              payment: {
                ...booking.payment,
                status: booking.payment.status === "authorized" ? "voided" : "refunded",
                note: booking.payment.status === "authorized" ? "Authorization voided." : "Refund recorded.",
              },
            }
          : booking,
      ),
    )
    setNotice("Ride canceled and active bookings updated.")
  }

  function completeRide(rideId: string) {
    setRides((current) => current.map((ride) => (ride.id === rideId ? { ...ride, status: "completed" } : ride)))
    setBookings((current) =>
      current.map((booking) =>
        booking.rideId === rideId && booking.status === "confirmed" ? { ...booking, status: "completed" } : booking,
      ),
    )
    setNotice("Ride completed. Riders can now review.")
  }

  function adjustRidePrice(rideId: string, amount: number) {
    setRides((current) =>
      current.map((ride) => (ride.id === rideId ? { ...ride, price: Math.max(12, ride.price + amount) } : ride)),
    )
    setNotice("Listing price updated.")
  }

  function fileReport(summary: string) {
    if (!summary.trim()) return
    setReports((current) => [summary.trim(), ...current])
    setNotice("Report saved in demo mode.")
  }

  if (!isSignedIn) {
    return <AuthView theme={theme} onSignIn={signIn} />
  }

  return (
    <main className="appShell" data-theme={theme}>
      <aside className="sidebar" aria-label="Shotgun navigation">
        <div className="brandMark">
          <div className="brandIcon">
            <Car size={24} />
          </div>
          <div>
            <strong>Shotgun</strong>
            <span>Northeast rides</span>
          </div>
        </div>

        <nav className="navStack">
          {navItems.map((item) => {
            const Icon = item.icon
            return (
              <button
                className={`navButton ${activeTab === item.id ? "active" : ""}`}
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                type="button"
              >
                <Icon size={18} />
                {item.label}
              </button>
            )
          })}
        </nav>

        <div className="trustCard">
          <ShieldCheck size={20} />
          <strong>Verified corridor</strong>
          <span>Phone checks, ride reports, clear pickup notes.</span>
        </div>
      </aside>

      <section className="mainPanel">
        {activeTab === "search" && (
          <SearchView
            searchState={searchState}
            setSearchState={setSearchState}
            results={results}
            selectedRide={selectedRide}
            setSelectedRideId={setSelectedRideId}
            bookingSeats={bookingSeats}
            setBookingSeats={setBookingSeats}
            onBook={setCheckoutRide}
            onOpenSafety={() => setActiveTab("safety")}
            savedRideIds={savedRideIds}
            setSavedRideIds={setSavedRideIds}
          />
        )}
        {activeTab === "trips" && (
          <TripsView bookings={bookings} rides={rides} reviews={reviews} onCancel={cancelBooking} onComplete={completeBooking} onReview={addReview} />
        )}
        {activeTab === "drive" && (
          <DriveView
            bookings={bookings}
            rides={rides}
            driverUserId={driverViewUserId}
            onAccept={acceptBooking}
            onAdjustPrice={adjustRidePrice}
            onCancelRide={cancelRide}
            onCompleteRide={completeRide}
            onCreateRide={createRideListing}
            onDecline={cancelBooking}
            onShowMyDashboard={() => setDriverViewUserId(currentUserId)}
          />
        )}
        {activeTab === "inbox" && <InboxView conversations={conversations} rides={rides} onSendMessage={sendMessage} />}
        {activeTab === "safety" && <SafetyView reports={reports} onReport={fileReport} />}
        {activeTab === "profile" && (
          <ProfileView
            authMode={authMode}
            quietMode={quietMode}
            reviews={reviews}
            setQuietMode={setQuietMode}
            notifications={notifications}
            setNotifications={setNotifications}
            theme={theme}
            setTheme={setTheme}
          />
        )}
        {activeTab === "settings" && (
          <SettingsView
            authMode={authMode}
            notifications={notifications}
            onSignOut={signOut}
            setNotifications={setNotifications}
            setTheme={setTheme}
            theme={theme}
          />
        )}
        {checkoutRide && (
          <CheckoutSheet
            ride={checkoutRide}
            seats={bookingSeats}
            onClose={() => setCheckoutRide(null)}
            onConfirm={() => bookRide(checkoutRide)}
          />
        )}
        {notice && (
          <button className="toast" type="button" onClick={() => setNotice("")}>
            <Check size={16} />
            {notice}
          </button>
        )}
      </section>
    </main>
  )
}

function AuthView({ theme, onSignIn }: { theme: ThemeChoice; onSignIn: (mode: "apple" | "demo") => void }) {
  return (
    <main className="authShell" data-theme={theme}>
      <section className="authHero">
        <div className="brandMark">
          <div className="brandIcon">
            <Car size={24} />
          </div>
          <div>
            <strong>Shotgun</strong>
            <span>Northeast rides</span>
          </div>
        </div>
        <div className="authCopy">
          <p>Shared rides between Northeast cities.</p>
          <h1>Book the empty seat, skip the train scramble.</h1>
        </div>
        <div className="authMap">
          <CorridorMap origin="New York, NY" destination="Newport, RI" />
        </div>
      </section>
      <section className="authPanel">
        <BadgeCheck size={26} />
        <h2>Start with a verified profile</h2>
        <p>Sign in with Apple is the intended production path. Demo mode keeps this MVP fully clickable while auth is wired to Supabase.</p>
        <button className="primaryAction" type="button" onClick={() => onSignIn("apple")}>
          <Apple size={18} />
          Sign in with Apple
        </button>
        <button className="secondaryAction" type="button" onClick={() => onSignIn("demo")}>
          Use demo mode
        </button>
        <div className="authChecklist">
          <span><LockKeyhole size={15} /> Private relay-ready</span>
          <span><Smartphone size={15} /> Phone verification placeholder</span>
          <span><ShieldCheck size={15} /> Trust and safety profile</span>
        </div>
      </section>
    </main>
  )
}

function SearchView({
  searchState,
  setSearchState,
  results,
  selectedRide,
  setSelectedRideId,
  bookingSeats,
  setBookingSeats,
  onBook,
  onOpenSafety,
  savedRideIds,
  setSavedRideIds,
}: {
  searchState: SearchState
  setSearchState: (value: SearchState) => void
  results: Ride[]
  selectedRide: Ride
  setSelectedRideId: (id: string) => void
  bookingSeats: number
  setBookingSeats: (seats: number) => void
  onBook: (ride: Ride) => void
  onOpenSafety: () => void
  savedRideIds: string[]
  setSavedRideIds: (ids: string[]) => void
}) {
  return (
    <div className="searchLayout">
      <section className="searchColumn">
        <div className="pageHeader">
          <p>Shared rides between Northeast cities.</p>
          <h1>Find a better ride down the corridor.</h1>
        </div>

        <div className="searchBox">
          <SelectField label="From" value={searchState.origin} onChange={(origin) => setSearchState({ ...searchState, origin })} />
          <SelectField label="To" value={searchState.destination} onChange={(destination) => setSearchState({ ...searchState, destination })} />
          <label className="field">
            <span>Date</span>
            <button className="selectButton" type="button">
              <CalendarDays size={18} />
              {searchState.date}
            </button>
          </label>
          <label className="field">
            <span>Seats</span>
            <div className="stepper">
              <button type="button" onClick={() => setSearchState({ ...searchState, seats: Math.max(1, searchState.seats - 1) })}>
                -
              </button>
              <strong>{searchState.seats}</strong>
              <button type="button" onClick={() => setSearchState({ ...searchState, seats: Math.min(4, searchState.seats + 1) })}>
                +
              </button>
            </div>
          </label>
        </div>

        <div className="routeChips" aria-label="Popular routes">
          {popularRoutes.map(([origin, destination]) => (
            <button
              key={`${origin}-${destination}`}
              type="button"
              onClick={() => setSearchState({ ...searchState, origin, destination })}
            >
              {shortCity(origin)} to {shortCity(destination)}
            </button>
          ))}
        </div>

        <div className="resultsHeader">
          <h2>Available rides</h2>
          <span>{results.length} match{results.length === 1 ? "" : "es"}</span>
        </div>

        <div className="rideList">
          {results.length === 0 ? (
            <EmptyState icon={Search} title="No rides found" body="Try another popular route or reduce the seat count." />
          ) : (
            results.map((ride) => (
              <RideCard
                key={ride.id}
                ride={ride}
                selected={ride.id === selectedRide.id}
                saved={savedRideIds.includes(ride.id)}
                onSelect={() => setSelectedRideId(ride.id)}
                onSave={() =>
                  setSavedRideIds(
                    savedRideIds.includes(ride.id)
                      ? savedRideIds.filter((id) => id !== ride.id)
                      : [...savedRideIds, ride.id],
                  )
                }
              />
            ))
          )}
        </div>
      </section>

      <RideDetail ride={selectedRide} bookingSeats={bookingSeats} setBookingSeats={setBookingSeats} onBook={onBook} onOpenSafety={onOpenSafety} />
    </div>
  )
}

function RideCard({
  ride,
  selected,
  saved,
  onSelect,
  onSave,
}: {
  ride: Ride
  selected: boolean
  saved: boolean
  onSelect: () => void
  onSave: () => void
}) {
  const driver = userById(ride.driverId)
  const vehicle = vehicleById(ride.vehicleId)

  return (
    <article className={`rideCard ${selected ? "selected" : ""}`}>
      <button className="rideCardMain" type="button" onClick={onSelect}>
        <Avatar userId={driver.id} />
        <div>
          <div className="cardTopline">
            <strong>{driver.name}</strong>
            <Rating rating={driver.rating} count={driver.reviews} />
          </div>
          <h3>{shortCity(ride.origin)} to {shortCity(ride.destination)}</h3>
          <p>{vehicle.color} {vehicle.make} {vehicle.model} · {ride.departureTime}</p>
          <div className="metaLine">
            <span><Users size={15} /> {ride.seatsAvailable} seats</span>
            <span><CreditCard size={15} /> ${ride.price}</span>
            <span>{ride.manualApproval ? "Approval" : "Instant"}</span>
          </div>
        </div>
      </button>
      <button className={`iconButton ${saved ? "saved" : ""}`} type="button" onClick={onSave} aria-label="Save ride">
        <Heart size={18} fill={saved ? "currentColor" : "none"} />
      </button>
    </article>
  )
}

function RideDetail({
  ride,
  bookingSeats,
  setBookingSeats,
  onBook,
  onOpenSafety,
}: {
  ride: Ride
  bookingSeats: number
  setBookingSeats: (seats: number) => void
  onBook: (ride: Ride) => void
  onOpenSafety: () => void
}) {
  const driver = userById(ride.driverId)
  const vehicle = vehicleById(ride.vehicleId)

  return (
    <aside className="detailPanel">
      <CorridorMap origin={ride.origin} destination={ride.destination} />
      <div className="detailHeader">
        <div>
          <p>{ride.departureTime}</p>
          <h2>{shortCity(ride.origin)} to {shortCity(ride.destination)}</h2>
        </div>
        <strong>${ride.price}</strong>
      </div>

      <div className="driverBlock">
        <Avatar userId={driver.id} />
        <div>
          <strong>{driver.name}</strong>
          <Rating rating={driver.rating} count={driver.reviews} />
        </div>
        {driver.verified && <span className="verified"><ShieldCheck size={15} /> Verified</span>}
      </div>

      <div className="timeline">
        <InfoRow icon={MapPin} title="Pickup" body={ride.pickupNotes} />
        <InfoRow icon={Flag} title="Dropoff" body={ride.dropoffNotes} />
        <InfoRow icon={Car} title="Car" body={`${vehicle.year} ${vehicle.color} ${vehicle.make} ${vehicle.model} · ${vehicle.plateState} plates`} />
      </div>

      <div className="preferenceGrid">
        {ride.preferences.map((preference) => (
          <span key={preference}>{preference}</span>
        ))}
        <span>{ride.luggage} luggage</span>
      </div>

      <div className="bookingBox">
        <div>
          <span>Seats</span>
          <div className="stepper">
            <button type="button" onClick={() => setBookingSeats(Math.max(1, bookingSeats - 1))}>-</button>
            <strong>{bookingSeats}</strong>
            <button type="button" onClick={() => setBookingSeats(Math.min(ride.seatsAvailable, bookingSeats + 1))}>+</button>
          </div>
        </div>
        <div>
          <span>Total</span>
          <strong>${ride.price * bookingSeats}</strong>
        </div>
      </div>

      <button className="primaryAction" type="button" onClick={() => onBook(ride)}>
        {ride.manualApproval ? "Request booking" : "Continue to checkout"}
        <ChevronRight size={18} />
      </button>
      <button className="secondaryAction" type="button" onClick={onOpenSafety}>
        <ShieldAlert size={16} />
        Safety and reports
      </button>
    </aside>
  )
}

function CheckoutSheet({
  ride,
  seats,
  onClose,
  onConfirm,
}: {
  ride: Ride
  seats: number
  onClose: () => void
  onConfirm: () => void
}) {
  const driver = userById(ride.driverId)
  const subtotal = ride.price * seats
  const fee = serviceFee(subtotal)
  const total = subtotal + fee

  return (
    <div className="sheetOverlay" role="presentation">
      <section className="checkoutSheet" aria-label="Booking checkout">
        <div className="sheetHeader">
          <div>
            <p>Secure checkout</p>
            <h2>{shortCity(ride.origin)} to {shortCity(ride.destination)}</h2>
          </div>
          <button className="iconButton" type="button" onClick={onClose} aria-label="Close checkout">
            <X size={18} />
          </button>
        </div>
        <div className="checkoutDriver">
          <Avatar userId={driver.id} />
          <div>
            <strong>{driver.name}</strong>
            <span>{ride.manualApproval ? "Driver approval required" : "Instant confirmation"}</span>
          </div>
        </div>
        <div className="priceBreakdown">
          <span>{seats} seat{seats === 1 ? "" : "s"} x ${ride.price}</span>
          <strong>${subtotal}</strong>
          <span>Shotgun service fee</span>
          <strong>${fee}</strong>
          <span>Total today</span>
          <strong>${total}</strong>
        </div>
        <div className="paymentChoice">
          <Wallet size={18} />
          <div>
            <strong>Payment stub</strong>
            <span>Stripe Connect or Apple Pay will capture this server-side later.</span>
          </div>
        </div>
        <button className="primaryAction" type="button" onClick={onConfirm}>
          <Receipt size={18} />
          {ride.manualApproval ? "Authorize payment and request" : "Pay and book"}
        </button>
      </section>
    </div>
  )
}

function TripsView({
  bookings,
  rides,
  reviews,
  onCancel,
  onComplete,
  onReview,
}: {
  bookings: Booking[]
  rides: Ride[]
  reviews: Review[]
  onCancel: (id: string) => void
  onComplete: (id: string) => void
  onReview: (bookingId: string, rating: number, body: string) => void
}) {
  const userBookings = bookings.filter((booking) => booking.riderId === currentUserId)
  return (
    <section className="contentStack">
      <Header eyebrow="My Trips" title="Upcoming and past rides" />
      {userBookings.length === 0 ? (
        <EmptyState icon={Ticket} title="No trips yet" body="Book a seat from Search and it will appear here." />
      ) : (
        <div className="gridCards">
          {userBookings.map((booking) => {
            const ride = rides.find((item) => item.id === booking.rideId)
            if (!ride) return null
            const driver = userById(ride.driverId)
            const reviewed = reviews.some((review) => review.authorId === currentUserId && review.id.includes(booking.id))
            return (
              <article className="tripCard" key={booking.id}>
                <Status status={booking.status} />
                <h2>{shortCity(ride.origin)} to {shortCity(ride.destination)}</h2>
                <p>{ride.departureTime} · {booking.seats} seat{booking.seats === 1 ? "" : "s"}</p>
                <div className="miniRow">
                  <Avatar userId={driver.id} />
                  <span>{driver.name}</span>
                </div>
                <div className="paymentLine">
                  <CreditCard size={16} />
                  <span>{booking.payment.status} · ${booking.payment.amount}</span>
                </div>
                {booking.status === "pending" || booking.status === "confirmed" ? (
                  <div className="actionRow">
                    <button className="secondaryAction" type="button" onClick={() => onCancel(booking.id)}>
                      <X size={16} /> Cancel booking
                    </button>
                    {booking.status === "confirmed" && (
                      <button className="primaryAction compact" type="button" onClick={() => onComplete(booking.id)}>
                        <Check size={16} /> Complete
                      </button>
                    )}
                  </div>
                ) : null}
                {booking.status === "completed" && !reviewed && <ReviewForm bookingId={booking.id} onReview={onReview} />}
                {booking.status === "completed" && reviewed && <span className="verified"><Star size={15} /> Reviewed</span>}
              </article>
            )
          })}
        </div>
      )}
    </section>
  )
}

function ReviewForm({
  bookingId,
  onReview,
}: {
  bookingId: string
  onReview: (bookingId: string, rating: number, body: string) => void
}) {
  const [rating, setRating] = useState(5)
  const [body, setBody] = useState("Great ride, clear pickup, would book again.")

  return (
    <form
      className="reviewForm"
      onSubmit={(event) => {
        event.preventDefault()
        onReview(bookingId, rating, body)
      }}
    >
      <div className="starPicker" aria-label="Review rating">
        {[1, 2, 3, 4, 5].map((value) => (
          <button className={value <= rating ? "active" : ""} key={value} type="button" onClick={() => setRating(value)}>
            <Star size={16} fill="currentColor" />
          </button>
        ))}
      </div>
      <textarea value={body} onChange={(event) => setBody(event.target.value)} />
      <button className="primaryAction compact" type="submit">
        Post review
      </button>
    </form>
  )
}

function DriveView({
  bookings,
  rides,
  driverUserId,
  onAccept,
  onAdjustPrice,
  onCancelRide,
  onCompleteRide,
  onCreateRide,
  onDecline,
  onShowMyDashboard,
}: {
  bookings: Booking[]
  rides: Ride[]
  driverUserId: string
  onAccept: (id: string) => void
  onAdjustPrice: (rideId: string, amount: number) => void
  onCancelRide: (rideId: string) => void
  onCompleteRide: (rideId: string) => void
  onCreateRide: (draft: ListingDraft) => void
  onDecline: (id: string) => void
  onShowMyDashboard: () => void
}) {
  const driver = userById(driverUserId)
  const ownRides = rides.filter((ride) => ride.driverId === driverUserId)
  const driverBookings = bookings.filter((booking) => ownRides.some((ride) => ride.id === booking.rideId))
  const expected = driverBookings.reduce((total, booking) => {
    if (booking.status !== "pending" && booking.status !== "confirmed") return total
    const ride = rides.find((item) => item.id === booking.rideId)
    return total + (ride ? ride.price * booking.seats : 0)
  }, 0)

  return (
    <section className="contentStack">
      <Header eyebrow="Drive" title={`${driver.firstName}'s driver dashboard`} />
      {driverUserId !== currentUserId && (
        <div className="demoNotice">
          <span>Demo handoff: this shows what the driver sees after your booking.</span>
          <button className="secondaryAction" type="button" onClick={onShowMyDashboard}>
            My listings
          </button>
        </div>
      )}
      <div className="metricGrid">
        <Metric icon={CircleDollarSign} label="Expected" value={`$${expected}`} />
        <Metric icon={Clock} label="Requests" value={`${driverBookings.filter((booking) => booking.status === "pending").length}`} />
        <Metric icon={Gauge} label="Seats open" value={`${ownRides.reduce((total, ride) => total + ride.seatsAvailable, 0)}`} />
      </div>
      {driverUserId === currentUserId && <CreateRideForm onCreateRide={onCreateRide} />}
      {ownRides.length === 0 ? (
        <EmptyState icon={Route} title="No driver listings" body="Create a listing to start filling empty seats." />
      ) : (
        <div className="gridCards">
          {ownRides.map((ride) => (
          <article className="tripCard" key={ride.id}>
            <Status status={ride.status} />
            <h2>{shortCity(ride.origin)} to {shortCity(ride.destination)}</h2>
            <p>{ride.departureTime} · {ride.seatsAvailable}/{ride.totalSeats} open · ${ride.price}/seat</p>
            <div className="paymentLine">
              <Car size={16} />
              <span>{vehicleById(ride.vehicleId).color} {vehicleById(ride.vehicleId).make} {vehicleById(ride.vehicleId).model}</span>
            </div>
            {driverUserId === currentUserId && ride.status === "active" && (
              <div className="actionRow">
                <button className="secondaryAction" type="button" onClick={() => onAdjustPrice(ride.id, -2)}>
                  <SlidersHorizontal size={16} /> Edit price
                </button>
                <button className="secondaryAction danger" type="button" onClick={() => onCancelRide(ride.id)}>
                  <Trash2 size={16} /> Cancel ride
                </button>
                <button className="primaryAction compact" type="button" onClick={() => onCompleteRide(ride.id)}>
                  <Check size={16} /> Complete
                </button>
              </div>
            )}
          </article>
          ))}
        </div>
      )}
      <h2 className="sectionTitle">Booking activity</h2>
      {driverBookings.length === 0 ? (
        <EmptyState icon={Users} title="No booking activity yet" body="Accepted riders and pending requests will appear here." />
      ) : (
        <div className="gridCards">
          {driverBookings.map((booking) => {
          const ride = rides.find((item) => item.id === booking.rideId)
          if (!ride) return null
          const rider = userById(booking.riderId)
          return (
            <article className="tripCard" key={booking.id}>
              <Status status={booking.status} />
              <div className="miniRow">
                <Avatar userId={rider.id} />
                <strong>{rider.name}</strong>
              </div>
              <p>{booking.seats} seat on {shortCity(ride.origin)} to {shortCity(ride.destination)}</p>
              <div className="paymentLine">
                <CreditCard size={16} />
                <span>{booking.payment.status} · ${booking.payment.amount}</span>
              </div>
              {booking.status === "pending" && (
                <div className="actionRow">
                  <button className="secondaryAction" type="button" onClick={() => onDecline(booking.id)}>
                    <X size={16} /> Decline
                  </button>
                  <button className="primaryAction compact" type="button" onClick={() => onAccept(booking.id)}>
                    <Check size={16} /> Accept
                  </button>
                </div>
              )}
            </article>
          )
          })}
        </div>
      )}
    </section>
  )
}

const preferenceOptions = ["No smoking", "Pets allowed", "Quiet ride", "Music okay", "Phone charger"]

function CreateRideForm({ onCreateRide }: { onCreateRide: (draft: ListingDraft) => void }) {
  const [draft, setDraft] = useState<ListingDraft>({
    origin: "New York, NY",
    destination: "Providence, RI",
    departureTime: "Friday, 3:30 PM",
    pickupNotes: "Meet near a transit-friendly curb pickup.",
    dropoffNotes: "Central dropoff with a little flexibility.",
    seatsAvailable: 2,
    price: 42,
    luggage: "Carry-on",
    preferences: ["No smoking", "Music okay"],
    manualApproval: true,
  })

  function submitListing(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    onCreateRide(draft)
  }

  function togglePreference(preference: string) {
    setDraft((current) => ({
      ...current,
      preferences: current.preferences.includes(preference)
        ? current.preferences.filter((item) => item !== preference)
        : [...current.preferences, preference],
    }))
  }

  return (
    <form className="listingForm" onSubmit={submitListing}>
      <div>
        <h2 className="sectionTitle">Create a ride listing</h2>
        <p>Post a corridor trip in under a minute.</p>
      </div>
      <div className="formGrid">
        <SelectField label="From" value={draft.origin} onChange={(origin) => setDraft({ ...draft, origin })} />
        <SelectField label="To" value={draft.destination} onChange={(destination) => setDraft({ ...draft, destination })} />
        <label className="field">
          <span>Departure</span>
          <input value={draft.departureTime} onChange={(event) => setDraft({ ...draft, departureTime: event.target.value })} />
        </label>
        <label className="field">
          <span>Price</span>
          <input
            min={12}
            type="number"
            value={draft.price}
            onChange={(event) => setDraft({ ...draft, price: Number(event.target.value) })}
          />
        </label>
        <label className="field">
          <span>Seats</span>
          <div className="stepper">
            <button type="button" onClick={() => setDraft({ ...draft, seatsAvailable: Math.max(1, draft.seatsAvailable - 1) })}>
              -
            </button>
            <strong>{draft.seatsAvailable}</strong>
            <button type="button" onClick={() => setDraft({ ...draft, seatsAvailable: Math.min(6, draft.seatsAvailable + 1) })}>
              +
            </button>
          </div>
        </label>
        <label className="field">
          <span>Luggage</span>
          <select value={draft.luggage} onChange={(event) => setDraft({ ...draft, luggage: event.target.value })}>
            <option>Backpack</option>
            <option>Carry-on</option>
            <option>Large suitcase</option>
          </select>
        </label>
      </div>
      <div className="formGrid notesGrid">
        <label className="textareaField">
          <span>Pickup notes</span>
          <textarea value={draft.pickupNotes} onChange={(event) => setDraft({ ...draft, pickupNotes: event.target.value })} />
        </label>
        <label className="textareaField">
          <span>Dropoff notes</span>
          <textarea value={draft.dropoffNotes} onChange={(event) => setDraft({ ...draft, dropoffNotes: event.target.value })} />
        </label>
      </div>
      <div className="preferenceGrid">
        {preferenceOptions.map((preference) => (
          <button
            className={draft.preferences.includes(preference) ? "selected" : ""}
            key={preference}
            type="button"
            onClick={() => togglePreference(preference)}
          >
            {preference}
          </button>
        ))}
      </div>
      <div className="actionRow">
        <button
          className={`secondaryAction ${draft.manualApproval ? "selected" : ""}`}
          type="button"
          onClick={() => setDraft({ ...draft, manualApproval: !draft.manualApproval })}
        >
          {draft.manualApproval ? "Manual approval on" : "Instant booking"}
        </button>
        <button className="primaryAction compact" type="submit">
          <Car size={16} />
          Publish ride
        </button>
      </div>
    </form>
  )
}

function InboxView({
  conversations,
  rides,
  onSendMessage,
}: {
  conversations: Conversation[]
  rides: Ride[]
  onSendMessage: (conversationId: string, body: string) => void
}) {
  const [selectedId, setSelectedId] = useState(conversations[0]?.id ?? "")
  const [draft, setDraft] = useState("On my way. What is the easiest pickup landmark?")
  const selected = conversations.find((conversation) => conversation.id === selectedId) ?? conversations[0]

  return (
    <section className="inboxLayout">
      <div className="conversationList">
        <Header eyebrow="Inbox" title="Ride messages" />
        {conversations.map((conversation) => {
          const ride = rides.find((item) => item.id === conversation.rideId)
          const otherId = conversation.participantIds.find((id) => id !== currentUserId) ?? currentUserId
          const other = userById(otherId)
          return (
            <button
              className={`conversationButton ${conversation.id === selected?.id ? "active" : ""}`}
              key={conversation.id}
              type="button"
              onClick={() => setSelectedId(conversation.id)}
            >
              <Avatar userId={other.id} />
              <span>
                <strong>{other.name}</strong>
                <small>{ride ? `${shortCity(ride.origin)} to ${shortCity(ride.destination)}` : "Ride"}</small>
              </span>
            </button>
          )
        })}
      </div>
      <div className="messagePane">
        {selected ? (
          <>
            <div className="messageHeader">
              <MessageCircle size={20} />
              <strong>{rideTitle(selected.rideId, rides)}</strong>
            </div>
            <div className="messageStack">
              {selected.messages.map((message) => (
                <div className={`bubble ${message.senderId === currentUserId ? "mine" : ""}`} key={message.id}>
                  <span>{message.body}</span>
                  <small>{message.sentAt}</small>
                </div>
              ))}
            </div>
            <form
              className="composer"
              onSubmit={(event) => {
                event.preventDefault()
                onSendMessage(selected.id, draft)
                setDraft("")
              }}
            >
              <input aria-label="Message" value={draft} onChange={(event) => setDraft(event.target.value)} />
              <button type="submit"><Send size={16} /> Send</button>
            </form>
          </>
        ) : (
          <EmptyState icon={Inbox} title="No messages" body="Book a ride and the conversation will appear here." />
        )}
      </div>
    </section>
  )
}

function ProfileView({
  authMode,
  quietMode,
  reviews,
  setQuietMode,
  notifications,
  setNotifications,
  theme,
  setTheme,
}: {
  authMode: "apple" | "demo"
  quietMode: boolean
  reviews: Review[]
  setQuietMode: (value: boolean) => void
  notifications: boolean
  setNotifications: (value: boolean) => void
  theme: ThemeChoice
  setTheme: (value: ThemeChoice) => void
}) {
  const user = userById(currentUserId)
  const userReviews = reviews.filter((review) => review.subjectId === user.id)
  return (
    <section className="contentStack">
      <Header eyebrow="Profile" title="Your Shotgun account" />
      <div className="profileHero">
        <Avatar userId={user.id} large />
        <div>
          <h2>{user.name}</h2>
          <Rating rating={user.rating} count={user.reviews} />
          <p>{user.bio}</p>
        </div>
      </div>
      <div className="metricGrid">
        <Metric icon={ShieldCheck} label="Identity" value="Verified" />
        <Metric icon={Car} label="Driver" value="Ready" />
        <Metric icon={Star} label="Rating" value={user.rating.toFixed(2)} />
      </div>
      <div className="profileDetails">
        <InfoRow icon={Phone} title="Phone" body={`${user.phone} · verification placeholder active`} />
        <InfoRow icon={IdCard} title="Verification" body={authMode === "apple" ? "Apple sign-in placeholder connected." : "Demo profile using production auth abstraction."} />
        <InfoRow icon={ShieldCheck} title="Trust" body="Verified badge, review history, and report flow are ready to connect to Supabase." />
      </div>
      <div className="settingsGrid">
        <ToggleRow icon={Bell} label="Ride notifications" enabled={notifications} onToggle={() => setNotifications(!notifications)} />
        <ToggleRow icon={Moon} label="Quiet ride default" enabled={quietMode} onToggle={() => setQuietMode(!quietMode)} />
        <ThemeControl theme={theme} setTheme={setTheme} />
      </div>
      <h2 className="sectionTitle">Recent reviews</h2>
      <div className="gridCards">
        {userReviews.map((review) => (
          <article className="tripCard" key={review.id}>
            <Rating rating={review.rating} />
            <p>{review.body}</p>
          </article>
        ))}
      </div>
    </section>
  )
}

function SafetyView({ reports, onReport }: { reports: string[]; onReport: (summary: string) => void }) {
  const [summary, setSummary] = useState("Pickup was unclear and I want the safety team to review.")

  return (
    <section className="contentStack">
      <Header eyebrow="Safety" title="Trust for corridor rides" />
      <div className="safetyGrid">
        <div className="safetyPanel">
          <Siren size={24} />
          <h2>Emergency info</h2>
          <p>Call local emergency services first. Share trip details, pickup notes, and driver profile with a trusted contact before departure.</p>
          <button className="primaryAction compact" type="button">
            <Phone size={16} /> Emergency card
          </button>
        </div>
        <div className="safetyPanel">
          <ShieldCheck size={24} />
          <h2>Verification stack</h2>
          <p>Phone verification, government ID, profile history, vehicle details, and post-ride reviews are modeled for Supabase policies.</p>
        </div>
        <div className="safetyPanel">
          <TriangleAlert size={24} />
          <h2>Safety tips</h2>
          <p>Meet in public pickup zones, confirm the plate and driver name, keep payments in-app, and use reports for anything that feels off.</p>
        </div>
      </div>
      <form
        className="reportForm"
        onSubmit={(event) => {
          event.preventDefault()
          onReport(summary)
          setSummary("")
        }}
      >
        <div>
          <h2 className="sectionTitle">Report a user or ride</h2>
          <p>Demo reports stay local for now, but this is the shape of the moderation flow.</p>
        </div>
        <textarea value={summary} onChange={(event) => setSummary(event.target.value)} />
        <button className="primaryAction compact" type="submit">
          <ShieldAlert size={16} />
          Submit report
        </button>
      </form>
      <div className="gridCards">
        {reports.length === 0 ? (
          <EmptyState icon={LifeBuoy} title="No reports filed" body="Submitted safety reports will appear here in demo mode." />
        ) : (
          reports.map((report, index) => (
            <article className="tripCard" key={`${report}-${index}`}>
              <Status status="received" />
              <p>{report}</p>
            </article>
          ))
        )}
      </div>
    </section>
  )
}

function SettingsView({
  authMode,
  notifications,
  onSignOut,
  setNotifications,
  setTheme,
  theme,
}: {
  authMode: "apple" | "demo"
  notifications: boolean
  onSignOut: () => void
  setNotifications: (value: boolean) => void
  setTheme: (value: ThemeChoice) => void
  theme: ThemeChoice
}) {
  return (
    <section className="contentStack">
      <Header eyebrow="Settings" title="App controls and integrations" />
      <div className="settingsGrid">
        <ThemeControl theme={theme} setTheme={setTheme} />
        <ToggleRow icon={Bell} label="Push notifications" enabled={notifications} onToggle={() => setNotifications(!notifications)} />
        <div className="integrationCard">
          <LockKeyhole size={20} />
          <strong>Authentication</strong>
          <span>{authMode === "apple" ? "Apple sign-in placeholder active." : "Demo mode active."}</span>
        </div>
        <div className="integrationCard">
          <Wallet size={20} />
          <strong>Payments</strong>
          <span>Stripe Connect or Apple Pay can replace the local checkout stub.</span>
        </div>
        <div className="integrationCard">
          <BadgeCheck size={20} />
          <strong>Supabase</strong>
          <span>Client env hook is ready. Auth, RLS, and realtime can be connected next.</span>
        </div>
        <button className="toggleRow danger" type="button" onClick={onSignOut}>
          <X size={18} />
          <span>Sign out</span>
          <strong>Demo</strong>
        </button>
      </div>
    </section>
  )
}

function ThemeControl({ theme, setTheme }: { theme: ThemeChoice; setTheme: (value: ThemeChoice) => void }) {
  return (
    <div className="themeControl">
      <div>
        <Settings size={18} />
        <span>Theme</span>
      </div>
      <div className="themeOptions">
        {(["system", "light", "dark"] as ThemeChoice[]).map((option) => (
          <button
            className={theme === option ? "active" : ""}
            key={option}
            type="button"
            onClick={() => setTheme(option)}
          >
            {option}
          </button>
        ))}
      </div>
    </div>
  )
}

function SelectField({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="field">
      <span>{label}</span>
      <select value={value} onChange={(event) => onChange(event.target.value)}>
        {cities.map((city) => (
          <option key={city} value={city}>
            {city}
          </option>
        ))}
      </select>
    </label>
  )
}

function Header({ eyebrow, title }: { eyebrow: string; title: string }) {
  return (
    <div className="pageHeader small">
      <p>{eyebrow}</p>
      <h1>{title}</h1>
    </div>
  )
}

function Metric({ icon: Icon, label, value }: { icon: ElementType; label: string; value: string }) {
  return (
    <div className="metricCard">
      <Icon size={20} />
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  )
}

function ToggleRow({ icon: Icon, label, enabled, onToggle }: { icon: ElementType; label: string; enabled: boolean; onToggle: () => void }) {
  return (
    <button className="toggleRow" type="button" onClick={onToggle}>
      <Icon size={18} />
      <span>{label}</span>
      <strong>{enabled ? "On" : "Off"}</strong>
    </button>
  )
}

function EmptyState({ icon: Icon, title, body }: { icon: ElementType; title: string; body: string }) {
  return (
    <div className="emptyState">
      <Icon size={34} />
      <strong>{title}</strong>
      <p>{body}</p>
    </div>
  )
}

function InfoRow({ icon: Icon, title, body }: { icon: ElementType; title: string; body: string }) {
  return (
    <div className="infoRow">
      <Icon size={18} />
      <div>
        <strong>{title}</strong>
        <p>{body}</p>
      </div>
    </div>
  )
}

function Avatar({ userId, large = false }: { userId: string; large?: boolean }) {
  const user = userById(userId)
  return <div className={`avatar ${large ? "large" : ""}`}>{user.symbol}</div>
}

function Rating({ rating, count }: { rating: number; count?: number }) {
  return (
    <span className="rating">
      <Star size={14} fill="currentColor" />
      {rating.toFixed(2)}
      {count !== undefined && <small>({count})</small>}
    </span>
  )
}

function Status({ status }: { status: string }) {
  return <span className={`status ${status.replace(" ", "-")}`}>{status}</span>
}

function CorridorMap({ origin, destination }: { origin: string; destination: string }) {
  return (
    <div className="corridorMap" aria-label={`${origin} to ${destination}`}>
      <div className="mapWater" />
      <div className="mapLine">
        <span />
        <span />
        <span />
        <span />
      </div>
      <div className="mapCities">
        <strong>{shortCity(origin)}</strong>
        <strong>{shortCity(destination)}</strong>
      </div>
    </div>
  )
}

function userById(id: string) {
  return users.find((user) => user.id === id) ?? users[0]
}

function vehicleById(id: string) {
  return vehicles.find((vehicle) => vehicle.id === id) ?? vehicles[0]
}

function shortCity(city: string) {
  return city.split(",")[0]
}

function cityMatches(city: string, query: string) {
  return city.toLowerCase().includes(query.toLowerCase().split(",")[0])
}

function rideTitle(rideId: string, rides: Ride[]) {
  const ride = rides.find((item) => item.id === rideId)
  return ride ? `${shortCity(ride.origin)} to ${shortCity(ride.destination)}` : "Ride"
}

function serviceFee(subtotal: number) {
  return Math.max(3, Math.round(subtotal * 0.08))
}
