import Foundation

struct AppUser: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var name: String
    var phoneNumber: String
    var bio: String
    var rating: Double
    var reviewCount: Int
    var isVerified: Bool
    var phoneVerified: Bool
    var profileSymbolName: String

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
}

enum AuthProvider: String, CaseIterable, Identifiable, Hashable, Codable {
    case apple = "Sign in with Apple"
    case demo = "Demo"

    var id: String { rawValue }
}

struct AuthSession: Identifiable, Hashable, Codable {
    let id: UUID
    var userID: UUID
    var provider: AuthProvider
    var accessToken: String?
    var refreshToken: String?
    var expiresAt: Date?
    var createdAt: Date
}

enum SyncState: String, CaseIterable, Identifiable, Hashable, Codable {
    case localOnly = "Local only"
    case syncing = "Syncing"
    case synced = "Synced"
    case failed = "Needs attention"

    var id: String { rawValue }
}

enum MarketplaceError: Error, LocalizedError, Hashable {
    case signedOut
    case rideUnavailable
    case seatLimit
    case paymentFailed
    case invalidAction

    var errorDescription: String? {
        switch self {
        case .signedOut:
            "Sign in to continue."
        case .rideUnavailable:
            "That ride is no longer available."
        case .seatLimit:
            "There are not enough open seats for this request."
        case .paymentFailed:
            "Payment could not be prepared."
        case .invalidAction:
            "That action is not available right now."
        }
    }
}

struct Vehicle: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var ownerID: UUID
    var make: String
    var model: String
    var color: String
    var year: Int
    var plateState: String

    var displayName: String {
        "\(color) \(make) \(model)"
    }
}

enum RidePreference: String, CaseIterable, Identifiable, Hashable, Codable {
    case noSmoking = "No smoking"
    case petsAllowed = "Pets okay"
    case quietRide = "Quiet ride"
    case musicOkay = "Music okay"
    case womenFriendly = "Women-friendly"
    case chargerAvailable = "Phone charger"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .noSmoking: "nosign"
        case .petsAllowed: "pawprint"
        case .quietRide: "moon"
        case .musicOkay: "music.note"
        case .womenFriendly: "checkmark.shield"
        case .chargerAvailable: "bolt"
        }
    }
}

enum LuggageAllowance: String, CaseIterable, Identifiable, Hashable, Codable {
    case backpack = "Backpack"
    case carryOn = "Carry-on"
    case checkedBag = "Checked bag"

    var id: String { rawValue }
}

enum RideStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case active
    case soldOut = "sold out"
    case canceled
    case completed

    var id: String { rawValue }
}

enum BookingStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case pending
    case confirmed
    case canceled
    case completed

    var id: String { rawValue }
}

enum PaymentStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case pending
    case authorized
    case succeeded
    case failed
    case refunded
    case voided

    var id: String { rawValue }
}

enum PaymentProvider: String, CaseIterable, Identifiable, Hashable, Codable {
    case stub = "Demo payment"
    case applePay = "Apple Pay"
    case stripe = "Stripe"

    var id: String { rawValue }
}

struct Ride: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var driverID: UUID
    var vehicleID: UUID
    var origin: String
    var destination: String
    var departureDate: Date
    var pickupNotes: String
    var dropoffNotes: String
    var seatsAvailable: Int
    var totalSeats: Int
    var pricePerSeatCents: Int
    var luggageAllowance: LuggageAllowance
    var preferences: Set<RidePreference>
    var manualApprovalEnabled: Bool
    var status: RideStatus
    var syncState: SyncState = .synced
    var createdAt: Date = .now
    var updatedAt: Date = .now

    var routeTitle: String {
        "\(origin.shortCity) to \(destination.shortCity)"
    }
}

struct Booking: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var rideID: UUID
    var riderID: UUID
    var seats: Int
    var status: BookingStatus
    var paymentID: UUID
    var createdAt: Date
    var updatedAt: Date = .now
    var approvedAt: Date? = nil
    var canceledAt: Date? = nil
    var completedAt: Date? = nil
    var syncState: SyncState = .synced
}

enum PaymentIntentStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case requiresPaymentMethod = "Needs payment method"
    case requiresConfirmation = "Ready to confirm"
    case authorized = "Authorized"
    case captured = "Captured"
    case canceled = "Canceled"
    case failed = "Failed"

    var id: String { rawValue }
}

enum RefundStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case notNeeded = "Not needed"
    case pending = "Refund pending"
    case succeeded = "Refunded"
    case failed = "Refund failed"

    var id: String { rawValue }
}

enum PayoutStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case notStarted = "Not started"
    case pending = "Pending"
    case available = "Available"
    case paid = "Paid"
    case canceled = "Canceled"

    var id: String { rawValue }
}

struct CheckoutSession: Identifiable, Hashable, Codable {
    let id: UUID
    var rideID: UUID
    var riderID: UUID
    var seats: Int
    var amountCents: Int
    var provider: PaymentProvider
    var clientSecret: String?
    var paymentIntentID: String?
    var status: PaymentIntentStatus
    var createdAt: Date
    var expiresAt: Date
}

struct Payment: Identifiable, Hashable, Codable {
    let id: UUID
    var checkoutSessionID: UUID? = nil
    var bookingID: UUID?
    var amountCents: Int
    var provider: PaymentProvider
    var status: PaymentStatus
    var intentStatus: PaymentIntentStatus = .captured
    var refundStatus: RefundStatus? = nil
    var payoutStatus: PayoutStatus = .notStarted
    var providerPaymentIntentID: String? = nil
    var platformFeeCents: Int = 0
    var driverPayoutCents: Int = 0
    var createdAt: Date
    var authorizedAt: Date? = nil
    var capturedAt: Date? = nil
    var refundedAt: Date? = nil
    var voidedAt: Date? = nil
    var note: String
}

struct DriverPayout: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var bookingID: UUID
    var driverID: UUID
    var amountCents: Int
    var status: PayoutStatus
    var availableOn: Date
    var createdAt: Date
    var paidOutAt: Date? = nil
}

enum NotificationPermissionStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case notDetermined = "Not asked"
    case denied = "Off"
    case authorized = "Allowed"
    case provisional = "Quietly allowed"
    case ephemeral = "Temporary"

    var id: String { rawValue }

    var allowsScheduling: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        }
    }
}

enum RideNotificationKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case bookingConfirmed = "Booking confirmed"
    case bookingRequested = "Booking requested"
    case bookingCanceled = "Booking canceled"
    case bookingDeclined = "Booking declined"
    case driverRequest = "New rider request"
    case rideReminder = "Ride reminder"
    case reviewPrompt = "Review prompt"

    var id: String { rawValue }
}

struct ScheduledRideNotification: Identifiable, Hashable, Codable {
    let id: UUID
    var kind: RideNotificationKind
    var rideID: UUID?
    var bookingID: UUID?
    var title: String
    var body: String
    var scheduledAt: Date
    var deliveryDate: Date

    var identifier: String {
        "shotgun.notification.\(id.uuidString)"
    }
}

struct Message: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var conversationID: UUID
    var senderID: UUID
    var body: String
    var sentAt: Date
    var syncState: SyncState = .synced
}

struct Conversation: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var rideID: UUID
    var bookingID: UUID?
    var participantIDs: [UUID]
    var lastUpdated: Date
    var syncState: SyncState = .synced
}

struct Review: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var rideID: UUID
    var authorID: UUID
    var subjectID: UUID
    var rating: Int
    var body: String
    var createdAt: Date
    var syncState: SyncState = .synced
}

enum ReportReason: String, CaseIterable, Identifiable, Hashable, Codable {
    case unsafeBehavior = "Unsafe behavior"
    case wrongVehicle = "Wrong vehicle"
    case harassment = "Harassment"
    case paymentIssue = "Payment issue"
    case noShow = "No-show"
    case other = "Other"

    var id: String { rawValue }
}

struct TrustReport: Identifiable, Hashable, Codable {
    let id: UUID
    var backendID: String? = nil
    var reporterID: UUID
    var subjectID: UUID?
    var rideID: UUID?
    var reason: ReportReason
    var details: String
    var createdAt: Date
    var isEmergency: Bool
    var syncState: SyncState = .synced
}

enum PaymentMethodKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case applePay = "Apple Pay"
    case card = "Card"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .applePay: "apple.logo"
        case .card: "creditcard.fill"
        }
    }
}

struct PaymentMethod: Identifiable, Hashable, Codable {
    let id: UUID
    var kind: PaymentMethodKind
    var label: String
    var detail: String
    var isDefault: Bool
}

struct PayoutAccount: Identifiable, Hashable, Codable {
    let id: UUID
    var bankName: String
    var lastFour: String
    var isVerified: Bool
    var instantPayoutsEnabled: Bool
}

struct EmergencyContact: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var relationship: String
}

enum SupportIssueType: String, CaseIterable, Identifiable, Hashable, Codable {
    case booking = "Booking"
    case safety = "Safety"
    case payments = "Payments"
    case account = "Account"

    var id: String { rawValue }
}

struct SupportTicket: Identifiable, Hashable, Codable {
    let id: UUID
    var type: SupportIssueType
    var title: String
    var details: String
    var createdAt: Date
}

enum RideSort: String, CaseIterable, Identifiable, Hashable, Codable {
    case earliest = "Earliest"
    case lowestPrice = "Lowest price"
    case highestRated = "Top rated"

    var id: String { rawValue }
}

struct SearchCriteria: Hashable, Codable {
    var origin: String = "New York, NY"
    var destination: String = "Newport, RI"
    var date: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    var seats: Int = 1
}

struct PopularRoute: Identifiable, Hashable, Codable {
    let id: UUID
    var origin: String
    var destination: String

    init(id: UUID = UUID(), origin: String, destination: String) {
        self.id = id
        self.origin = origin
        self.destination = destination
    }

    var title: String {
        "\(origin.shortCity) to \(destination.shortCity)"
    }
}

extension String {
    var shortCity: String {
        components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? self
    }

    var searchKey: String {
        lowercased()
            .replacingOccurrences(of: "nyc", with: "new york")
            .replacingOccurrences(of: "washington dc", with: "washington")
            .replacingOccurrences(of: "washington, dc", with: "washington")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Int {
    var dollarsText: String {
        let dollars = Double(self) / 100
        return dollars.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
