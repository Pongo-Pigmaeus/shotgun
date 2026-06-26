import AuthenticationServices
import SwiftUI

extension PaymentStatus {
    var statusColor: Color {
        switch self {
        case .pending, .authorized:
            .appGold
        case .succeeded:
            .appMint
        case .failed, .refunded, .voided:
            .appCoral
        }
    }
}

extension PayoutStatus {
    var statusColor: Color {
        switch self {
        case .notStarted:
            .secondary
        case .pending:
            .appGold
        case .available, .paid:
            .appMint
        case .canceled:
            .appCoral
        }
    }
}

extension SyncState {
    var statusColor: Color {
        switch self {
        case .localOnly:
            .appGold
        case .syncing:
            .appTint
        case .synced:
            .appMint
        case .failed:
            .appCoral
        }
    }
}

extension NotificationPermissionStatus {
    var statusColor: Color {
        switch self {
        case .authorized, .provisional, .ephemeral:
            .appMint
        case .notDetermined:
            .appGold
        case .denied:
            .appCoral
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.isSignedIn {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(.appTint)
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Image(systemName: "car.2.fill")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(AppTheme.routeGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Spacer()

                            Text("Shotgun")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.secondary)
                        }

                        Text("Shared rides between Northeast cities.")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .lineLimit(3)
                            .minimumScaleFactor(0.78)

                        Text("Find comfortable empty seats, book in a few taps, and coordinate with verified riders and drivers from Boston to DC.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    CorridorPreview()

                    VStack(spacing: 12) {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { _ in
                            store.signInWithApple()
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        SecondaryButton(title: "Use Demo Mode", systemImage: "play.circle.fill") {
                            store.signInDemoMode()
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Verified profiles and phone checks.", systemImage: "checkmark.seal")
                        Label("Seats reserved with clear trip details.", systemImage: "creditcard")
                        Label("Built for Northeast city-to-city rides.", systemImage: "map")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct CorridorPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Tonight", systemImage: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("6 open seats")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            VStack(spacing: 14) {
                previewRow(origin: "NYC", destination: "Newport", price: "$48", time: "8:15 AM")
                previewRow(origin: "Philadelphia", destination: "DC", price: "$28", time: "9:00 AM")
                previewRow(origin: "Boston", destination: "NYC", price: "$52", time: "7:45 AM")
            }
        }
        .padding(18)
        .background(AppTheme.routeGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.appTint.opacity(0.22), radius: 24, y: 12)
    }

    private func previewRow(origin: String, destination: String, price: String, time: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.18), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("\(origin) to \(destination)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()

            Text(price)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            NavigationStack {
                MyTripsView()
            }
            .tabItem { Label("Trips", systemImage: "ticket") }
            .tag(AppTab.trips)

            NavigationStack {
                DriveView()
            }
            .tabItem { Label("Drive", systemImage: "steeringwheel") }
            .tag(AppTab.drive)

            NavigationStack {
                MessagesView()
            }
            .tabItem { Label("Inbox", systemImage: "bubble.left.and.bubble.right") }
            .tag(AppTab.inbox)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(AppTab.profile)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showResults = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                searchCard
                popularRoutes
                savedShortcuts
                todayHighlights
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Shotgun")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showResults) {
            RideResultsView(criteria: store.searchCriteria)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared rides between Northeast cities.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .lineLimit(3)
                .minimumScaleFactor(0.78)

            HStack(spacing: 10) {
                Label("Verified profiles", systemImage: "checkmark.seal.fill")
                Label("Seat-safe booking", systemImage: "lock.fill")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchCard: some View {
        VStack(spacing: 18) {
            CityTextField(title: "From", text: $store.searchCriteria.origin, cities: store.cities)
            CityTextField(title: "To", text: $store.searchCriteria.destination, cities: store.cities)

            HStack(spacing: 12) {
                DatePicker("Date", selection: $store.searchCriteria.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Stepper(value: $store.searchCriteria.seats, in: 1...4) {
                    Label("\(store.searchCriteria.seats)", systemImage: "person.2")
                        .font(.headline)
                }
                .frame(width: 116)
            }
            .padding(.top, 2)

            PrimaryButton(title: "Search rides", systemImage: "magnifyingglass") {
                showResults = true
            }
        }
        .appCard()
    }

    private var popularRoutes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular routes")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.popularRoutes) { route in
                        Button {
                            store.routeTapped(route)
                            showResults = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    .foregroundStyle(Color.appTint)
                                Text(route.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var savedShortcuts: some View {
        let savedRides = store.savedRides()

        if !store.savedRoutes.isEmpty || !savedRides.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Saved")
                    .font(.headline)

                if !store.savedRoutes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.savedRoutes) { route in
                                Button {
                                    store.routeTapped(route)
                                    showResults = true
                                } label: {
                                    Label(route.title, systemImage: "bookmark.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color.appTint.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                ForEach(savedRides.prefix(1)) { ride in
                    NavigationLink {
                        RideDetailView(rideID: ride.id)
                    } label: {
                        RideCard(ride: ride)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var todayHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Good options today")
                    .font(.headline)
                Spacer()
                Button("View all") {
                    showResults = true
                }
                .font(.subheadline.weight(.semibold))
            }

            ForEach(store.rides.filter { $0.status == .active }.prefix(2)) { ride in
                NavigationLink {
                    RideDetailView(rideID: ride.id)
                } label: {
                    RideCard(ride: ride)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct RideResultsView: View {
    @EnvironmentObject private var store: AppStore
    let criteria: SearchCriteria
    @State private var sort = RideSort.earliest
    @State private var instantOnly = false

    private var results: [Ride] {
        let matchingRides = store.rides(matching: criteria)
            .filter { !instantOnly || !$0.manualApprovalEnabled }

        switch sort {
        case .earliest:
            return matchingRides.sorted { $0.departureDate < $1.departureDate }
        case .lowestPrice:
            return matchingRides.sorted { $0.pricePerSeatCents < $1.pricePerSeatCents }
        case .highestRated:
            return matchingRides.sorted { lhs, rhs in
                store.user(with: lhs.driverID).rating > store.user(with: rhs.driverID).rating
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(criteria.origin.shortCity) to \(criteria.destination.shortCity)")
                        .font(.title2.weight(.bold))
                    Text("\(criteria.date.dayText) · \(criteria.seats) \(criteria.seats == 1 ? "seat" : "seats")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SecondaryButton(title: "Save this route", systemImage: "bookmark.fill") {
                    store.searchCriteria = criteria
                    store.saveCurrentRoute()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Sort", selection: $sort) {
                        ForEach(RideSort.allCases) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle(isOn: $instantOnly) {
                        Label("Instant booking only", systemImage: "bolt.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .appCard(padding: 14)

                if results.isEmpty {
                    EmptyStateView(
                        systemImage: "car.rear.road.lane",
                        title: "No matching seats yet",
                        message: "Try a nearby city, a different date, or one fewer seat."
                    )
                } else {
                    ForEach(results) { ride in
                        NavigationLink {
                            RideDetailView(rideID: ride.id)
                        } label: {
                            RideCard(ride: ride)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Available rides")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RideDetailView: View {
    @EnvironmentObject private var store: AppStore
    let rideID: UUID
    @State private var showBooking = false
    @State private var showReport = false

    var body: some View {
        Group {
            if let ride = store.ride(with: rideID) {
                detailContent(ride)
                    .safeAreaInset(edge: .bottom) {
                        bottomBar(ride)
                    }
                    .sheet(isPresented: $showBooking) {
                        BookingFlowView(rideID: ride.id)
                            .presentationDetents([.medium, .large])
                    }
                    .sheet(isPresented: $showReport) {
                        ReportUserView(subjectID: ride.driverID, rideID: ride.id)
                            .presentationDetents([.medium, .large])
                    }
            } else {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "Ride unavailable", message: "This listing may have been removed.")
                    .padding(20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ride details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleSavedRide(rideID)
                } label: {
                    Image(systemName: store.isRideSaved(rideID) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(store.isRideSaved(rideID) ? "Unsave ride" : "Save ride")
            }
        }
    }

    private func detailContent(_ ride: Ride) -> some View {
        let driver = store.user(with: ride.driverID)
        let vehicle = store.vehicle(with: ride.vehicleID)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                routeHero(ride)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        AvatarView(user: driver, size: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(driver.name)
                                .font(.headline)
                            HStack(spacing: 8) {
                                RatingPill(rating: driver.rating, count: driver.reviewCount)
                                if driver.isVerified {
                                    StatusBadge(text: "Verified", color: .appMint)
                                }
                            }
                        }
                        Spacer()
                    }

                    Text(driver.bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showReport = true
                    } label: {
                        Label("Report driver or listing", systemImage: "exclamationmark.bubble")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appCoral)
                    }
                    .buttonStyle(.plain)
                }
                .appCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Ride plan")
                        .font(.headline)
                    Label(ride.departureDate.shortDateTimeText, systemImage: "clock")
                    Label(ride.pickupNotes, systemImage: "mappin.and.ellipse")
                    Label(ride.dropoffNotes, systemImage: "flag.checkered")
                    Label("\(ride.luggageAllowance.rawValue) luggage", systemImage: "suitcase")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Car")
                        .font(.headline)
                    HStack {
                        Image(systemName: "car.side.fill")
                            .font(.title2)
                            .foregroundStyle(Color.appTint)
                            .frame(width: 48, height: 48)
                            .background(Color.appTint.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vehicle.displayName)
                                .font(.headline)
                            Text("\(vehicle.year) · \(vehicle.plateState) plates")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferences")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(Array(ride.preferences).sorted(by: { $0.rawValue < $1.rawValue })) { preference in
                            PreferenceBadge(preference: preference)
                        }
                    }
                }
                .appCard()

                reviewsPreview(for: driver)
                    .padding(.bottom, 98)
            }
            .padding(20)
        }
    }

    private func routeHero(_ ride: Ride) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.routeTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text(ride.departureDate.shortDateTimeText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ride.pricePerSeatCents.dollarsText)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    Text("per seat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }

            HStack(spacing: 12) {
                Label("\(ride.seatsAvailable) available", systemImage: "person.2.fill")
                Label(ride.manualApprovalEnabled ? "Approval" : "Instant", systemImage: ride.manualApprovalEnabled ? "hand.raised.fill" : "bolt.fill")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
        }
        .padding(20)
        .background(AppTheme.routeGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.appTint.opacity(0.18), radius: 18, y: 10)
    }

    private func reviewsPreview(for driver: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent reviews")
                .font(.headline)

            let userReviews = store.reviews(for: driver.id)
            if userReviews.isEmpty {
                Text("No written reviews yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(userReviews.prefix(2)) { review in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(String(repeating: "★", count: review.rating))
                                .foregroundStyle(Color.appGold)
                            Spacer()
                            Text(store.user(with: review.authorID).firstName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(review.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .compactCard()
                }
            }
        }
        .appCard()
    }

    private func bottomBar(_ ride: Ride) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ride.pricePerSeatCents.dollarsText)
                    .font(.title3.weight(.bold))
                Text("\(ride.seatsAvailable) seats left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showBooking = true
            } label: {
                Label("Book", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppTheme.routeGradient, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(ride.status != .active || ride.seatsAvailable == 0)
            .opacity(ride.status == .active && ride.seatsAvailable > 0 ? 1 : 0.45)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

struct BookingFlowView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let rideID: UUID
    @State private var seats = 1
    @State private var booking: Booking?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Group {
                if let booking {
                    BookingConfirmationView(booking: booking) {
                        dismiss()
                    }
                } else if let ride = store.ride(with: rideID) {
                    bookingForm(ride)
                }
            }
            .navigationTitle("Book ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Seat no longer available", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.lastMarketplaceError ?? "Try a different ride or reduce the number of seats.")
            }
        }
    }

    private func bookingForm(_ ride: Ride) -> some View {
        let driver = store.user(with: ride.driverID)
        let total = seats * ride.pricePerSeatCents
        let isBooking = store.isOperating("book-\(ride.id.uuidString)")

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    AvatarView(user: driver, size: 48)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ride.routeTitle)
                            .font(.headline)
                        Text("\(driver.name) · \(ride.departureDate.shortDateTimeText)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 16) {
                    Stepper(value: $seats, in: 1...max(1, ride.seatsAvailable)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(seats) \(seats == 1 ? "seat" : "seats")")
                                .font(.headline)
                            Text("\(ride.seatsAvailable) currently available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    HStack {
                        Text("\(ride.pricePerSeatCents.dollarsText) x \(seats)")
                        Spacer()
                        Text(total.dollarsText)
                            .font(.headline)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .foregroundStyle(Color.appTint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ride.manualApprovalEnabled ? "Payment authorization" : "Payment")
                                .font(.headline)
                            Text(ride.manualApprovalEnabled ? "Shotgun will hold a demo Stripe authorization until the driver accepts." : "Demo Stripe checkout captures payment and schedules the driver payout after the ride.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .appCard()

                PrimaryButton(
                    title: ride.manualApprovalEnabled ? "Request booking" : "Confirm booking",
                    systemImage: "checkmark.circle.fill",
                    isLoading: isBooking
                ) {
                    Task {
                        if let newBooking = await store.bookRide(rideID: ride.id, seats: seats) {
                            booking = newBooking
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct BookingConfirmationView: View {
    @EnvironmentObject private var store: AppStore
    let booking: Booking
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: booking.status == .pending ? "clock.badge.checkmark" : "checkmark.seal.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.appMint)

            VStack(spacing: 8) {
                Text(booking.status == .pending ? "Request sent" : "Seat booked")
                    .font(.title.weight(.bold))
                if let ride = store.ride(with: booking.rideID) {
                    Text("\(ride.routeTitle) · \(ride.departureDate.shortDateTimeText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                if let payment = store.payment(for: booking) {
                    Text(payment.status == .authorized ? "Payment is authorized until the driver accepts." : "Payment captured in demo mode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                PrimaryButton(title: "View My Trips", systemImage: "ticket.fill") {
                    store.selectedTab = .trips
                    onDone()
                }

                SecondaryButton(title: "Message driver", systemImage: "bubble.left.and.bubble.right.fill") {
                    store.selectedTab = .inbox
                    onDone()
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }
}

struct MyTripsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showPast = false

    private var bookings: [Booking] {
        store.bookingsForCurrentRider(includePast: showPast)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Trips", selection: $showPast) {
                    Text("Upcoming").tag(false)
                    Text("Past").tag(true)
                }
                .pickerStyle(.segmented)

                if bookings.isEmpty {
                    EmptyStateView(
                        systemImage: showPast ? "clock.arrow.circlepath" : "ticket",
                        title: showPast ? "No past rides yet" : "No upcoming rides",
                        message: showPast ? "Completed rides and review prompts will appear here." : "Book a seat from Search and it will appear here."
                    )
                } else {
                    ForEach(bookings) { booking in
                        TripBookingCard(booking: booking)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Trips")
    }
}

struct TripBookingCard: View {
    @EnvironmentObject private var store: AppStore
    let booking: Booking
    @State private var showReview = false
    @State private var showDetails = false
    private var isCanceling: Bool {
        store.isOperating("cancel-booking-\(booking.id.uuidString)")
    }

    var body: some View {
        if let ride = store.ride(with: booking.rideID) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ride.routeTitle)
                            .font(.headline)
                        Text(ride.departureDate.shortDateTimeText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: booking.status.rawValue, color: statusColor)
                }

                RouteLineView(origin: ride.origin, destination: ride.destination)

                HStack {
                    AvatarView(user: store.user(with: ride.driverID), size: 38)
                    Text(store.user(with: ride.driverID).name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(booking.seats) \(booking.seats == 1 ? "seat" : "seats")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let payment = store.payment(with: booking.paymentID) {
                    HStack {
                        Label(payment.provider.rawValue, systemImage: "creditcard.fill")
                        Spacer()
                        StatusBadge(text: payment.status.rawValue, color: payment.status.statusColor)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                }

                SecondaryButton(title: "Trip details", systemImage: "doc.text.magnifyingglass") {
                    showDetails = true
                }

                if [.pending, .confirmed].contains(booking.status) {
                    HStack(spacing: 12) {
                        SecondaryButton(title: "Message", systemImage: "message.fill") {
                            store.selectedTab = .inbox
                        }
                        SecondaryButton(title: "Cancel", systemImage: "xmark.circle.fill", isLoading: isCanceling) {
                            Task {
                                await store.cancelBooking(booking)
                            }
                        }
                    }
                } else if booking.status == .completed {
                    if store.didCurrentUserReview(booking: booking) {
                        Label("Review submitted", systemImage: "star.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appGold)
                    } else {
                        SecondaryButton(title: "Leave review", systemImage: "star.fill") {
                            showReview = true
                        }
                    }
                }
            }
            .appCard()
            .sheet(isPresented: $showReview) {
                ReviewSheetView(booking: booking)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showDetails) {
                TripDetailSheetView(booking: booking)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: .appGold
        case .confirmed: .appMint
        case .canceled: .appCoral
        case .completed: .appTint
        }
    }
}

struct TripDetailSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let booking: Booking
    @State private var showReport = false
    private var isCanceling: Bool {
        store.isOperating("cancel-booking-\(booking.id.uuidString)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let ride = store.ride(with: booking.rideID) {
                    let driver = store.user(with: ride.driverID)

                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ride.routeTitle)
                                        .font(.title3.weight(.bold))
                                    Text(ride.departureDate.shortDateTimeText)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(text: booking.status.rawValue, color: statusColor)
                            }

                            RouteLineView(origin: ride.origin, destination: ride.destination)
                        }
                        .appCard()

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Driver")
                                .font(.headline)
                            HStack(spacing: 12) {
                                AvatarView(user: driver, size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(driver.name)
                                        .font(.headline)
                                    RatingPill(rating: driver.rating, count: driver.reviewCount)
                                }
                                Spacer()
                            }
                        }
                        .appCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pickup and dropoff")
                                .font(.headline)
                            Label(ride.pickupNotes, systemImage: "mappin.and.ellipse")
                            Label(ride.dropoffNotes, systemImage: "flag.checkered")
                            Label("\(booking.seats) \(booking.seats == 1 ? "seat" : "seats") reserved", systemImage: "person.2.fill")
                        }
                        .font(.subheadline)
                        .appCard()

                        if let payment = store.payment(with: booking.paymentID) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Payment")
                                    .font(.headline)
                                HStack {
                                    Label(payment.provider.rawValue, systemImage: "creditcard.fill")
                                    Spacer()
                                    Text(payment.amountCents.dollarsText)
                                        .font(.headline)
                                }
                                StatusBadge(text: payment.status.rawValue, color: payment.status.statusColor)
                                if payment.status == .authorized {
                                    Text("The driver has not captured this payment yet.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if payment.status == .refunded || payment.status == .voided {
                                    Text(payment.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline)
                            .appCard()
                        }

                        VStack(spacing: 12) {
                            SecondaryButton(title: "Message driver", systemImage: "message.fill") {
                                store.selectedTab = .inbox
                                dismiss()
                            }

                            if [.pending, .confirmed].contains(booking.status) {
                                SecondaryButton(title: "Cancel booking", systemImage: "xmark.circle.fill", isLoading: isCanceling) {
                                    Task {
                                        await store.cancelBooking(booking)
                                        dismiss()
                                    }
                                }
                            }

                            SecondaryButton(title: "Report driver", systemImage: "exclamationmark.bubble.fill") {
                                showReport = true
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showReport) {
            if let ride = store.ride(with: booking.rideID) {
                ReportUserView(subjectID: ride.driverID, rideID: ride.id)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: .appGold
        case .confirmed: .appMint
        case .canceled: .appCoral
        case .completed: .appTint
        }
    }
}

struct DriveView: View {
    @State private var mode = DriverMode.dashboard

    var body: some View {
        VStack(spacing: 0) {
            Picker("Drive", selection: $mode) {
                ForEach(DriverMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if mode == .dashboard {
                DriverDashboardView()
            } else {
                CreateRideView()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Drive")
    }
}

enum DriverMode: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case listing = "List seats"

    var id: String { rawValue }
}

struct DriverDashboardView: View {
    @EnvironmentObject private var store: AppStore

    private var dashboardBookings: [Booking] {
        store.bookingsForDriverDashboard()
    }

    private var ownListingBookings: [Booking] {
        store.bookingsForCurrentDriverListings()
    }

    private var expectedEarnings: Int {
        ownListingBookings.reduce(0) { total, booking in
            guard [.pending, .confirmed].contains(booking.status),
                  let ride = store.ride(with: booking.rideID) else { return total }
            return total + booking.seats * ride.pricePerSeatCents
        }
    }

    private var pendingPayouts: Int {
        store.currentDriverPayoutTotal(matching: [.pending, .available])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    MetricTile(title: "Expected", value: expectedEarnings.dollarsText, systemImage: "banknote.fill", tint: .appMint)
                    MetricTile(title: "Requests", value: "\(ownListingBookings.filter { $0.status == .pending }.count)", systemImage: "person.badge.clock.fill", tint: .appGold)
                }

                HStack(spacing: 12) {
                    MetricTile(title: "Payouts", value: pendingPayouts.dollarsText, systemImage: "building.columns.fill", tint: .appTint)
                    MetricTile(title: "Captured", value: "\(ownListingBookings.compactMap { store.payment(for: $0) }.filter { $0.status == .succeeded }.count)", systemImage: "creditcard.fill", tint: .appCoral)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Active listings")
                        .font(.headline)

                    ForEach(store.activeRidesForDriverDashboard()) { ride in
                        DriverRideRow(ride: ride)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Booking activity")
                        .font(.headline)

                    if dashboardBookings.isEmpty {
                        EmptyStateView(systemImage: "person.2.slash", title: "No rider activity", message: "Requests and confirmed bookings will appear as riders book your seats.")
                    } else {
                        ForEach(dashboardBookings) { booking in
                            BookingRequestRow(booking: booking)
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 88)
        }
    }
}

struct DriverRideRow: View {
    @EnvironmentObject private var store: AppStore
    let ride: Ride
    @State private var showEdit = false
    @State private var showManifest = false
    private var isCompleting: Bool {
        store.isOperating("complete-ride-\(ride.id.uuidString)")
    }
    private var isCanceling: Bool {
        store.isOperating("cancel-ride-\(ride.id.uuidString)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.routeTitle)
                        .font(.headline)
                    Text(ride.departureDate.shortDateTimeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(text: ride.status.rawValue, color: ride.status == .active ? .appMint : .appGold)
            }

            HStack {
                Label("\(ride.seatsAvailable)/\(ride.totalSeats) open", systemImage: "person.2")
                Spacer()
                Label((ride.totalSeats - ride.seatsAvailable).description, systemImage: "ticket.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                SecondaryButton(title: "Manifest", systemImage: "list.bullet.clipboard") {
                    showManifest = true
                }
                SecondaryButton(title: "Edit", systemImage: "slider.horizontal.3") {
                    showEdit = true
                }
            }

            HStack(spacing: 12) {
                if ride.status == .active || ride.status == .soldOut {
                    SecondaryButton(title: "Complete", systemImage: "checkmark.seal", isLoading: isCompleting) {
                        Task {
                            await store.completeRide(ride)
                        }
                    }
                }
            }

            if ride.status == .active || ride.status == .soldOut {
                SecondaryButton(title: "Cancel listing", systemImage: "xmark.circle", isLoading: isCanceling) {
                    Task {
                        await store.cancelRide(ride)
                    }
                }
            }
        }
        .appCard()
        .sheet(isPresented: $showEdit) {
            EditRideView(ride: ride, vehicle: store.vehicle(with: ride.vehicleID))
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showManifest) {
            DriverManifestView(rideID: ride.id)
                .presentationDetents([.medium, .large])
        }
    }
}

struct DriverManifestView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let rideID: UUID

    private var bookings: [Booking] {
        store.bookings(forRide: rideID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let ride = store.ride(with: rideID) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(ride.routeTitle)
                                .font(.title3.weight(.bold))
                            Text(ride.departureDate.shortDateTimeText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                MetricTile(title: "Booked", value: "\(ride.totalSeats - ride.seatsAvailable)", systemImage: "ticket.fill", tint: .appTint)
                                MetricTile(title: "Open", value: "\(ride.seatsAvailable)", systemImage: "person.2", tint: .appMint)
                            }
                        }
                        .appCard()
                    }

                    if bookings.isEmpty {
                        EmptyStateView(systemImage: "person.crop.circle.badge.questionmark", title: "No riders yet", message: "Confirmed and pending riders will appear here.")
                    } else {
                        ForEach(bookings) { booking in
                            ManifestRiderRow(booking: booking)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Manifest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ManifestRiderRow: View {
    @EnvironmentObject private var store: AppStore
    let booking: Booking
    @State private var showReview = false
    private var isAccepting: Bool {
        store.isOperating("accept-booking-\(booking.id.uuidString)")
    }
    private var isDeclining: Bool {
        store.isOperating("cancel-booking-\(booking.id.uuidString)")
    }

    var body: some View {
        let rider = store.user(with: booking.riderID)

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AvatarView(user: rider, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(rider.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        RatingPill(rating: rider.rating, count: rider.reviewCount)
                        StatusBadge(text: booking.status.rawValue, color: statusColor)
                    }
                }
                Spacer()
            }

            HStack {
                Label("\(booking.seats) \(booking.seats == 1 ? "seat" : "seats")", systemImage: "person.2.fill")
                Spacer()
                if let payment = store.payment(with: booking.paymentID) {
                    Label(payment.status.rawValue.capitalized, systemImage: "creditcard.fill")
                        .foregroundStyle(payment.status.statusColor)
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)

            if let payout = store.driverPayout(for: booking.id) {
                Label("\(payout.status.rawValue) payout · \(payout.amountCents.dollarsText)", systemImage: "building.columns.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(payout.status.statusColor)
            }

            HStack(spacing: 12) {
                SecondaryButton(title: "Message", systemImage: "message.fill") {
                    store.selectedTab = .inbox
                }

                if booking.status == .pending {
                    SecondaryButton(title: "Decline", systemImage: "xmark.circle.fill", isLoading: isDeclining) {
                        Task {
                            await store.decline(booking)
                        }
                    }
                    PrimaryButton(title: "Accept", systemImage: "checkmark.circle.fill", isLoading: isAccepting) {
                        Task {
                            await store.accept(booking)
                        }
                    }
                } else if booking.status == .completed && !store.didCurrentUserReview(booking: booking, subjectID: rider.id) {
                    SecondaryButton(title: "Review", systemImage: "star.fill") {
                        showReview = true
                    }
                }
            }
        }
        .appCard()
        .sheet(isPresented: $showReview) {
            ReviewSheetView(booking: booking, subjectID: rider.id)
                .presentationDetents([.medium, .large])
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: .appGold
        case .confirmed: .appMint
        case .canceled: .appCoral
        case .completed: .appTint
        }
    }
}

struct BookingRequestRow: View {
    @EnvironmentObject private var store: AppStore
    let booking: Booking
    @State private var showRiderReview = false
    private var isAccepting: Bool {
        store.isOperating("accept-booking-\(booking.id.uuidString)")
    }
    private var isDeclining: Bool {
        store.isOperating("cancel-booking-\(booking.id.uuidString)")
    }

    var body: some View {
        if let ride = store.ride(with: booking.rideID) {
            let rider = store.user(with: booking.riderID)
            let driver = store.user(with: ride.driverID)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    AvatarView(user: rider, size: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rider.name)
                            .font(.headline)
                        Text("\(booking.seats) \(booking.seats == 1 ? "seat" : "seats") on \(ride.routeTitle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: booking.status.rawValue, color: statusColor)
                }

                Text("For \(driver.name)'s listing · \(ride.departureDate.shortDateTimeText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let payment = store.payment(for: booking) {
                    HStack {
                        Label(payment.status.rawValue.capitalized, systemImage: "creditcard.fill")
                            .foregroundStyle(payment.status.statusColor)
                        Spacer()
                        if let payout = store.driverPayout(for: booking.id) {
                            Label(payout.status.rawValue, systemImage: "building.columns.fill")
                                .foregroundStyle(payout.status.statusColor)
                        }
                    }
                    .font(.caption.weight(.semibold))
                }

                if booking.status == .pending {
                    HStack(spacing: 12) {
                        SecondaryButton(title: "Decline", systemImage: "xmark.circle.fill", isLoading: isDeclining) {
                            Task {
                                await store.decline(booking)
                            }
                        }
                        PrimaryButton(title: "Accept", systemImage: "checkmark.circle.fill", isLoading: isAccepting) {
                            Task {
                                await store.accept(booking)
                            }
                        }
                    }
                } else if booking.status == .completed && ride.driverID == store.currentUser?.id {
                    if store.didCurrentUserReview(booking: booking, subjectID: rider.id) {
                        Label("Rider reviewed", systemImage: "star.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appGold)
                    } else {
                        SecondaryButton(title: "Review rider", systemImage: "star.fill") {
                            showRiderReview = true
                        }
                    }
                }
            }
            .appCard()
            .sheet(isPresented: $showRiderReview) {
                ReviewSheetView(booking: booking, subjectID: rider.id)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: .appGold
        case .confirmed: .appMint
        case .canceled: .appCoral
        case .completed: .appTint
        }
    }
}

struct CreateRideView: View {
    @EnvironmentObject private var store: AppStore
    @State private var origin = "New York, NY"
    @State private var destination = "Providence, RI"
    @State private var departureDate = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
    @State private var pickupNotes = "Meet near a transit stop with room to pull over."
    @State private var dropoffNotes = "Central dropoff, flexible within 10 minutes."
    @State private var seats = 2
    @State private var price = 38
    @State private var make = "Toyota"
    @State private var model = "RAV4"
    @State private var color = "Black"
    @State private var luggageAllowance = LuggageAllowance.carryOn
    @State private var preferences: Set<RidePreference> = [.noSmoking, .musicOkay]
    @State private var manualApproval = true
    @State private var showPublished = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                routeSection
                detailsSection
                carSection
                preferencesSection

                PrimaryButton(title: "Publish listing", systemImage: "plus.circle.fill") {
                    publishRide()
                }

                if showPublished {
                    Label("Listing published in Driver Dashboard.", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appMint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
            .padding(20)
        }
    }

    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route")
                .font(.headline)
            CityTextField(title: "Origin", text: $origin, cities: store.cities)
            CityTextField(title: "Destination", text: $destination, cities: store.cities)
            DatePicker("Departure", selection: $departureDate)
                .datePickerStyle(.compact)
        }
        .appCard()
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seats and pickup")
                .font(.headline)

            Stepper(value: $seats, in: 1...6) {
                Label("\(seats) seats available", systemImage: "person.2.fill")
                    .font(.subheadline.weight(.semibold))
            }

            Stepper(value: $price, in: 10...120, step: 2) {
                Label("$\(price) per seat", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }

            TextField("Pickup notes", text: $pickupNotes, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            TextField("Dropoff notes", text: $dropoffNotes, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            Picker("Luggage", selection: $luggageAllowance) {
                ForEach(LuggageAllowance.allCases) { allowance in
                    Text(allowance.rawValue).tag(allowance)
                }
            }
        }
        .appCard()
    }

    private var carSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Car")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("Make", text: $make)
                    .textFieldStyle(.roundedBorder)
                TextField("Model", text: $model)
                    .textFieldStyle(.roundedBorder)
            }

            TextField("Color", text: $color)
                .textFieldStyle(.roundedBorder)
        }
        .appCard()
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preferences")
                .font(.headline)

            ForEach(RidePreference.allCases) { preference in
                Toggle(isOn: binding(for: preference)) {
                    Label(preference.rawValue, systemImage: preference.symbolName)
                }
            }

            Toggle(isOn: $manualApproval) {
                Label("Approve riders manually", systemImage: "hand.raised.fill")
            }
        }
        .appCard()
    }

    private func binding(for preference: RidePreference) -> Binding<Bool> {
        Binding {
            preferences.contains(preference)
        } set: { isOn in
            if isOn {
                preferences.insert(preference)
            } else {
                preferences.remove(preference)
            }
        }
    }

    private func publishRide() {
        guard let currentUser = store.currentUser else { return }
        let vehicle = Vehicle(
            id: UUID(),
            ownerID: currentUser.id,
            make: make,
            model: model,
            color: color,
            year: 2022,
            plateState: "NY"
        )

        store.createRide(
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            pickupNotes: pickupNotes,
            dropoffNotes: dropoffNotes,
            seats: seats,
            pricePerSeatCents: price * 100,
            vehicle: vehicle,
            luggageAllowance: luggageAllowance,
            preferences: preferences,
            manualApprovalEnabled: manualApproval
        )

        showPublished = true
    }
}

struct MessagesView: View {
    @EnvironmentObject private var store: AppStore

    private var conversations: [Conversation] {
        store.conversationsForCurrentUser()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if conversations.isEmpty {
                    EmptyStateView(systemImage: "bubble.left.and.bubble.right", title: "No messages yet", message: "After booking, your ride conversation will show up here.")
                        .padding(.top, 20)
                } else {
                    ForEach(conversations) { conversation in
                        NavigationLink {
                            ConversationDetailView(conversationID: conversation.id)
                        } label: {
                            ConversationRow(conversation: conversation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Messages")
    }
}

struct ConversationRow: View {
    @EnvironmentObject private var store: AppStore
    let conversation: Conversation

    var body: some View {
        let other = otherUser

        HStack(spacing: 12) {
            AvatarView(user: other, size: 48)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(other.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.lastUpdated.timeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(store.ride(with: conversation.rideID)?.routeTitle ?? "Ride")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTint)

                Text(store.lastMessage(for: conversation)?.body ?? "No messages yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .appCard()
    }

    private var otherUser: AppUser {
        let currentID = store.currentUser?.id
        let otherID = conversation.participantIDs.first { $0 != currentID } ?? conversation.participantIDs.first
        return store.user(with: otherID ?? SeedData.currentUserID)
    }
}

struct ConversationDetailView: View {
    @EnvironmentObject private var store: AppStore
    let conversationID: UUID
    @State private var draft = ""

    private var conversation: Conversation? {
        store.conversations.first(where: { $0.id == conversationID })
    }

    var body: some View {
        VStack(spacing: 0) {
            if let conversation {
                ScrollView {
                    VStack(spacing: 10) {
                        if let ride = store.ride(with: conversation.rideID) {
                            Text(ride.routeTitle)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 10)
                        }

                        ForEach(store.conversationMessages(conversation.id)) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(16)
                }
            }

            HStack(spacing: 10) {
                TextField("Message", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    store.sendMessage(conversationID: conversationID, text: draft)
                    draft = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(.bar)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(conversation.map { otherUser(for: $0).name } ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func otherUser(for conversation: Conversation) -> AppUser {
        let currentID = store.currentUser?.id
        let otherID = conversation.participantIDs.first { $0 != currentID } ?? conversation.participantIDs.first
        return store.user(with: otherID ?? SeedData.currentUserID)
    }
}

struct MessageBubble: View {
    @EnvironmentObject private var store: AppStore
    let message: Message

    private var isMine: Bool {
        message.senderID == store.currentUser?.id
    }

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 48) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(isMine ? .white : .primary)
                    .background(isMine ? Color.appTint : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(message.sentAt.timeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !isMine { Spacer(minLength: 48) }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showEditProfile = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let user = store.currentUser {
                    profileHeader(user)
                    verificationCard(user)
                    reviewsCard(user)
                }

                NavigationLink {
                    SafetyTrustView()
                } label: {
                    Label("Safety and trust", systemImage: "shield.lefthalf.filled")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .compactCard()
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .compactCard()
                }
                .buttonStyle(.plain)

                SecondaryButton(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right") {
                    store.signOut()
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditProfile = true
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let user = store.currentUser {
                ProfileEditorView(user: user)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func profileHeader(_ user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AvatarView(user: user, size: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.name)
                        .font(.title2.weight(.bold))
                    RatingPill(rating: user.rating, count: user.reviewCount)
                }
                Spacer()
            }

            Text(user.bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                MetricTile(title: "Rider", value: "Active", systemImage: "figure.walk", tint: .appTint)
                MetricTile(title: "Driver", value: "Ready", systemImage: "steeringwheel", tint: .appMint)
            }
        }
        .appCard()
    }

    private func verificationCard(_ user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification")
                .font(.headline)
            Label(user.isVerified ? "Identity verified" : "Identity pending", systemImage: user.isVerified ? "checkmark.seal.fill" : "clock")
            Label(user.phoneVerified ? "Phone verified" : "Phone pending", systemImage: user.phoneVerified ? "phone.fill.badge.checkmark" : "phone")
            Label(user.phoneNumber, systemImage: "lock.fill")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.weight(.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func reviewsCard(_ user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews")
                .font(.headline)

            let userReviews = store.reviews(for: user.id)
            if userReviews.isEmpty {
                Text("Reviews will appear after completed rides.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(userReviews.prefix(3)) { review in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(String(repeating: "★", count: review.rating))
                            .foregroundStyle(Color.appGold)
                        Text(review.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .compactCard()
                }
            }
        }
        .appCard()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue
    @AppStorage("manualApprovalDefault") private var requireApproval = true
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $appearancePreference) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.rawValue).tag(preference.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Infrastructure") {
                Label(store.configuration.backendProvider, systemImage: "server.rack")
                Label(store.configuration.paymentProvider, systemImage: "creditcard.and.123")
                HStack {
                    Label("Sync status", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    StatusBadge(text: store.syncState.rawValue, color: store.syncState.statusColor)
                }
                HStack {
                    Label("Last saved", systemImage: "clock.badge.checkmark")
                    Spacer()
                    Text(store.lastSyncedAt?.shortDateTimeText ?? "Not yet")
                        .foregroundStyle(.secondary)
                }
                Label("API \(store.configuration.apiVersion) contract", systemImage: "point.3.connected.trianglepath.dotted")
            }

            Section("Account") {
                NavigationLink {
                    NotificationPreferencesView()
                } label: {
                    Label("Notification center", systemImage: "bell.and.waves.left.and.right.fill")
                }
                Toggle("Ride notifications", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { isEnabled in
                        Task { await store.setRideNotificationsEnabled(isEnabled) }
                    }
                ))
                Toggle("Pickup reminders", isOn: Binding(
                    get: { store.pickupReminderNotificationsEnabled },
                    set: { isEnabled in
                        Task { await store.setPickupReminderNotificationsEnabled(isEnabled) }
                    }
                ))
                .disabled(!store.notificationsEnabled)
                HStack {
                    Label("Notification access", systemImage: "bell.badge.fill")
                    Spacer()
                    StatusBadge(text: store.notificationPermission.rawValue, color: store.notificationPermission.statusColor)
                }
                if let notificationError = store.notificationErrorMessage {
                    Text(notificationError)
                        .font(.caption)
                        .foregroundStyle(Color.appCoral)
                }
                NavigationLink {
                    VerificationCenterView()
                } label: {
                    Label("Verification center", systemImage: "checkmark.seal.fill")
                }
                NavigationLink {
                    PaymentMethodsView()
                } label: {
                    Label("Payment methods", systemImage: "creditcard.fill")
                }
            }

            Section("Driving") {
                Toggle("Manual approval by default", isOn: $requireApproval)
                NavigationLink {
                    PayoutSetupView()
                } label: {
                    Label("Payout setup", systemImage: "banknote.fill")
                }
                Label("Sign in with Apple account", systemImage: "apple.logo")
            }

            Section("Support") {
                NavigationLink {
                    SupportCenterView()
                } label: {
                    Label("Report a problem", systemImage: "exclamationmark.bubble")
                }
                NavigationLink {
                    LegalPrivacyView()
                } label: {
                    Label("Legal and privacy", systemImage: "doc.text")
                }
            }

            Section("Local data") {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset local demo data", systemImage: "arrow.counterclockwise.circle.fill")
                }
            }
        }
        .navigationTitle("Settings")
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 44)
        }
        .task {
            await store.refreshNotificationPermission()
        }
        .alert("Reset local demo data?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                store.resetLocalData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears saved rides, bookings, messages, profile edits, and local setup data on this device.")
        }
    }
}

struct NotificationPreferencesView: View {
    @EnvironmentObject private var store: AppStore

    private var scheduledNotifications: [ScheduledRideNotification] {
        store.scheduledNotifications.sorted { $0.deliveryDate < $1.deliveryDate }
    }

    var body: some View {
        List {
            Section("Access") {
                HStack {
                    Label("iOS permission", systemImage: "bell.badge.fill")
                    Spacer()
                    StatusBadge(text: store.notificationPermission.rawValue, color: store.notificationPermission.statusColor)
                }

                Button {
                    Task {
                        await store.setRideNotificationsEnabled(true)
                    }
                } label: {
                    Label("Request notification access", systemImage: "checkmark.seal.fill")
                }
            }

            Section("Trip updates") {
                Toggle("Booking updates", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { isEnabled in
                        Task { await store.setRideNotificationsEnabled(isEnabled) }
                    }
                ))

                Toggle("Pickup reminders", isOn: Binding(
                    get: { store.pickupReminderNotificationsEnabled },
                    set: { isEnabled in
                        Task { await store.setPickupReminderNotificationsEnabled(isEnabled) }
                    }
                ))
                .disabled(!store.notificationsEnabled)

                if let notificationError = store.notificationErrorMessage {
                    Text(notificationError)
                        .font(.caption)
                        .foregroundStyle(Color.appCoral)
                }
            }

            Section("Scheduled") {
                if scheduledNotifications.isEmpty {
                    Label("No scheduled ride reminders yet", systemImage: "bell.slash.fill")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scheduledNotifications) { notification in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(notification.title)
                                    .font(.headline)
                                Spacer()
                                StatusBadge(text: notification.kind.rawValue, color: .appTint)
                            }
                            Text(notification.body)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Label(notification.deliveryDate.shortDateTimeText, systemImage: "clock.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appGold)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !scheduledNotifications.isEmpty {
                Section {
                    Button(role: .destructive) {
                        store.clearScheduledNotifications()
                    } label: {
                        Label("Clear scheduled notifications", systemImage: "trash.fill")
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 44)
        }
        .task {
            await store.refreshNotificationPermission()
        }
    }
}

struct VerificationCenterView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            if let user = store.currentUser {
                Section {
                    verificationRow(title: "Identity", subtitle: user.isVerified ? "Verified" : "Needs review", symbol: "person.text.rectangle.fill", complete: user.isVerified)
                    verificationRow(title: "Phone", subtitle: user.phoneVerified ? user.phoneNumber : "Add a phone number", symbol: "phone.fill", complete: user.phoneVerified)
                    verificationRow(title: "Driver profile", subtitle: "Vehicle and payout details on file", symbol: "car.fill", complete: true)
                }

                Section("Profile preview") {
                    HStack(spacing: 12) {
                        AvatarView(user: user, size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            RatingPill(rating: user.rating, count: user.reviewCount)
                        }
                    }
                }
            }
        }
        .navigationTitle("Verification")
    }

    private func verificationRow(title: String, subtitle: String, symbol: String, complete: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(complete ? Color.appMint : Color.appGold)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: complete ? "checkmark.circle.fill" : "clock.fill")
                .foregroundStyle(complete ? Color.appMint : Color.appGold)
        }
    }
}

struct PaymentMethodsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAddMethod = false

    var body: some View {
        List {
            Section {
                Label("Stripe Connect checkout is represented locally for this build.", systemImage: "creditcard.and.123")
                Label("Apple Pay can be offered through Stripe once merchant credentials are ready.", systemImage: "apple.logo")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Section {
                ForEach(store.paymentMethods) { method in
                    HStack(spacing: 12) {
                        Image(systemName: method.kind.symbolName)
                            .foregroundStyle(Color.appTint)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(method.label)
                                .font(.headline)
                            Text(method.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if method.isDefault {
                            StatusBadge(text: "Default", color: .appMint)
                        } else {
                            Button("Make default") {
                                store.makeDefaultPaymentMethod(method)
                            }
                            .font(.caption.weight(.bold))
                        }
                    }
                }
            }

            Section {
                Button {
                    showAddMethod = true
                } label: {
                    Label("Add payment method", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Payments")
        .sheet(isPresented: $showAddMethod) {
            AddPaymentMethodView()
                .presentationDetents([.medium])
        }
    }
}

struct AddPaymentMethodView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind = PaymentMethodKind.card
    @State private var label = "Mastercard"
    @State private var detail = "Ending in 1888"

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(PaymentMethodKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                TextField("Label", text: $label)
                TextField("Detail", text: $detail)

                Button("Add method") {
                    store.addPaymentMethod(kind: kind, label: label, detail: detail)
                    dismiss()
                }
                .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("Add Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PayoutSetupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var bankName = ""
    @State private var lastFour = ""
    @State private var instantPayouts = false

    var body: some View {
        Form {
            Section {
                Label("Stripe Connect onboarding placeholder", systemImage: "building.columns.fill")
                Label("Driver payouts are tracked locally until a live backend is connected.", systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Section("Current account") {
                HStack {
                    Label(store.payoutAccount.bankName, systemImage: "building.columns.fill")
                    Spacer()
                    Text("•••• \(store.payoutAccount.lastFour)")
                        .foregroundStyle(.secondary)
                }
                Toggle("Instant payouts", isOn: $instantPayouts)
                StatusBadge(text: store.payoutAccount.isVerified ? "Verified" : "Pending", color: store.payoutAccount.isVerified ? .appMint : .appGold)
            }

            Section("Update") {
                TextField("Bank name", text: $bankName)
                TextField("Last 4 digits", text: $lastFour)
                    .keyboardType(.numberPad)
                Button("Save payout account") {
                    store.updatePayoutAccount(bankName: bankName, lastFour: lastFour, instantPayoutsEnabled: instantPayouts)
                }
                .disabled(bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || lastFour.count < 4)
            }

            if !store.currentDriverPayouts().isEmpty {
                Section("Payout activity") {
                    ForEach(store.currentDriverPayouts()) { payout in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(payout.amountCents.dollarsText)
                                    .font(.headline)
                                Text("Available \(payout.availableOn.shortDateTimeText)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(text: payout.status.rawValue, color: payout.status.statusColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Payouts")
        .onAppear {
            bankName = store.payoutAccount.bankName
            lastFour = store.payoutAccount.lastFour
            instantPayouts = store.payoutAccount.instantPayoutsEnabled
        }
    }
}

struct SupportCenterView: View {
    @EnvironmentObject private var store: AppStore
    @State private var type = SupportIssueType.booking
    @State private var title = "Question about a ride"
    @State private var details = ""

    var body: some View {
        Form {
            Section("New request") {
                Picker("Type", selection: $type) {
                    ForEach(SupportIssueType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                TextField("Title", text: $title)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(4...7)
                Button("Submit support request") {
                    store.submitSupportTicket(type: type, title: title, details: details)
                    details = ""
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !store.supportTickets.isEmpty {
                Section("Recent") {
                    ForEach(store.supportTickets) { ticket in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ticket.title)
                                .font(.headline)
                            Text("\(ticket.type.rawValue) · \(ticket.createdAt.shortDateTimeText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Support")
    }
}

struct LegalPrivacyView: View {
    var body: some View {
        List {
            Section("Privacy") {
                Label("Location is used only for pickup and dropoff context.", systemImage: "location.fill")
                Label("Payment details are represented by provider tokens.", systemImage: "creditcard.fill")
                Label("Reports and safety events are reviewed by support.", systemImage: "shield.fill")
            }

            Section("Marketplace terms") {
                Label("Drivers control listings, seats, price, and approval mode.", systemImage: "steeringwheel")
                Label("Riders can cancel before departure while seats remain tracked.", systemImage: "ticket.fill")
                Label("Completed trips unlock mutual reviews.", systemImage: "star.fill")
            }
        }
        .navigationTitle("Legal")
    }
}

struct SafetyTrustView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showReport = false
    @State private var reportSubmitted = false
    @State private var showAddContact = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Trust basics", systemImage: "shield.checkered")
                        .font(.title3.weight(.bold))
                    Text("Verify your phone, review rider profiles, confirm pickup details in chat, and share your live trip details with someone you trust.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .appCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Safety tips")
                        .font(.headline)
                    safetyRow("Meet in visible, public pickup spots.", "mappin.and.ellipse")
                    safetyRow("Match the car details before getting in.", "car.side.fill")
                    safetyRow("Keep conversation in the app before pickup.", "bubble.left.and.bubble.right.fill")
                    safetyRow("Use Report User if something feels off.", "exclamationmark.shield.fill")
                }
                .appCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Emergency")
                        .font(.headline)
                    Label("Call local emergency services if you are in immediate danger.", systemImage: "phone.fill")
                    Label("Add emergency contacts and share live trip details before pickup.", systemImage: "location.fill")
                }
                .font(.subheadline)
                .appCard()

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Emergency contacts")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAddContact = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }

                    if store.emergencyContacts.isEmpty {
                        Text("Add a contact to share trip details before pickup.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.emergencyContacts) { contact in
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundStyle(Color.appTint)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(contact.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(contact.relationship) · \(contact.phoneNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    store.removeEmergencyContact(contact)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Color.appCoral)
                                }
                            }
                        }
                    }
                }
                .appCard()

                if reportSubmitted {
                    Label("Report submitted for review", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appMint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 6)
                }

                PrimaryButton(title: "Report user", systemImage: "exclamationmark.bubble.fill") {
                    showReport = true
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Safety")
        .sheet(isPresented: $showReport) {
            ReportUserView(subjectID: nil, rideID: nil) {
                reportSubmitted = true
            }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddContact) {
            AddEmergencyContactView()
                .presentationDetents([.medium])
        }
    }

    private func safetyRow(_ text: String, _ symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(.primary)
    }
}

struct AddEmergencyContactView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = "Friend"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Relationship", text: $relationship)

                Button("Add contact") {
                    store.addEmergencyContact(name: name, phoneNumber: phone, relationship: relationship)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ReviewSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let booking: Booking
    let subjectID: UUID?
    @State private var rating = 5
    @State private var reviewBody = "Smooth ride and easy coordination."

    init(booking: Booking, subjectID: UUID? = nil) {
        self.booking = booking
        self.subjectID = subjectID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let ride = store.ride(with: booking.rideID) {
                        let subject = store.user(with: subjectID ?? ride.driverID)

                        HStack(spacing: 12) {
                            AvatarView(user: subject, size: 52)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Review \(subject.firstName)")
                                    .font(.title3.weight(.bold))
                                Text(ride.routeTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .appCard()
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Rating")
                            .font(.headline)
                        StarRatingControl(rating: $rating)
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Written review")
                            .font(.headline)
                        TextField("Share what went well", text: $reviewBody, axis: .vertical)
                            .lineLimit(4...7)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appCard()

                    PrimaryButton(title: "Submit review", systemImage: "star.circle.fill", isDisabled: reviewBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        store.submitReview(booking: booking, subjectID: subjectID, rating: rating, body: reviewBody)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Leave Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ReportUserView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let subjectID: UUID?
    let rideID: UUID?
    var onSubmitted: () -> Void = {}
    @State private var reason = ReportReason.unsafeBehavior
    @State private var details = ""
    @State private var isEmergency = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Report a concern", systemImage: "exclamationmark.shield.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appCoral)
                        Text("Share what happened so the support team can review the ride, profile, or conversation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Reason", selection: $reason) {
                            ForEach(ReportReason.allCases) { reason in
                                Text(reason.rawValue).tag(reason)
                            }
                        }

                        Toggle(isOn: $isEmergency) {
                            Label("This needs urgent attention", systemImage: "phone.fill")
                        }

                        TextField("Add details", text: $details, axis: .vertical)
                            .lineLimit(5...8)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appCard()

                    PrimaryButton(title: "Submit report", systemImage: "paperplane.fill", isDisabled: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        store.submitReport(subjectID: subjectID, rideID: rideID, reason: reason, details: details, isEmergency: isEmergency)
                        onSubmitted()
                        dismiss()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ProfileEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var bio: String

    init(user: AppUser) {
        _name = State(initialValue: user.name)
        _phone = State(initialValue: user.phoneNumber)
        _bio = State(initialValue: user.bio)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Public profile")
                            .font(.headline)
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                            .textFieldStyle(.roundedBorder)
                        TextField("Bio", text: $bio, axis: .vertical)
                            .lineLimit(4...7)
                            .textFieldStyle(.roundedBorder)
                    }
                    .appCard()

                    PrimaryButton(title: "Save profile", systemImage: "checkmark.circle.fill", isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        store.updateCurrentUserProfile(name: name, phoneNumber: phone, bio: bio)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct EditRideView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    private let rideID: UUID
    private let vehicleID: UUID
    private let ownerID: UUID
    @State private var origin: String
    @State private var destination: String
    @State private var departureDate: Date
    @State private var pickupNotes: String
    @State private var dropoffNotes: String
    @State private var seats: Int
    @State private var price: Int
    @State private var make: String
    @State private var model: String
    @State private var color: String
    @State private var year: Int
    @State private var plateState: String
    @State private var luggageAllowance: LuggageAllowance
    @State private var preferences: Set<RidePreference>
    @State private var manualApproval: Bool

    init(ride: Ride, vehicle: Vehicle) {
        rideID = ride.id
        vehicleID = vehicle.id
        ownerID = vehicle.ownerID
        _origin = State(initialValue: ride.origin)
        _destination = State(initialValue: ride.destination)
        _departureDate = State(initialValue: ride.departureDate)
        _pickupNotes = State(initialValue: ride.pickupNotes)
        _dropoffNotes = State(initialValue: ride.dropoffNotes)
        _seats = State(initialValue: ride.totalSeats)
        _price = State(initialValue: ride.pricePerSeatCents / 100)
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _color = State(initialValue: vehicle.color)
        _year = State(initialValue: vehicle.year)
        _plateState = State(initialValue: vehicle.plateState)
        _luggageAllowance = State(initialValue: ride.luggageAllowance)
        _preferences = State(initialValue: ride.preferences)
        _manualApproval = State(initialValue: ride.manualApprovalEnabled)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Route")
                            .font(.headline)
                        CityTextField(title: "Origin", text: $origin, cities: store.cities)
                        CityTextField(title: "Destination", text: $destination, cities: store.cities)
                        DatePicker("Departure", selection: $departureDate)
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Listing")
                            .font(.headline)
                        Stepper(value: $seats, in: 1...6) {
                            Label("\(seats) total seats", systemImage: "person.2.fill")
                        }
                        Stepper(value: $price, in: 10...140, step: 2) {
                            Label("$\(price) per seat", systemImage: "dollarsign.circle.fill")
                        }
                        TextField("Pickup notes", text: $pickupNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        TextField("Dropoff notes", text: $dropoffNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        Picker("Luggage", selection: $luggageAllowance) {
                            ForEach(LuggageAllowance.allCases) { allowance in
                                Text(allowance.rawValue).tag(allowance)
                            }
                        }
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Car")
                            .font(.headline)
                        HStack(spacing: 12) {
                            TextField("Make", text: $make)
                                .textFieldStyle(.roundedBorder)
                            TextField("Model", text: $model)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack(spacing: 12) {
                            TextField("Color", text: $color)
                                .textFieldStyle(.roundedBorder)
                            TextField("Plate state", text: $plateState)
                                .textInputAutocapitalization(.characters)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Preferences")
                            .font(.headline)
                        ForEach(RidePreference.allCases) { preference in
                            Toggle(isOn: binding(for: preference)) {
                                Label(preference.rawValue, systemImage: preference.symbolName)
                            }
                        }
                        Toggle(isOn: $manualApproval) {
                            Label("Approve riders manually", systemImage: "hand.raised.fill")
                        }
                    }
                    .appCard()

                    PrimaryButton(title: "Save listing", systemImage: "checkmark.circle.fill") {
                        save()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func binding(for preference: RidePreference) -> Binding<Bool> {
        Binding {
            preferences.contains(preference)
        } set: { isOn in
            if isOn {
                preferences.insert(preference)
            } else {
                preferences.remove(preference)
            }
        }
    }

    private func save() {
        let vehicle = Vehicle(
            id: vehicleID,
            ownerID: ownerID,
            make: make,
            model: model,
            color: color,
            year: year,
            plateState: plateState
        )

        store.updateRide(
            rideID: rideID,
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            pickupNotes: pickupNotes,
            dropoffNotes: dropoffNotes,
            totalSeats: seats,
            pricePerSeatCents: price * 100,
            vehicle: vehicle,
            luggageAllowance: luggageAllowance,
            preferences: preferences,
            manualApprovalEnabled: manualApproval
        )
        dismiss()
    }
}

struct StarRatingControl: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = value
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.appGold)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
