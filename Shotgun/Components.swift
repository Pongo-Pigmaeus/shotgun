import SwiftUI

struct AvatarView: View {
    let user: AppUser
    var size: CGFloat = 48

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.appTint.opacity(0.95), .appMint.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: user.profileSymbolName)
                        .font(.system(size: size * 0.45, weight: .semibold))
                        .foregroundStyle(.white)
                }

            if user.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: size * 0.28))
                    .foregroundStyle(.white, Color.appMint)
                    .background(Circle().fill(Color(.systemBackground)))
                    .offset(x: size * 0.05, y: size * 0.05)
            }
        }
        .accessibilityLabel(user.name)
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String = "arrow.right"
    var isDisabled = false
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: systemImage)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                AppTheme.routeGradient,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .opacity(isDisabled || isLoading ? 0.55 : 1)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    var title: String
    var systemImage: String
    var isDisabled = false
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(Color.appTint)
                } else {
                    Image(systemName: systemImage)
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(Color.appTint)
            .background(Color.appTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isDisabled || isLoading ? 0.55 : 1)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(.plain)
    }
}

struct RatingPill: View {
    var rating: Double
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appGold)
            Text(rating.formatted(.number.precision(.fractionLength(2))))
                .font(.subheadline.weight(.semibold))
            if let count {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}

struct StatusBadge: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text.capitalized)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.13), in: Capsule())
    }
}

struct PreferenceBadge: View {
    let preference: RidePreference

    var body: some View {
        Label(preference.rawValue, systemImage: preference.symbolName)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.appTint)
                .frame(width: 76, height: 76)
                .background(Color.appTint.opacity(0.12), in: Circle())
            Text(title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .appCard()
    }
}

struct RouteLineView: View {
    var origin: String
    var destination: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(origin.shortCity)
                    .font(.headline)
                    .lineLimit(1)
                Text("Pickup")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.appMint)
                    .frame(width: 9, height: 9)
                Rectangle()
                    .fill(Color.primary.opacity(0.16))
                    .frame(height: 2)
                Image(systemName: "car.fill")
                    .font(.caption)
                    .foregroundStyle(Color.appTint)
                Rectangle()
                    .fill(Color.primary.opacity(0.16))
                    .frame(height: 2)
                Circle()
                    .fill(Color.appCoral)
                    .frame(width: 9, height: 9)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 5) {
                Text(destination.shortCity)
                    .font(.headline)
                    .lineLimit(1)
                Text("Dropoff")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RideCard: View {
    @EnvironmentObject private var store: AppStore
    let ride: Ride

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                AvatarView(user: driver, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(driver.name)
                            .font(.headline)
                            .lineLimit(1)
                        if driver.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.appMint)
                        }
                    }
                    HStack(spacing: 8) {
                        RatingPill(rating: driver.rating)
                        Text(vehicle.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ride.pricePerSeatCents.dollarsText)
                        .font(.title3.weight(.bold))
                    Text("per seat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            RouteLineView(origin: ride.origin, destination: ride.destination)

            HStack(spacing: 12) {
                Label(ride.departureDate.shortDateTimeText, systemImage: "clock")
                Label("\(ride.seatsAvailable) seats", systemImage: "person.2")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 7) {
                Label(ride.pickupNotes, systemImage: "mappin.and.ellipse")
                Label(ride.dropoffNotes, systemImage: "flag.checkered")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        .appCard()
    }

    private var driver: AppUser {
        store.user(with: ride.driverID)
    }

    private var vehicle: Vehicle {
        store.vehicle(with: ride.vehicleID)
    }
}

struct MetricTile: View {
    var title: String
    var value: String
    var systemImage: String
    var tint: Color = .appTint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .compactCard()
    }
}

struct CityTextField: View {
    var title: String
    @Binding var text: String
    var cities: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            TextField(title, text: $text)
                .textInputAutocapitalization(.words)
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cities.filter { $0.searchKey.contains(text.searchKey) || text.isEmpty }.prefix(5), id: \.self) { city in
                        Button {
                            text = city
                        } label: {
                            Text(city.shortCity)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.appTint.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
