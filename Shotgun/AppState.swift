import Foundation
import SwiftUI

protocol AuthServicing {
    func signInWithApplePlaceholder() -> AuthSession
    func signInDemo() -> AuthSession
}

struct AppleAuthService: AuthServicing {
    private let demoUser: AppUser

    init(demoUser: AppUser) {
        self.demoUser = demoUser
    }

    func signInWithApplePlaceholder() -> AuthSession {
        makeSession(provider: .apple)
    }

    func signInDemo() -> AuthSession {
        makeSession(provider: .demo)
    }

    private func makeSession(provider: AuthProvider) -> AuthSession {
        AuthSession(
            id: UUID(),
            userID: demoUser.id,
            provider: provider,
            accessToken: "local-\(provider.id.lowercased().replacingOccurrences(of: " ", with: "-"))",
            refreshToken: nil,
            expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: .now),
            createdAt: .now
        )
    }
}

protocol PaymentOrchestrating {
    func createCheckoutSession(rideID: UUID, riderID: UUID, seats: Int, amountCents: Int) throws -> CheckoutSession
    func authorize(session: CheckoutSession) throws -> Payment
    func capture(_ payment: Payment) throws -> Payment
    func refund(_ payment: Payment) throws -> Payment
    func voidAuthorization(_ payment: Payment) throws -> Payment
}

struct LocalPaymentOrchestrator: PaymentOrchestrating {
    func createCheckoutSession(rideID: UUID, riderID: UUID, seats: Int, amountCents: Int) throws -> CheckoutSession {
        CheckoutSession(
            id: UUID(),
            rideID: rideID,
            riderID: riderID,
            seats: seats,
            amountCents: amountCents,
            provider: .stripe,
            clientSecret: "cs_test_local_\(UUID().uuidString)",
            paymentIntentID: "pi_local_\(UUID().uuidString)",
            status: .authorized,
            createdAt: .now,
            expiresAt: Calendar.current.date(byAdding: .minute, value: 20, to: .now) ?? .now
        )
    }

    func authorize(session: CheckoutSession) throws -> Payment {
        Payment(
            id: UUID(),
            checkoutSessionID: session.id,
            bookingID: nil,
            amountCents: session.amountCents,
            provider: session.provider,
            status: .authorized,
            intentStatus: .authorized,
            refundStatus: .notNeeded,
            payoutStatus: .notStarted,
            providerPaymentIntentID: session.paymentIntentID,
            platformFeeCents: platformFee(for: session.amountCents),
            driverPayoutCents: session.amountCents - platformFee(for: session.amountCents),
            createdAt: .now,
            authorizedAt: .now,
            note: "Demo authorization held for Stripe Connect checkout."
        )
    }

    func capture(_ payment: Payment) throws -> Payment {
        var captured = payment
        captured.status = .succeeded
        captured.intentStatus = .captured
        captured.payoutStatus = .pending
        captured.capturedAt = .now
        captured.note = "Demo capture recorded. Stripe Connect would collect the rider charge and schedule driver payout."
        return captured
    }

    func refund(_ payment: Payment) throws -> Payment {
        var refunded = payment
        refunded.status = .refunded
        refunded.intentStatus = .canceled
        refunded.refundStatus = .succeeded
        refunded.payoutStatus = .canceled
        refunded.refundedAt = .now
        refunded.note = "Demo refund recorded."
        return refunded
    }

    func voidAuthorization(_ payment: Payment) throws -> Payment {
        var voided = payment
        voided.status = .voided
        voided.intentStatus = .canceled
        voided.refundStatus = .notNeeded
        voided.payoutStatus = .canceled
        voided.voidedAt = .now
        voided.note = "Demo authorization voided before capture."
        return voided
    }

    private func platformFee(for amountCents: Int) -> Int {
        max(100, Int((Double(amountCents) * 0.12).rounded()))
    }
}

struct RemotePaymentOrchestrator: PaymentOrchestrating {
    var apiClient: APIClient

    func createRemoteCheckoutSession(rideID: UUID, riderID: UUID, seats: Int, amountCents: Int) async throws -> CheckoutSession {
        let request = APIRequest<CheckoutSession>(
            method: .post,
            path: "/payments/checkout-sessions",
            body: CreateCheckoutSessionRequestDTO(rideID: rideID, riderID: riderID, seats: seats, amountCents: amountCents)
        )
        return try await apiClient.send(request)
    }

    func createCheckoutSession(rideID: UUID, riderID: UUID, seats: Int, amountCents: Int) throws -> CheckoutSession {
        throw MarketplaceError.paymentFailed
    }

    func authorize(session: CheckoutSession) throws -> Payment {
        throw MarketplaceError.paymentFailed
    }

    func capture(_ payment: Payment) throws -> Payment {
        throw MarketplaceError.paymentFailed
    }

    func refund(_ payment: Payment) throws -> Payment {
        throw MarketplaceError.paymentFailed
    }

    func voidAuthorization(_ payment: Payment) throws -> Payment {
        throw MarketplaceError.paymentFailed
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var authSession: AuthSession?
    @Published var currentUser: AppUser?
    @Published var users: [AppUser]
    @Published var vehicles: [Vehicle]
    @Published var rides: [Ride]
    @Published var bookings: [Booking]
    @Published var payments: [Payment]
    @Published var checkoutSessions: [CheckoutSession]
    @Published var driverPayouts: [DriverPayout]
    @Published var conversations: [Conversation]
    @Published var messages: [Message]
    @Published var reviews: [Review]
    @Published var reports: [TrustReport]
    @Published var savedRideIDs: Set<UUID> = []
    @Published var savedRoutes: [PopularRoute] = []
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var payoutAccount = PayoutAccount(id: UUID(), bankName: "Chase", lastFour: "4821", isVerified: true, instantPayoutsEnabled: false)
    @Published var notificationsEnabled = true
    @Published var pickupReminderNotificationsEnabled = true
    @Published var notificationPermission: NotificationPermissionStatus = .notDetermined
    @Published var scheduledNotifications: [ScheduledRideNotification] = []
    @Published var notificationErrorMessage: String?
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var supportTickets: [SupportTicket] = []
    @Published var searchCriteria = SearchCriteria()
    @Published var selectedTab = AppTab.search
    @Published var syncState: SyncState = .synced
    @Published var lastSyncedAt: Date?
    @Published var activeOperationKeys: Set<String> = []
    @Published var lastMarketplaceError: String?

    let configuration: AppConfiguration

    let cities = [
        "New York, NY",
        "Boston, MA",
        "Providence, RI",
        "Newport, RI",
        "New Haven, CT",
        "Stamford, CT",
        "Hoboken, NJ",
        "Philadelphia, PA",
        "Baltimore, MD",
        "Washington, DC"
    ]

    let popularRoutes = [
        PopularRoute(origin: "New York, NY", destination: "Newport, RI"),
        PopularRoute(origin: "New York, NY", destination: "Providence, RI"),
        PopularRoute(origin: "Boston, MA", destination: "New York, NY"),
        PopularRoute(origin: "Philadelphia, PA", destination: "Washington, DC"),
        PopularRoute(origin: "Washington, DC", destination: "New York, NY"),
        PopularRoute(origin: "New Haven, CT", destination: "New York, NY")
    ]

    private let authService: AuthServicing
    private let paymentOrchestrator: PaymentOrchestrating
    private let notificationScheduler: NotificationScheduling
    private let persistence: AppPersisting

    init(
        bootstrap: AppBootstrapping = LocalMockBootstrap(),
        paymentOrchestrator: PaymentOrchestrating = LocalPaymentOrchestrator(),
        notificationScheduler: NotificationScheduling = LocalNotificationScheduler(),
        persistence: AppPersisting = JSONFileAppPersistence()
    ) {
        let initialState = bootstrap.makeInitialState()
        configuration = bootstrap.configuration
        authSession = initialState.authSession
        currentUser = initialState.currentUser
        users = initialState.users
        vehicles = initialState.vehicles
        rides = initialState.rides
        bookings = initialState.bookings
        payments = initialState.payments
        checkoutSessions = initialState.checkoutSessions
        driverPayouts = initialState.driverPayouts
        conversations = initialState.conversations
        messages = initialState.messages
        reviews = initialState.reviews
        reports = initialState.reports
        savedRideIDs = initialState.savedRideIDs
        savedRoutes = initialState.savedRoutes
        paymentMethods = initialState.paymentMethods
        payoutAccount = initialState.payoutAccount
        notificationsEnabled = initialState.notificationsEnabled
        pickupReminderNotificationsEnabled = initialState.pickupReminderNotificationsEnabled
        scheduledNotifications = initialState.scheduledNotifications
        emergencyContacts = initialState.emergencyContacts
        supportTickets = initialState.supportTickets
        searchCriteria = initialState.searchCriteria
        lastSyncedAt = initialState.lastSyncedAt
        authService = AppleAuthService(demoUser: initialState.demoUser)
        self.paymentOrchestrator = paymentOrchestrator
        self.notificationScheduler = notificationScheduler
        self.persistence = persistence
    }

    var isSignedIn: Bool {
        currentUser != nil
    }

    func signInWithApple() {
        let session = authService.signInWithApplePlaceholder()
        let user = self.user(with: session.userID)
        authSession = session
        currentUser = user
        upsert(user: user)
        persistSnapshot()
    }

    func signInDemoMode() {
        let session = authService.signInDemo()
        let user = self.user(with: session.userID)
        authSession = session
        currentUser = user
        upsert(user: user)
        persistSnapshot()
    }

    func signOut() {
        authSession = nil
        currentUser = nil
        persistSnapshot()
    }

    func resetLocalData() {
        try? persistence.clearSnapshot()
        let initialState = LocalMockBootstrap(persistence: persistence).makeInitialState()
        authSession = nil
        currentUser = nil
        users = initialState.users
        vehicles = initialState.vehicles
        rides = initialState.rides
        bookings = initialState.bookings
        payments = initialState.payments
        checkoutSessions = initialState.checkoutSessions
        driverPayouts = initialState.driverPayouts
        conversations = initialState.conversations
        messages = initialState.messages
        reviews = initialState.reviews
        reports = initialState.reports
        savedRideIDs = initialState.savedRideIDs
        savedRoutes = initialState.savedRoutes
        paymentMethods = initialState.paymentMethods
        payoutAccount = initialState.payoutAccount
        notificationsEnabled = initialState.notificationsEnabled
        pickupReminderNotificationsEnabled = initialState.pickupReminderNotificationsEnabled
        scheduledNotifications.forEach { notificationScheduler.cancel(identifier: $0.identifier) }
        scheduledNotifications = initialState.scheduledNotifications
        notificationErrorMessage = nil
        emergencyContacts = initialState.emergencyContacts
        supportTickets = initialState.supportTickets
        searchCriteria = initialState.searchCriteria
        lastSyncedAt = nil
        lastMarketplaceError = nil
    }

    func user(with id: UUID) -> AppUser {
        users.first(where: { $0.id == id }) ?? SeedData.fallbackUser
    }

    func vehicle(with id: UUID) -> Vehicle {
        vehicles.first(where: { $0.id == id }) ?? SeedData.fallbackVehicle
    }

    func ride(with id: UUID) -> Ride? {
        rides.first(where: { $0.id == id })
    }

    func payment(with id: UUID) -> Payment? {
        payments.first(where: { $0.id == id })
    }

    func isRideSaved(_ rideID: UUID) -> Bool {
        savedRideIDs.contains(rideID)
    }

    func toggleSavedRide(_ rideID: UUID) {
        if savedRideIDs.contains(rideID) {
            savedRideIDs.remove(rideID)
        } else {
            savedRideIDs.insert(rideID)
        }
        persistSnapshot()
    }

    func savedRides() -> [Ride] {
        rides
            .filter { savedRideIDs.contains($0.id) }
            .sorted { $0.departureDate < $1.departureDate }
    }

    func saveCurrentRoute() {
        let route = PopularRoute(origin: searchCriteria.origin, destination: searchCriteria.destination)
        guard !savedRoutes.contains(where: { $0.origin == route.origin && $0.destination == route.destination }) else { return }
        savedRoutes.insert(route, at: 0)
        persistSnapshot()
    }

    func removeSavedRoute(_ route: PopularRoute) {
        savedRoutes.removeAll { $0.origin == route.origin && $0.destination == route.destination }
        persistSnapshot()
    }

    func rides(matching criteria: SearchCriteria) -> [Ride] {
        rides
            .filter { ride in
                ride.status == .active &&
                ride.seatsAvailable >= criteria.seats &&
                matches(ride.origin, criteria.origin) &&
                matches(ride.destination, criteria.destination) &&
                Calendar.current.isDate(ride.departureDate, inSameDayAs: criteria.date)
            }
            .sorted { $0.departureDate < $1.departureDate }
    }

    func bookingsForCurrentRider(includePast: Bool) -> [Booking] {
        guard let currentUser else { return [] }

        return bookings
            .filter { booking in
                booking.riderID == currentUser.id &&
                (includePast ? [.completed, .canceled].contains(booking.status) : [.pending, .confirmed].contains(booking.status))
            }
            .sorted { lhs, rhs in
                let leftDate = ride(with: lhs.rideID)?.departureDate ?? lhs.createdAt
                let rightDate = ride(with: rhs.rideID)?.departureDate ?? rhs.createdAt
                return leftDate < rightDate
            }
    }

    func bookingsForDriverDashboard() -> [Booking] {
        guard let currentUser else {
            return bookings.sorted { $0.createdAt > $1.createdAt }
        }

        let rideIDsForCurrentUser = rides
            .filter { $0.driverID == currentUser.id }
            .map(\.id)

        let dashboardBookings = bookings.filter { booking in
            rideIDsForCurrentUser.contains(booking.rideID) || booking.riderID == currentUser.id
        }

        return dashboardBookings.sorted { $0.createdAt > $1.createdAt }
    }

    func bookingsForCurrentDriverListings() -> [Booking] {
        guard let currentUser else { return [] }
        let rideIDsForCurrentUser = rides
            .filter { $0.driverID == currentUser.id }
            .map(\.id)

        return bookings
            .filter { rideIDsForCurrentUser.contains($0.rideID) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func bookings(forRide rideID: UUID) -> [Booking] {
        bookings
            .filter { $0.rideID == rideID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func activeRidesForDriverDashboard() -> [Ride] {
        guard let currentUser else {
            return rides.filter { $0.status == .active }.prefix(3).map { $0 }
        }

        let ownRides = rides.filter { $0.driverID == currentUser.id && [.active, .soldOut].contains($0.status) }
        return ownRides.isEmpty ? rides.filter { $0.status == .active }.prefix(3).map { $0 } : ownRides
    }

    func conversationsForCurrentUser() -> [Conversation] {
        guard let currentUser else { return [] }
        return conversations
            .filter { $0.participantIDs.contains(currentUser.id) }
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }

    func conversationMessages(_ conversationID: UUID) -> [Message] {
        messages
            .filter { $0.conversationID == conversationID }
            .sorted { $0.sentAt < $1.sentAt }
    }

    func lastMessage(for conversation: Conversation) -> Message? {
        conversationMessages(conversation.id).last
    }

    func reviews(for userID: UUID) -> [Review] {
        reviews
            .filter { $0.subjectID == userID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func isOperating(_ key: String) -> Bool {
        activeOperationKeys.contains(key)
    }

    func payment(for booking: Booking) -> Payment? {
        payments.first(where: { $0.id == booking.paymentID })
    }

    func driverPayout(for bookingID: UUID) -> DriverPayout? {
        driverPayouts.first(where: { $0.bookingID == bookingID })
    }

    func currentDriverPayouts() -> [DriverPayout] {
        guard let currentUser else { return [] }
        return driverPayouts
            .filter { $0.driverID == currentUser.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func currentDriverPayoutTotal(matching statuses: Set<PayoutStatus>) -> Int {
        currentDriverPayouts()
            .filter { statuses.contains($0.status) }
            .reduce(0) { $0 + $1.amountCents }
    }

    func refreshNotificationPermission() async {
        notificationPermission = await notificationScheduler.currentPermissionStatus()
    }

    func setRideNotificationsEnabled(_ isEnabled: Bool) async {
        notificationsEnabled = isEnabled
        notificationErrorMessage = nil

        if isEnabled {
            notificationPermission = await notificationScheduler.requestPermission()
            if !notificationPermission.allowsScheduling {
                notificationErrorMessage = "Turn on notifications in iOS Settings to receive trip updates."
            }
        } else {
            notificationScheduler.cancel(identifiers: scheduledNotifications.map(\.identifier))
            scheduledNotifications.removeAll()
        }

        persistSnapshot()
    }

    func setPickupReminderNotificationsEnabled(_ isEnabled: Bool) async {
        pickupReminderNotificationsEnabled = isEnabled

        if isEnabled, notificationsEnabled {
            notificationPermission = await notificationScheduler.requestPermission()
        } else if !isEnabled {
            let reminders = scheduledNotifications.filter { $0.kind == .rideReminder }
            notificationScheduler.cancel(identifiers: reminders.map(\.identifier))
            scheduledNotifications.removeAll { $0.kind == .rideReminder }
        }

        persistSnapshot()
    }

    func clearScheduledNotifications() {
        notificationScheduler.cancel(identifiers: scheduledNotifications.map(\.identifier))
        scheduledNotifications.removeAll()
        persistSnapshot()
    }

    func didCurrentUserReview(booking: Booking, subjectID: UUID? = nil) -> Bool {
        guard let currentUser else { return false }
        return reviews.contains { review in
            review.rideID == booking.rideID &&
            review.authorID == currentUser.id &&
            (subjectID == nil || review.subjectID == subjectID)
        }
    }

    func updateCurrentUserProfile(name: String, phoneNumber: String, bio: String) {
        guard var currentUser else { return }
        currentUser.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        self.currentUser = currentUser
        upsert(user: currentUser)
        persistSnapshot()
    }

    func submitReview(booking: Booking, subjectID: UUID? = nil, rating: Int, body: String) {
        guard let currentUser,
              let ride = ride(with: booking.rideID),
              !didCurrentUserReview(booking: booking, subjectID: subjectID ?? ride.driverID) else {
            return
        }

        let reviewedUserID = subjectID ?? ride.driverID
        let review = Review(
            id: UUID(),
            rideID: ride.id,
            authorID: currentUser.id,
            subjectID: reviewedUserID,
            rating: min(max(rating, 1), 5),
            body: body.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: .now,
            syncState: .localOnly
        )

        reviews.insert(review, at: 0)
        recalculateRating(for: reviewedUserID)
        persistSnapshot()
    }

    func submitReport(subjectID: UUID?, rideID: UUID?, reason: ReportReason, details: String, isEmergency: Bool) {
        guard let currentUser else { return }

        reports.insert(
            TrustReport(
                id: UUID(),
                reporterID: currentUser.id,
                subjectID: subjectID,
                rideID: rideID,
                reason: reason,
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: .now,
                isEmergency: isEmergency,
                syncState: .localOnly
            ),
            at: 0
        )
        persistSnapshot()
    }

    func addPaymentMethod(kind: PaymentMethodKind, label: String, detail: String) {
        let method = PaymentMethod(
            id: UUID(),
            kind: kind,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            isDefault: paymentMethods.isEmpty
        )
        paymentMethods.append(method)
        persistSnapshot()
    }

    func makeDefaultPaymentMethod(_ method: PaymentMethod) {
        for index in paymentMethods.indices {
            paymentMethods[index].isDefault = paymentMethods[index].id == method.id
        }
        persistSnapshot()
    }

    func updatePayoutAccount(bankName: String, lastFour: String, instantPayoutsEnabled: Bool) {
        payoutAccount.bankName = bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        payoutAccount.lastFour = String(lastFour.trimmingCharacters(in: .whitespacesAndNewlines).suffix(4))
        payoutAccount.instantPayoutsEnabled = instantPayoutsEnabled
        payoutAccount.isVerified = !payoutAccount.bankName.isEmpty && payoutAccount.lastFour.count == 4
        persistSnapshot()
    }

    func addEmergencyContact(name: String, phoneNumber: String, relationship: String) {
        emergencyContacts.append(
            EmergencyContact(
                id: UUID(),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                relationship: relationship.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        persistSnapshot()
    }

    func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        persistSnapshot()
    }

    func submitSupportTicket(type: SupportIssueType, title: String, details: String) {
        supportTickets.insert(
            SupportTicket(
                id: UUID(),
                type: type,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: .now
            ),
            at: 0
        )
        persistSnapshot()
    }

    @discardableResult
    func bookRide(rideID: UUID, seats: Int) async -> Booking? {
        let operationKey = "book-\(rideID.uuidString)"
        beginOperation(operationKey)
        defer { endOperation(operationKey) }

        await simulateServiceLatency()

        do {
            guard let currentUser else {
                throw MarketplaceError.signedOut
            }

            guard let rideIndex = rides.firstIndex(where: { $0.id == rideID }),
                  rides[rideIndex].status == .active else {
                throw MarketplaceError.rideUnavailable
            }

            guard seats > 0, seats <= rides[rideIndex].seatsAvailable else {
                throw MarketplaceError.seatLimit
            }

            let ride = rides[rideIndex]
            let amountCents = seats * ride.pricePerSeatCents
            let checkoutSession = try paymentOrchestrator.createCheckoutSession(
                rideID: rideID,
                riderID: currentUser.id,
                seats: seats,
                amountCents: amountCents
            )

            var payment = try paymentOrchestrator.authorize(session: checkoutSession)
            let bookingStatus: BookingStatus
            let approvedAt: Date?

            if ride.manualApprovalEnabled {
                bookingStatus = .pending
                approvedAt = nil
            } else {
                payment = try paymentOrchestrator.capture(payment)
                bookingStatus = .confirmed
                approvedAt = .now
            }

            let booking = Booking(
                id: UUID(),
                rideID: rideID,
                riderID: currentUser.id,
                seats: seats,
                status: bookingStatus,
                paymentID: payment.id,
                createdAt: .now,
                updatedAt: .now,
                approvedAt: approvedAt,
                syncState: .localOnly
            )

            payment.bookingID = booking.id
            checkoutSessions.append(checkoutSession)
            payments.append(payment)
            bookings.append(booking)
            rides[rideIndex].seatsAvailable -= seats
            rides[rideIndex].updatedAt = .now
            if rides[rideIndex].seatsAvailable == 0 {
                rides[rideIndex].status = .soldOut
            }

            if booking.status == .confirmed {
                createOrUpdatePayout(for: booking, payment: payment, driverID: ride.driverID)
            }

            ensureConversation(for: booking, ride: ride, rider: currentUser)
            await scheduleBookingNotifications(for: booking, ride: ride, driver: user(with: ride.driverID))
            persistSnapshot()
            return booking
        } catch {
            recordMarketplaceError(error)
            return nil
        }
    }

    func cancelBooking(_ booking: Booking, declined: Bool = false) async {
        let operationKey = "cancel-booking-\(booking.id.uuidString)"
        beginOperation(operationKey)
        defer { endOperation(operationKey) }
        await simulateServiceLatency()

        guard let index = bookings.firstIndex(where: { $0.id == booking.id }),
              [.pending, .confirmed].contains(bookings[index].status) else {
            recordMarketplaceError(MarketplaceError.invalidAction)
            return
        }

        bookings[index].status = .canceled
        bookings[index].updatedAt = .now
        bookings[index].canceledAt = .now

        if let rideIndex = rides.firstIndex(where: { $0.id == booking.rideID }) {
            rides[rideIndex].seatsAvailable += booking.seats
            rides[rideIndex].updatedAt = .now
            if rides[rideIndex].status == .soldOut {
                rides[rideIndex].status = .active
            }
        }

        if let paymentIndex = payments.firstIndex(where: { $0.id == booking.paymentID }) {
            if payments[paymentIndex].status == .authorized {
                payments[paymentIndex] = (try? paymentOrchestrator.voidAuthorization(payments[paymentIndex])) ?? payments[paymentIndex]
            } else {
                payments[paymentIndex] = (try? paymentOrchestrator.refund(payments[paymentIndex])) ?? payments[paymentIndex]
            }
            cancelPayout(for: booking.id)
        }

        if let ride = ride(with: booking.rideID) {
            await scheduleBookingCanceledNotification(for: bookings[index], ride: ride, declined: declined)
        }

        persistSnapshot()
    }

    func accept(_ booking: Booking) async {
        let operationKey = "accept-booking-\(booking.id.uuidString)"
        beginOperation(operationKey)
        defer { endOperation(operationKey) }
        await simulateServiceLatency()

        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        guard bookings[index].status == .pending else {
            recordMarketplaceError(MarketplaceError.invalidAction)
            return
        }

        bookings[index].status = .confirmed
        bookings[index].updatedAt = .now
        bookings[index].approvedAt = .now

        if let paymentIndex = payments.firstIndex(where: { $0.id == booking.paymentID }) {
            payments[paymentIndex] = (try? paymentOrchestrator.capture(payments[paymentIndex])) ?? payments[paymentIndex]
            if let ride = ride(with: booking.rideID) {
                createOrUpdatePayout(for: bookings[index], payment: payments[paymentIndex], driverID: ride.driverID)
                await scheduleBookingAcceptedNotification(for: bookings[index], ride: ride)
            }
        }

        persistSnapshot()
    }

    func decline(_ booking: Booking) async {
        await cancelBooking(booking, declined: true)
    }

    func cancelRide(_ ride: Ride) async {
        let operationKey = "cancel-ride-\(ride.id.uuidString)"
        beginOperation(operationKey)
        defer { endOperation(operationKey) }
        await simulateServiceLatency()

        guard let rideIndex = rides.firstIndex(where: { $0.id == ride.id }) else { return }
        rides[rideIndex].status = .canceled
        rides[rideIndex].updatedAt = .now

        for index in bookings.indices where bookings[index].rideID == ride.id && [.pending, .confirmed].contains(bookings[index].status) {
            bookings[index].status = .canceled
            bookings[index].updatedAt = .now
            bookings[index].canceledAt = .now
            if let paymentIndex = payments.firstIndex(where: { $0.id == bookings[index].paymentID }) {
                if payments[paymentIndex].status == .authorized {
                    payments[paymentIndex] = (try? paymentOrchestrator.voidAuthorization(payments[paymentIndex])) ?? payments[paymentIndex]
                } else {
                    payments[paymentIndex] = (try? paymentOrchestrator.refund(payments[paymentIndex])) ?? payments[paymentIndex]
                }
                cancelPayout(for: bookings[index].id)
            }
            await scheduleBookingCanceledNotification(for: bookings[index], ride: rides[rideIndex])
        }
        persistSnapshot()
    }

    func completeRide(_ ride: Ride) async {
        let operationKey = "complete-ride-\(ride.id.uuidString)"
        beginOperation(operationKey)
        defer { endOperation(operationKey) }
        await simulateServiceLatency()

        guard let rideIndex = rides.firstIndex(where: { $0.id == ride.id }) else { return }
        rides[rideIndex].status = .completed
        rides[rideIndex].updatedAt = .now

        for index in bookings.indices where bookings[index].rideID == ride.id && bookings[index].status == .confirmed {
            bookings[index].status = .completed
            bookings[index].updatedAt = .now
            bookings[index].completedAt = .now
            markPayoutAvailable(for: bookings[index].id)
            await scheduleReviewPrompt(for: bookings[index], ride: rides[rideIndex])
        }
        persistSnapshot()
    }

    func createRide(
        origin: String,
        destination: String,
        departureDate: Date,
        pickupNotes: String,
        dropoffNotes: String,
        seats: Int,
        pricePerSeatCents: Int,
        vehicle: Vehicle,
        luggageAllowance: LuggageAllowance,
        preferences: Set<RidePreference>,
        manualApprovalEnabled: Bool
    ) {
        guard let currentUser else { return }

        let storedVehicle: Vehicle
        if let existingIndex = vehicles.firstIndex(where: { $0.ownerID == currentUser.id }) {
            let existingID = vehicles[existingIndex].id
            storedVehicle = Vehicle(
                id: existingID,
                ownerID: currentUser.id,
                make: vehicle.make,
                model: vehicle.model,
                color: vehicle.color,
                year: vehicle.year,
                plateState: vehicle.plateState
            )
            vehicles[existingIndex] = storedVehicle
        } else {
            storedVehicle = vehicle
            vehicles.append(vehicle)
        }

        let ride = Ride(
            id: UUID(),
            driverID: currentUser.id,
            vehicleID: storedVehicle.id,
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            pickupNotes: pickupNotes,
            dropoffNotes: dropoffNotes,
            seatsAvailable: seats,
            totalSeats: seats,
            pricePerSeatCents: pricePerSeatCents,
            luggageAllowance: luggageAllowance,
            preferences: preferences,
            manualApprovalEnabled: manualApprovalEnabled,
            status: .active,
            syncState: .localOnly,
            createdAt: .now,
            updatedAt: .now
        )

        rides.insert(ride, at: 0)
        persistSnapshot()
    }

    func updateRide(
        rideID: UUID,
        origin: String,
        destination: String,
        departureDate: Date,
        pickupNotes: String,
        dropoffNotes: String,
        totalSeats: Int,
        pricePerSeatCents: Int,
        vehicle: Vehicle,
        luggageAllowance: LuggageAllowance,
        preferences: Set<RidePreference>,
        manualApprovalEnabled: Bool
    ) {
        guard let rideIndex = rides.firstIndex(where: { $0.id == rideID }) else { return }

        if let vehicleIndex = vehicles.firstIndex(where: { $0.id == rides[rideIndex].vehicleID }) {
            vehicles[vehicleIndex] = vehicle
        } else {
            vehicles.append(vehicle)
        }

        let bookedSeats = max(0, rides[rideIndex].totalSeats - rides[rideIndex].seatsAvailable)
        let adjustedTotalSeats = max(totalSeats, bookedSeats)
        let adjustedAvailableSeats = max(0, adjustedTotalSeats - bookedSeats)
        let nextStatus: RideStatus
        if rides[rideIndex].status == .canceled || rides[rideIndex].status == .completed {
            nextStatus = rides[rideIndex].status
        } else {
            nextStatus = adjustedAvailableSeats == 0 ? .soldOut : .active
        }

        rides[rideIndex].origin = origin
        rides[rideIndex].destination = destination
        rides[rideIndex].departureDate = departureDate
        rides[rideIndex].pickupNotes = pickupNotes
        rides[rideIndex].dropoffNotes = dropoffNotes
        rides[rideIndex].totalSeats = adjustedTotalSeats
        rides[rideIndex].seatsAvailable = adjustedAvailableSeats
        rides[rideIndex].pricePerSeatCents = pricePerSeatCents
        rides[rideIndex].luggageAllowance = luggageAllowance
        rides[rideIndex].preferences = preferences
        rides[rideIndex].manualApprovalEnabled = manualApprovalEnabled
        rides[rideIndex].status = nextStatus
        rides[rideIndex].syncState = .localOnly
        rides[rideIndex].updatedAt = .now
        persistSnapshot()
    }

    func sendMessage(conversationID: UUID, text: String) {
        guard let currentUser else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = Message(
            id: UUID(),
            conversationID: conversationID,
            senderID: currentUser.id,
            body: trimmed,
            sentAt: .now,
            syncState: .localOnly
        )

        messages.append(message)
        if let index = conversations.firstIndex(where: { $0.id == conversationID }) {
            conversations[index].lastUpdated = .now
            conversations[index].syncState = .localOnly
        }
        persistSnapshot()
    }

    func routeTapped(_ route: PopularRoute) {
        searchCriteria.origin = route.origin
        searchCriteria.destination = route.destination
        if let nextRide = rides
            .filter({ ride in
                ride.status == .active &&
                matches(ride.origin, route.origin) &&
                matches(ride.destination, route.destination)
            })
            .sorted(by: { $0.departureDate < $1.departureDate })
            .first {
            searchCriteria.date = nextRide.departureDate
        }
        persistSnapshot()
    }

    private func beginOperation(_ key: String) {
        activeOperationKeys.insert(key)
        lastMarketplaceError = nil
    }

    private func endOperation(_ key: String) {
        activeOperationKeys.remove(key)
    }

    private func recordMarketplaceError(_ error: Error) {
        if let marketplaceError = error as? MarketplaceError {
            lastMarketplaceError = marketplaceError.errorDescription
        } else {
            lastMarketplaceError = error.localizedDescription
        }
    }

    private func simulateServiceLatency() async {
        try? await Task.sleep(nanoseconds: 250_000_000)
    }

    private func upsert(user: AppUser) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        } else {
            users.append(user)
        }
    }

    private func makeSnapshot() -> AppSnapshot {
        AppSnapshot(
            state: AppBootstrapState(
                demoUser: currentUser ?? users.first ?? SeedData.fallbackUser,
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
        )
    }

    private func persistSnapshot() {
        guard configuration.usesLocalData else { return }
        do {
            syncState = .syncing
            lastSyncedAt = .now
            try persistence.saveSnapshot(makeSnapshot())
            syncState = .synced
        } catch {
            syncState = .failed
            lastMarketplaceError = "Local save failed. Your latest action may not survive relaunch."
        }
    }

    private func recalculateRating(for userID: UUID) {
        let userReviews = reviews.filter { $0.subjectID == userID }
        guard !userReviews.isEmpty,
              let userIndex = users.firstIndex(where: { $0.id == userID }) else {
            return
        }

        let average = Double(userReviews.reduce(0) { $0 + $1.rating }) / Double(userReviews.count)
        users[userIndex].rating = average
        users[userIndex].reviewCount = userReviews.count

        if currentUser?.id == userID {
            currentUser = users[userIndex]
        }
    }

    private func matches(_ city: String, _ query: String) -> Bool {
        let cityKey = city.searchKey
        let queryKey = query.searchKey

        if cityKey == queryKey { return true }
        if cityKey.contains(queryKey) || queryKey.contains(cityKey) { return true }

        let aliases: [String: [String]] = [
            "new york ny": ["nyc", "new york", "manhattan"],
            "washington": ["dc", "washington"],
            "hoboken nj": ["hoboken"],
            "newport ri": ["newport"],
            "providence ri": ["providence"],
            "boston ma": ["boston"],
            "philadelphia pa": ["philly", "philadelphia"],
            "new haven ct": ["new haven"],
            "stamford ct": ["stamford"],
            "baltimore md": ["baltimore"]
        ]

        return aliases[cityKey]?.contains(queryKey) == true
    }

    private func createOrUpdatePayout(for booking: Booking, payment: Payment, driverID: UUID) {
        let amountCents = payment.driverPayoutCents > 0 ? payment.driverPayoutCents : payment.amountCents

        if let index = driverPayouts.firstIndex(where: { $0.bookingID == booking.id }) {
            driverPayouts[index].amountCents = amountCents
            driverPayouts[index].status = .pending
            driverPayouts[index].availableOn = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
        } else {
            driverPayouts.append(
                DriverPayout(
                    id: UUID(),
                    bookingID: booking.id,
                    driverID: driverID,
                    amountCents: amountCents,
                    status: .pending,
                    availableOn: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
                    createdAt: .now
                )
            )
        }
    }

    private func cancelPayout(for bookingID: UUID) {
        guard let index = driverPayouts.firstIndex(where: { $0.bookingID == bookingID }) else { return }
        driverPayouts[index].status = .canceled
    }

    private func markPayoutAvailable(for bookingID: UUID) {
        guard let index = driverPayouts.firstIndex(where: { $0.bookingID == bookingID }) else { return }
        driverPayouts[index].status = .available
        driverPayouts[index].availableOn = .now
    }

    private func scheduleBookingNotifications(for booking: Booking, ride: Ride, driver: AppUser) async {
        let title = booking.status == .pending ? "Booking request sent" : "Seat booked"
        let body = booking.status == .pending
            ? "\(driver.firstName) will review your request for \(ride.routeTitle)."
            : "You're confirmed for \(ride.routeTitle) on \(ride.departureDate.dayText)."

        await scheduleNotification(
            kind: booking.status == .pending ? .bookingRequested : .bookingConfirmed,
            rideID: ride.id,
            bookingID: booking.id,
            title: title,
            body: body,
            deliveryDate: Calendar.current.date(byAdding: .second, value: 5, to: .now) ?? .now
        )

        await scheduleRideReminderIfNeeded(for: booking, ride: ride)
    }

    private func scheduleDriverRequestNotification(for booking: Booking, ride: Ride, rider: AppUser) async {
        await scheduleNotification(
            kind: .driverRequest,
            rideID: ride.id,
            bookingID: booking.id,
            title: "New rider request",
            body: "\(rider.firstName) requested \(booking.seats) \(booking.seats == 1 ? "seat" : "seats") on \(ride.routeTitle).",
            deliveryDate: Calendar.current.date(byAdding: .second, value: 5, to: .now) ?? .now
        )
    }

    private func scheduleBookingAcceptedNotification(for booking: Booking, ride: Ride) async {
        await scheduleNotification(
            kind: .bookingConfirmed,
            rideID: ride.id,
            bookingID: booking.id,
            title: "Booking accepted",
            body: "\(ride.routeTitle) is confirmed. Payment was captured in demo mode.",
            deliveryDate: Calendar.current.date(byAdding: .second, value: 5, to: .now) ?? .now
        )

        await scheduleRideReminderIfNeeded(for: booking, ride: ride)
    }

    private func scheduleBookingCanceledNotification(for booking: Booking, ride: Ride, declined: Bool = false) async {
        cancelScheduledNotifications(forBookingID: booking.id, kinds: [.rideReminder])
        await scheduleNotification(
            kind: declined ? .bookingDeclined : .bookingCanceled,
            rideID: ride.id,
            bookingID: booking.id,
            title: declined ? "Booking declined" : "Booking canceled",
            body: declined ? "The request for \(ride.routeTitle) was declined." : "\(ride.routeTitle) has been canceled and seats were released.",
            deliveryDate: Calendar.current.date(byAdding: .second, value: 5, to: .now) ?? .now
        )
    }

    private func scheduleReviewPrompt(for booking: Booking, ride: Ride) async {
        await scheduleNotification(
            kind: .reviewPrompt,
            rideID: ride.id,
            bookingID: booking.id,
            title: "How was the ride?",
            body: "Leave a quick review for \(ride.routeTitle).",
            deliveryDate: Calendar.current.date(byAdding: .second, value: 5, to: .now) ?? .now
        )
    }

    private func scheduleRideReminderIfNeeded(for booking: Booking, ride: Ride) async {
        guard pickupReminderNotificationsEnabled, booking.status == .confirmed else { return }

        let preferredDate = Calendar.current.date(byAdding: .hour, value: -2, to: ride.departureDate) ?? ride.departureDate
        let deliveryDate = max(preferredDate, Calendar.current.date(byAdding: .minute, value: 1, to: .now) ?? .now)

        await scheduleNotification(
            kind: .rideReminder,
            rideID: ride.id,
            bookingID: booking.id,
            title: "Ride soon",
            body: "\(ride.routeTitle) leaves at \(ride.departureDate.timeText). Check pickup notes before you go.",
            deliveryDate: deliveryDate
        )
    }

    private func scheduleNotification(
        kind: RideNotificationKind,
        rideID: UUID?,
        bookingID: UUID?,
        title: String,
        body: String,
        deliveryDate: Date
    ) async {
        guard notificationsEnabled else { return }

        if notificationPermission == .notDetermined {
            notificationPermission = await notificationScheduler.requestPermission()
        } else {
            notificationPermission = await notificationScheduler.currentPermissionStatus()
        }

        guard notificationPermission.allowsScheduling else {
            notificationErrorMessage = "Notifications are off for Shotgun."
            return
        }

        let notification = ScheduledRideNotification(
            id: UUID(),
            kind: kind,
            rideID: rideID,
            bookingID: bookingID,
            title: title,
            body: body,
            scheduledAt: .now,
            deliveryDate: deliveryDate
        )

        do {
            try await notificationScheduler.schedule(notification)
            scheduledNotifications.removeAll { existing in
                existing.kind == kind && existing.bookingID == bookingID && existing.rideID == rideID
            }
            scheduledNotifications.insert(notification, at: 0)
            notificationErrorMessage = nil
        } catch {
            notificationErrorMessage = "Notification could not be scheduled."
        }
    }

    private func cancelScheduledNotifications(forBookingID bookingID: UUID, kinds: Set<RideNotificationKind>? = nil) {
        let matching = scheduledNotifications.filter { notification in
            notification.bookingID == bookingID && (kinds == nil || kinds?.contains(notification.kind) == true)
        }
        notificationScheduler.cancel(identifiers: matching.map(\.identifier))
        scheduledNotifications.removeAll { notification in
            notification.bookingID == bookingID && (kinds == nil || kinds?.contains(notification.kind) == true)
        }
    }

    private func ensureConversation(for booking: Booking, ride: Ride, rider: AppUser) {
        if conversations.contains(where: { $0.bookingID == booking.id }) {
            return
        }

        let conversation = Conversation(
            id: UUID(),
            rideID: ride.id,
            bookingID: booking.id,
            participantIDs: [rider.id, ride.driverID],
            lastUpdated: .now,
            syncState: .localOnly
        )

        conversations.append(conversation)
        messages.append(
            Message(
                id: UUID(),
                conversationID: conversation.id,
                senderID: ride.driverID,
                body: "Thanks for booking. I will send exact pickup details the morning of the ride.",
                sentAt: .now,
                syncState: .localOnly
            )
        )
    }
}

enum AppTab: Hashable {
    case search
    case trips
    case drive
    case inbox
    case profile
}

enum SeedData {
    static let currentUserID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    static let maeID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    static let samID = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
    static let jordanID = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    static let priyaID = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
    static let ninaID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!

    static let fallbackUser = AppUser(
        id: UUID(),
        name: "Corridor Driver",
        phoneNumber: "(555) 010-0000",
        bio: "Verified community member.",
        rating: 4.8,
        reviewCount: 18,
        isVerified: true,
        phoneVerified: true,
        profileSymbolName: "person.crop.circle"
    )

    static let fallbackVehicle = Vehicle(
        id: UUID(),
        ownerID: UUID(),
        make: "Toyota",
        model: "Camry",
        color: "Blue",
        year: 2021,
        plateState: "NY"
    )

    static func make() -> (
        currentUser: AppUser,
        users: [AppUser],
        vehicles: [Vehicle],
        rides: [Ride],
        bookings: [Booking],
        payments: [Payment],
        checkoutSessions: [CheckoutSession],
        driverPayouts: [DriverPayout],
        conversations: [Conversation],
        messages: [Message],
        reviews: [Review],
        reports: [TrustReport]
    ) {
        let currentUser = AppUser(
            id: currentUserID,
            name: "Alex Morgan",
            phoneNumber: "(917) 555-0148",
            bio: "Splits time between Brooklyn and New England. Light packer, punctual, and happy to share playlists.",
            rating: 4.9,
            reviewCount: 27,
            isVerified: true,
            phoneVerified: true,
            profileSymbolName: "person.crop.circle.fill"
        )

        let mae = AppUser(
            id: maeID,
            name: "Mae Carter",
            phoneNumber: "(401) 555-0192",
            bio: "Newport local, usually driving between SoHo and Aquidneck Island for work.",
            rating: 4.98,
            reviewCount: 64,
            isVerified: true,
            phoneVerified: true,
            profileSymbolName: "person.crop.circle.badge.checkmark"
        )

        let sam = AppUser(
            id: samID,
            name: "Sam Patel",
            phoneNumber: "(617) 555-0108",
            bio: "Product designer in Boston. Quiet car, clean trunk, coffee stops negotiable.",
            rating: 4.86,
            reviewCount: 41,
            isVerified: true,
            phoneVerified: true,
            profileSymbolName: "person.crop.circle"
        )

        let jordan = AppUser(
            id: jordanID,
            name: "Jordan Lee",
            phoneNumber: "(202) 555-0177",
            bio: "DC to NYC every few weeks. Prefer an on-time departure and low-key conversation.",
            rating: 4.74,
            reviewCount: 22,
            isVerified: true,
            phoneVerified: false,
            profileSymbolName: "person.crop.circle"
        )

        let priya = AppUser(
            id: priyaID,
            name: "Priya Shah",
            phoneNumber: "(215) 555-0133",
            bio: "Grad student, careful driver, and generous with trunk space.",
            rating: 4.92,
            reviewCount: 36,
            isVerified: true,
            phoneVerified: true,
            profileSymbolName: "person.crop.circle"
        )

        let nina = AppUser(
            id: ninaID,
            name: "Nina Brooks",
            phoneNumber: "(203) 555-0181",
            bio: "Weekend traveler and early train alternative seeker.",
            rating: 4.81,
            reviewCount: 15,
            isVerified: false,
            phoneVerified: true,
            profileSymbolName: "person.crop.circle"
        )

        let maeCar = Vehicle(id: UUID(), ownerID: maeID, make: "Volvo", model: "XC60", color: "Sage", year: 2023, plateState: "RI")
        let samCar = Vehicle(id: UUID(), ownerID: samID, make: "Tesla", model: "Model 3", color: "White", year: 2022, plateState: "MA")
        let jordanCar = Vehicle(id: UUID(), ownerID: jordanID, make: "Subaru", model: "Outback", color: "Gray", year: 2021, plateState: "DC")
        let priyaCar = Vehicle(id: UUID(), ownerID: priyaID, make: "Honda", model: "CR-V", color: "Blue", year: 2020, plateState: "PA")
        let alexCar = Vehicle(id: UUID(), ownerID: currentUserID, make: "Toyota", model: "RAV4", color: "Black", year: 2022, plateState: "NY")

        let calendar = Calendar.current
        func date(days: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: days, to: .now) ?? .now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let rideNYCNewport = Ride(
            id: UUID(),
            driverID: maeID,
            vehicleID: maeCar.id,
            origin: "New York, NY",
            destination: "Newport, RI",
            departureDate: date(days: 1, hour: 8, minute: 15),
            pickupNotes: "SoHo pickup near Canal St. Easy subway access.",
            dropoffNotes: "Newport Gateway Center, flexible downtown drop.",
            seatsAvailable: 3,
            totalSeats: 4,
            pricePerSeatCents: 4800,
            luggageAllowance: .carryOn,
            preferences: [.noSmoking, .quietRide, .chargerAvailable],
            manualApprovalEnabled: false,
            status: .active
        )

        let rideNYCProvidence = Ride(
            id: UUID(),
            driverID: samID,
            vehicleID: samCar.id,
            origin: "New York, NY",
            destination: "Providence, RI",
            departureDate: date(days: 1, hour: 16, minute: 30),
            pickupNotes: "Meet outside Moynihan Train Hall on 31st St.",
            dropoffNotes: "Dropoff by Providence Station.",
            seatsAvailable: 2,
            totalSeats: 3,
            pricePerSeatCents: 3900,
            luggageAllowance: .backpack,
            preferences: [.noSmoking, .musicOkay],
            manualApprovalEnabled: true,
            status: .active
        )

        let rideBostonNYC = Ride(
            id: UUID(),
            driverID: samID,
            vehicleID: samCar.id,
            origin: "Boston, MA",
            destination: "New York, NY",
            departureDate: date(days: 2, hour: 7, minute: 45),
            pickupNotes: "Back Bay curbside pickup.",
            dropoffNotes: "Upper West Side or Midtown East.",
            seatsAvailable: 1,
            totalSeats: 3,
            pricePerSeatCents: 5200,
            luggageAllowance: .carryOn,
            preferences: [.quietRide, .chargerAvailable],
            manualApprovalEnabled: false,
            status: .active
        )

        let ridePhillyDC = Ride(
            id: UUID(),
            driverID: priyaID,
            vehicleID: priyaCar.id,
            origin: "Philadelphia, PA",
            destination: "Washington, DC",
            departureDate: date(days: 1, hour: 9, minute: 0),
            pickupNotes: "30th Street Station west curb.",
            dropoffNotes: "Union Station main entrance.",
            seatsAvailable: 2,
            totalSeats: 3,
            pricePerSeatCents: 2800,
            luggageAllowance: .checkedBag,
            preferences: [.noSmoking, .petsAllowed, .musicOkay],
            manualApprovalEnabled: false,
            status: .active
        )

        let rideDCNYC = Ride(
            id: UUID(),
            driverID: jordanID,
            vehicleID: jordanCar.id,
            origin: "Washington, DC",
            destination: "New York, NY",
            departureDate: date(days: 3, hour: 13, minute: 15),
            pickupNotes: "Capitol Hill pickup near Eastern Market.",
            dropoffNotes: "Brooklyn dropoff near Atlantic Terminal.",
            seatsAvailable: 3,
            totalSeats: 3,
            pricePerSeatCents: 4500,
            luggageAllowance: .carryOn,
            preferences: [.quietRide, .noSmoking],
            manualApprovalEnabled: true,
            status: .active
        )

        let rideNewHavenNYC = Ride(
            id: UUID(),
            driverID: currentUserID,
            vehicleID: alexCar.id,
            origin: "New Haven, CT",
            destination: "New York, NY",
            departureDate: date(days: 2, hour: 18, minute: 10),
            pickupNotes: "Union Station pickup by the taxi stand.",
            dropoffNotes: "Grand Central or Williamsburg by request.",
            seatsAvailable: 2,
            totalSeats: 3,
            pricePerSeatCents: 2400,
            luggageAllowance: .backpack,
            preferences: [.noSmoking, .musicOkay, .chargerAvailable],
            manualApprovalEnabled: true,
            status: .active
        )

        let completedRide = Ride(
            id: UUID(),
            driverID: maeID,
            vehicleID: maeCar.id,
            origin: "New York, NY",
            destination: "Providence, RI",
            departureDate: date(days: -4, hour: 10, minute: 0),
            pickupNotes: "Lower East Side pickup.",
            dropoffNotes: "RISD Museum curb.",
            seatsAvailable: 0,
            totalSeats: 3,
            pricePerSeatCents: 3600,
            luggageAllowance: .carryOn,
            preferences: [.noSmoking, .quietRide],
            manualApprovalEnabled: false,
            status: .completed
        )

        let unreviewedCompletedRide = Ride(
            id: UUID(),
            driverID: jordanID,
            vehicleID: jordanCar.id,
            origin: "Hoboken, NJ",
            destination: "Baltimore, MD",
            departureDate: date(days: -2, hour: 15, minute: 30),
            pickupNotes: "Hoboken Terminal south entrance.",
            dropoffNotes: "Penn Station Baltimore curbside.",
            seatsAvailable: 0,
            totalSeats: 3,
            pricePerSeatCents: 3300,
            luggageAllowance: .carryOn,
            preferences: [.quietRide, .noSmoking],
            manualApprovalEnabled: false,
            status: .completed
        )

        let seedPayment = Payment(
            id: UUID(),
            bookingID: nil,
            amountCents: 2400,
            provider: .stub,
            status: .authorized,
            intentStatus: .authorized,
            refundStatus: .notNeeded,
            payoutStatus: .notStarted,
            platformFeeCents: 288,
            driverPayoutCents: 2112,
            createdAt: date(days: -1, hour: 12, minute: 20),
            authorizedAt: date(days: -1, hour: 12, minute: 20),
            note: "Successful demo payment."
        )

        let seedBooking = Booking(
            id: UUID(),
            rideID: rideNewHavenNYC.id,
            riderID: ninaID,
            seats: 1,
            status: .pending,
            paymentID: seedPayment.id,
            createdAt: date(days: -1, hour: 12, minute: 20)
        )

        let tripPayment = Payment(
            id: UUID(),
            bookingID: nil,
            amountCents: 3600,
            provider: .stub,
            status: .succeeded,
            intentStatus: .captured,
            refundStatus: .notNeeded,
            payoutStatus: .available,
            platformFeeCents: 432,
            driverPayoutCents: 3168,
            createdAt: date(days: -6, hour: 8, minute: 0),
            authorizedAt: date(days: -6, hour: 8, minute: 0),
            capturedAt: date(days: -6, hour: 8, minute: 0),
            note: "Successful demo payment."
        )

        let pastBooking = Booking(
            id: UUID(),
            rideID: completedRide.id,
            riderID: currentUserID,
            seats: 1,
            status: .completed,
            paymentID: tripPayment.id,
            createdAt: date(days: -6, hour: 8, minute: 0)
        )

        let unreviewedTripPayment = Payment(
            id: UUID(),
            bookingID: nil,
            amountCents: 3300,
            provider: .stub,
            status: .succeeded,
            intentStatus: .captured,
            refundStatus: .notNeeded,
            payoutStatus: .available,
            platformFeeCents: 396,
            driverPayoutCents: 2904,
            createdAt: date(days: -3, hour: 9, minute: 45),
            authorizedAt: date(days: -3, hour: 9, minute: 45),
            capturedAt: date(days: -3, hour: 9, minute: 45),
            note: "Successful demo payment."
        )

        let unreviewedPastBooking = Booking(
            id: UUID(),
            rideID: unreviewedCompletedRide.id,
            riderID: currentUserID,
            seats: 1,
            status: .completed,
            paymentID: unreviewedTripPayment.id,
            createdAt: date(days: -3, hour: 9, minute: 45)
        )

        let driverConversation = Conversation(
            id: UUID(),
            rideID: rideNewHavenNYC.id,
            bookingID: seedBooking.id,
            participantIDs: [currentUserID, ninaID],
            lastUpdated: date(days: -1, hour: 12, minute: 40)
        )

        let pastConversation = Conversation(
            id: UUID(),
            rideID: completedRide.id,
            bookingID: pastBooking.id,
            participantIDs: [currentUserID, maeID],
            lastUpdated: date(days: -4, hour: 9, minute: 0)
        )

        let messages = [
            Message(id: UUID(), conversationID: driverConversation.id, senderID: ninaID, body: "Hi Alex, I can meet at Union Station 10 minutes early.", sentAt: date(days: -1, hour: 12, minute: 35)),
            Message(id: UUID(), conversationID: driverConversation.id, senderID: currentUserID, body: "Perfect. I will be in the black RAV4 by the taxi stand.", sentAt: date(days: -1, hour: 12, minute: 40)),
            Message(id: UUID(), conversationID: pastConversation.id, senderID: maeID, body: "Great riding with you last week. Thanks for being right on time.", sentAt: date(days: -4, hour: 9, minute: 0))
        ]

        let reviews = [
            Review(id: UUID(), rideID: completedRide.id, authorID: currentUserID, subjectID: maeID, rating: 5, body: "Mae was calm, prompt, and the car was spotless.", createdAt: date(days: -3, hour: 14, minute: 0)),
            Review(id: UUID(), rideID: completedRide.id, authorID: maeID, subjectID: currentUserID, rating: 5, body: "Alex was easy to coordinate with and ready at pickup.", createdAt: date(days: -3, hour: 15, minute: 0)),
            Review(id: UUID(), rideID: rideBostonNYC.id, authorID: priyaID, subjectID: samID, rating: 5, body: "Smooth Boston to New York ride and very clear pickup notes.", createdAt: date(days: -7, hour: 11, minute: 0))
        ]

        let pastDriverPayout = DriverPayout(
            id: UUID(),
            bookingID: pastBooking.id,
            driverID: maeID,
            amountCents: 3168,
            status: .available,
            availableOn: date(days: -2, hour: 8, minute: 0),
            createdAt: date(days: -6, hour: 8, minute: 0)
        )

        let unreviewedDriverPayout = DriverPayout(
            id: UUID(),
            bookingID: unreviewedPastBooking.id,
            driverID: jordanID,
            amountCents: 2904,
            status: .available,
            availableOn: date(days: -1, hour: 9, minute: 45),
            createdAt: date(days: -3, hour: 9, minute: 45)
        )

        return (
            currentUser,
            [currentUser, mae, sam, jordan, priya, nina],
            [maeCar, samCar, jordanCar, priyaCar, alexCar],
            [rideNYCNewport, rideNYCProvidence, rideBostonNYC, ridePhillyDC, rideDCNYC, rideNewHavenNYC, completedRide, unreviewedCompletedRide],
            [seedBooking, pastBooking, unreviewedPastBooking],
            [seedPayment, tripPayment, unreviewedTripPayment],
            [],
            [pastDriverPayout, unreviewedDriverPayout],
            [driverConversation, pastConversation],
            messages,
            reviews,
            []
        )
    }
}
