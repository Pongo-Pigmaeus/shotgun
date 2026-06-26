export type RideStatus = "active" | "sold out" | "canceled" | "completed"
export type BookingStatus = "pending" | "confirmed" | "canceled" | "completed"
export type PaymentStatus = "authorized" | "succeeded" | "refunded" | "voided"

export type AppUser = {
  id: string
  name: string
  firstName: string
  phone: string
  bio: string
  rating: number
  reviews: number
  verified: boolean
  symbol: string
}

export type Vehicle = {
  id: string
  ownerId: string
  make: string
  model: string
  color: string
  year: number
  plateState: string
}

export type Ride = {
  id: string
  driverId: string
  vehicleId: string
  origin: string
  destination: string
  departureTime: string
  pickupNotes: string
  dropoffNotes: string
  seatsAvailable: number
  totalSeats: number
  price: number
  luggage: string
  preferences: string[]
  manualApproval: boolean
  status: RideStatus
}

export type Payment = {
  id: string
  amount: number
  status: PaymentStatus
  note: string
}

export type Booking = {
  id: string
  rideId: string
  riderId: string
  seats: number
  status: BookingStatus
  payment: Payment
  createdAt: string
}

export type Message = {
  id: string
  senderId: string
  body: string
  sentAt: string
}

export type Conversation = {
  id: string
  rideId: string
  bookingId: string
  participantIds: string[]
  messages: Message[]
}

export type Review = {
  id: string
  authorId: string
  subjectId: string
  rating: number
  body: string
}

