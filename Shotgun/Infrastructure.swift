import Foundation
import UserNotifications

enum BackendTarget: String, CaseIterable, Identifiable, Codable {
    case localMock = "Local Mock"
    case staging = "Staging"
    case production = "Production"

    var id: String { rawValue }

    var baseURL: URL? {
        switch self {
        case .localMock:
            nil
        case .staging:
            URL(string: "https://api-staging.shotgunrides.example")
        case .production:
            URL(string: "https://api.shotgunrides.example")
        }
    }
}

struct AppConfiguration: Codable {
    var backendTarget: BackendTarget
    var apiVersion: String
    var usesLocalData: Bool
    var backendProvider: String
    var paymentProvider: String

    static let localMock = AppConfiguration(
        backendTarget: .localMock,
        apiVersion: "v1",
        usesLocalData: true,
        backendProvider: "Supabase-ready local mock",
        paymentProvider: "Stripe Connect-ready local mock"
    )
}

protocol NotificationScheduling {
    func currentPermissionStatus() async -> NotificationPermissionStatus
    func requestPermission() async -> NotificationPermissionStatus
    func schedule(_ notification: ScheduledRideNotification) async throws
    func cancel(identifier: String)
    func cancel(identifiers: [String])
}

struct LocalNotificationScheduler: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func currentPermissionStatus() async -> NotificationPermissionStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus.notificationPermissionStatus)
            }
        }
    }

    func requestPermission() async -> NotificationPermissionStatus {
        _ = await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        return await currentPermissionStatus()
    }

    func schedule(_ notification: ScheduledRideNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.userInfo = [
            "notificationID": notification.id.uuidString,
            "kind": notification.kind.rawValue,
            "rideID": notification.rideID?.uuidString ?? "",
            "bookingID": notification.bookingID?.uuidString ?? ""
        ]

        let trigger: UNNotificationTrigger
        if notification.deliveryDate.timeIntervalSinceNow <= 60 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(3, notification.deliveryDate.timeIntervalSinceNow), repeats: false)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notification.deliveryDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancel(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

private extension UNAuthorizationStatus {
    var notificationPermissionStatus: NotificationPermissionStatus {
        switch self {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized:
            .authorized
        case .provisional:
            .provisional
        case .ephemeral:
            .ephemeral
        @unknown default:
            .notDetermined
        }
    }
}

struct AppBootstrapState {
    var demoUser: AppUser
    var authSession: AuthSession?
    var currentUser: AppUser?
    var users: [AppUser]
    var vehicles: [Vehicle]
    var rides: [Ride]
    var bookings: [Booking]
    var payments: [Payment]
    var checkoutSessions: [CheckoutSession]
    var driverPayouts: [DriverPayout]
    var conversations: [Conversation]
    var messages: [Message]
    var reviews: [Review]
    var reports: [TrustReport]
    var savedRideIDs: Set<UUID>
    var savedRoutes: [PopularRoute]
    var paymentMethods: [PaymentMethod]
    var payoutAccount: PayoutAccount
    var notificationsEnabled: Bool
    var pickupReminderNotificationsEnabled: Bool
    var scheduledNotifications: [ScheduledRideNotification]
    var emergencyContacts: [EmergencyContact]
    var supportTickets: [SupportTicket]
    var searchCriteria: SearchCriteria
    var lastSyncedAt: Date?
}

struct AppSnapshot: Codable {
    var schemaVersion: Int
    var authSession: AuthSession?
    var currentUser: AppUser?
    var users: [AppUser]
    var vehicles: [Vehicle]
    var rides: [Ride]
    var bookings: [Booking]
    var payments: [Payment]
    var checkoutSessions: [CheckoutSession]
    var driverPayouts: [DriverPayout]
    var conversations: [Conversation]
    var messages: [Message]
    var reviews: [Review]
    var reports: [TrustReport]
    var savedRideIDs: Set<UUID>
    var savedRoutes: [PopularRoute]
    var paymentMethods: [PaymentMethod]
    var payoutAccount: PayoutAccount
    var notificationsEnabled: Bool
    var pickupReminderNotificationsEnabled: Bool
    var scheduledNotifications: [ScheduledRideNotification]
    var emergencyContacts: [EmergencyContact]
    var supportTickets: [SupportTicket]
    var searchCriteria: SearchCriteria
    var lastSyncedAt: Date?

    static let currentSchemaVersion = 3

    init(state: AppBootstrapState) {
        schemaVersion = Self.currentSchemaVersion
        authSession = state.authSession
        currentUser = state.currentUser
        users = state.users
        vehicles = state.vehicles
        rides = state.rides
        bookings = state.bookings
        payments = state.payments
        checkoutSessions = state.checkoutSessions
        driverPayouts = state.driverPayouts
        conversations = state.conversations
        messages = state.messages
        reviews = state.reviews
        reports = state.reports
        savedRideIDs = state.savedRideIDs
        savedRoutes = state.savedRoutes
        paymentMethods = state.paymentMethods
        payoutAccount = state.payoutAccount
        notificationsEnabled = state.notificationsEnabled
        pickupReminderNotificationsEnabled = state.pickupReminderNotificationsEnabled
        scheduledNotifications = state.scheduledNotifications
        emergencyContacts = state.emergencyContacts
        supportTickets = state.supportTickets
        searchCriteria = state.searchCriteria
        lastSyncedAt = state.lastSyncedAt
    }

    func bootstrapState(demoUser: AppUser) -> AppBootstrapState {
        AppBootstrapState(
            demoUser: demoUser,
            authSession: authSession,
            currentUser: currentUser,
            users: users,
            vehicles: vehicles,
            rides: rides,
            bookings: bookings,
            payments: payments,
            checkoutSessions: checkoutSessions,
            driverPayouts: driverPayouts,
            conversations: conversations,
            messages: messages,
            reviews: reviews,
            reports: reports,
            savedRideIDs: savedRideIDs,
            savedRoutes: savedRoutes,
            paymentMethods: paymentMethods,
            payoutAccount: payoutAccount,
            notificationsEnabled: notificationsEnabled,
            pickupReminderNotificationsEnabled: pickupReminderNotificationsEnabled,
            scheduledNotifications: scheduledNotifications,
            emergencyContacts: emergencyContacts,
            supportTickets: supportTickets,
            searchCriteria: searchCriteria,
            lastSyncedAt: lastSyncedAt
        )
    }
}

protocol AppPersisting {
    func loadSnapshot() throws -> AppSnapshot?
    func saveSnapshot(_ snapshot: AppSnapshot) throws
    func clearSnapshot() throws
}

struct JSONFileAppPersistence: AppPersisting {
    private let fileURL: URL
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Shotgun", directoryHint: .isDirectory)
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "Shotgun", directoryHint: .isDirectory)
        fileURL = directory.appending(path: "local-state.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() throws -> AppSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let snapshot = try decoder.decode(AppSnapshot.self, from: data)
        guard snapshot.schemaVersion == AppSnapshot.currentSchemaVersion else { return nil }
        return snapshot
    }

    func saveSnapshot(_ snapshot: AppSnapshot) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    func clearSnapshot() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}

protocol AppBootstrapping {
    var configuration: AppConfiguration { get }
    func makeInitialState() -> AppBootstrapState
}

struct LocalMockBootstrap: AppBootstrapping {
    let configuration = AppConfiguration.localMock
    var persistence: AppPersisting = JSONFileAppPersistence()

    func makeInitialState() -> AppBootstrapState {
        let seed = SeedData.make()
        if let snapshot = try? persistence.loadSnapshot() {
            return snapshot.bootstrapState(demoUser: seed.currentUser)
        }

        return AppBootstrapState(
            demoUser: seed.currentUser,
            authSession: nil,
            currentUser: nil,
            users: seed.users,
            vehicles: seed.vehicles,
            rides: seed.rides,
            bookings: seed.bookings,
            payments: seed.payments,
            checkoutSessions: seed.checkoutSessions,
            driverPayouts: seed.driverPayouts,
            conversations: seed.conversations,
            messages: seed.messages,
            reviews: seed.reviews,
            reports: seed.reports,
            savedRideIDs: Set(seed.rides.prefix(1).map(\.id)),
            savedRoutes: [PopularRoute(origin: "New York, NY", destination: "Newport, RI")],
            paymentMethods: [
                PaymentMethod(id: UUID(), kind: .applePay, label: "Apple Pay", detail: "Ready for checkout", isDefault: true),
                PaymentMethod(id: UUID(), kind: .card, label: "Visa", detail: "Ending in 4242", isDefault: false)
            ],
            payoutAccount: PayoutAccount(id: UUID(), bankName: "Chase", lastFour: "4821", isVerified: true, instantPayoutsEnabled: false),
            notificationsEnabled: true,
            pickupReminderNotificationsEnabled: true,
            scheduledNotifications: [],
            emergencyContacts: [
                EmergencyContact(id: UUID(), name: "Taylor Morgan", phoneNumber: "(917) 555-0199", relationship: "Sibling")
            ],
            supportTickets: [],
            searchCriteria: SearchCriteria(),
            lastSyncedAt: nil
        )
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIRequest<Response: Decodable> {
    var method: HTTPMethod
    var path: String
    var queryItems: [URLQueryItem] = []
    var body: Encodable? = nil
}

enum APIClientError: Error, LocalizedError {
    case localMockHasNoBaseURL
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .localMockHasNoBaseURL:
            "Local mock mode does not have a remote base URL."
        case .invalidResponse:
            "The server returned an invalid response."
        case .httpStatus(let status):
            "The server returned status \(status)."
        }
    }
}

protocol APIClient {
    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response
}

struct URLSessionAPIClient: APIClient {
    var configuration: AppConfiguration
    var urlSession: URLSession = .shared
    var jsonEncoder = JSONEncoder()
    var jsonDecoder = JSONDecoder()

    init(configuration: AppConfiguration) {
        self.configuration = configuration
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonDecoder.dateDecodingStrategy = .iso8601
    }

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        guard let baseURL = configuration.backendTarget.baseURL else {
            throw APIClientError.localMockHasNoBaseURL
        }

        var components = URLComponents(url: baseURL.appending(path: "/\(configuration.apiVersion)\(request.path)"), resolvingAgainstBaseURL: false)
        components?.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        guard let url = components?.url else {
            throw APIClientError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = request.body {
            urlRequest.httpBody = try jsonEncoder.encode(AnyEncodable(body))
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode)
        }

        return try jsonDecoder.decode(Response.self, from: data)
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

protocol MarketplaceServicing {
    func searchRides(criteria: SearchCriteria) async throws -> [Ride]
    func createBooking(rideID: UUID, riderID: UUID, seats: Int) async throws -> Booking
    func cancelBooking(_ bookingID: UUID) async throws
    func approveBooking(_ bookingID: UUID) async throws -> Booking
    func declineBooking(_ bookingID: UUID) async throws -> Booking
    func sendMessage(conversationID: UUID, senderID: UUID, body: String) async throws -> Message
}

struct RemoteMarketplaceService: MarketplaceServicing {
    var apiClient: APIClient

    func searchRides(criteria: SearchCriteria) async throws -> [Ride] {
        let request = APIRequest<[RideDTO]>(
            method: .get,
            path: "/rides",
            queryItems: [
                URLQueryItem(name: "origin", value: criteria.origin),
                URLQueryItem(name: "destination", value: criteria.destination),
                URLQueryItem(name: "seats", value: "\(criteria.seats)")
            ]
        )

        return try await apiClient.send(request).map(\.domainModel)
    }

    func createBooking(rideID: UUID, riderID: UUID, seats: Int) async throws -> Booking {
        let request = APIRequest<BookingDTO>(
            method: .post,
            path: "/bookings",
            body: CreateBookingRequestDTO(rideID: rideID, riderID: riderID, seats: seats)
        )

        return try await apiClient.send(request).domainModel
    }

    func cancelBooking(_ bookingID: UUID) async throws {
        let request = APIRequest<EmptyResponseDTO>(
            method: .post,
            path: "/bookings/\(bookingID.uuidString)/cancel"
        )
        _ = try await apiClient.send(request)
    }

    func approveBooking(_ bookingID: UUID) async throws -> Booking {
        let request = APIRequest<BookingDTO>(
            method: .post,
            path: "/bookings/\(bookingID.uuidString)/approve",
            body: ApproveBookingRequestDTO(bookingID: bookingID)
        )
        return try await apiClient.send(request).domainModel
    }

    func declineBooking(_ bookingID: UUID) async throws -> Booking {
        let request = APIRequest<BookingDTO>(
            method: .post,
            path: "/bookings/\(bookingID.uuidString)/decline",
            body: DeclineBookingRequestDTO(bookingID: bookingID)
        )
        return try await apiClient.send(request).domainModel
    }

    func sendMessage(conversationID: UUID, senderID: UUID, body: String) async throws -> Message {
        let request = APIRequest<MessageDTO>(
            method: .post,
            path: "/conversations/\(conversationID.uuidString)/messages",
            body: SendMessageRequestDTO(senderID: senderID, body: body)
        )

        return try await apiClient.send(request).domainModel
    }
}

struct EmptyResponseDTO: Decodable {}

struct SearchRidesRequestDTO: Encodable {
    var origin: String
    var destination: String
    var date: Date
    var seats: Int
}

struct CreateBookingRequestDTO: Encodable {
    var rideID: UUID
    var riderID: UUID
    var seats: Int
}

struct CancelBookingRequestDTO: Encodable {
    var bookingID: UUID
    var reason: String?
}

struct ApproveBookingRequestDTO: Encodable {
    var bookingID: UUID
}

struct DeclineBookingRequestDTO: Encodable {
    var bookingID: UUID
}

struct CreateCheckoutSessionRequestDTO: Encodable {
    var rideID: UUID
    var riderID: UUID
    var seats: Int
    var amountCents: Int
}

struct CapturePaymentRequestDTO: Encodable {
    var paymentID: UUID
    var bookingID: UUID
}

struct RefundPaymentRequestDTO: Encodable {
    var paymentID: UUID
    var bookingID: UUID
    var reason: String?
}

struct SendMessageRequestDTO: Encodable {
    var senderID: UUID
    var body: String
}

struct RideDTO: Codable, Identifiable {
    var id: UUID
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
    var preferences: [RidePreference]
    var manualApprovalEnabled: Bool
    var status: RideStatus

    init(_ ride: Ride) {
        id = ride.id
        driverID = ride.driverID
        vehicleID = ride.vehicleID
        origin = ride.origin
        destination = ride.destination
        departureDate = ride.departureDate
        pickupNotes = ride.pickupNotes
        dropoffNotes = ride.dropoffNotes
        seatsAvailable = ride.seatsAvailable
        totalSeats = ride.totalSeats
        pricePerSeatCents = ride.pricePerSeatCents
        luggageAllowance = ride.luggageAllowance
        preferences = Array(ride.preferences)
        manualApprovalEnabled = ride.manualApprovalEnabled
        status = ride.status
    }

    var domainModel: Ride {
        Ride(
            id: id,
            driverID: driverID,
            vehicleID: vehicleID,
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            pickupNotes: pickupNotes,
            dropoffNotes: dropoffNotes,
            seatsAvailable: seatsAvailable,
            totalSeats: totalSeats,
            pricePerSeatCents: pricePerSeatCents,
            luggageAllowance: luggageAllowance,
            preferences: Set(preferences),
            manualApprovalEnabled: manualApprovalEnabled,
            status: status
        )
    }
}

struct BookingDTO: Codable, Identifiable {
    var id: UUID
    var rideID: UUID
    var riderID: UUID
    var seats: Int
    var status: BookingStatus
    var paymentID: UUID
    var createdAt: Date

    init(_ booking: Booking) {
        id = booking.id
        rideID = booking.rideID
        riderID = booking.riderID
        seats = booking.seats
        status = booking.status
        paymentID = booking.paymentID
        createdAt = booking.createdAt
    }

    var domainModel: Booking {
        Booking(
            id: id,
            rideID: rideID,
            riderID: riderID,
            seats: seats,
            status: status,
            paymentID: paymentID,
            createdAt: createdAt
        )
    }
}

struct MessageDTO: Codable, Identifiable {
    var id: UUID
    var conversationID: UUID
    var senderID: UUID
    var body: String
    var sentAt: Date

    init(_ message: Message) {
        id = message.id
        conversationID = message.conversationID
        senderID = message.senderID
        body = message.body
        sentAt = message.sentAt
    }

    var domainModel: Message {
        Message(id: id, conversationID: conversationID, senderID: senderID, body: body, sentAt: sentAt)
    }
}
