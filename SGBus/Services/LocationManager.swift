import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    static let singaporeCenter = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)

    private static let lastLatKey = "LocationManager.lastLatitude"
    private static let lastLngKey = "LocationManager.lastLongitude"

    override init() {
        self.authorizationStatus = manager.authorizationStatus

        // Load last known location from UserDefaults
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.lastLatKey) != nil {
            let lat = defaults.double(forKey: Self.lastLatKey)
            let lng = defaults.double(forKey: Self.lastLngKey)
            self.currentLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }

        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coord = location.coordinate
        currentLocation = coord
        persistLocation(coord)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently fail — we still have last known or Singapore default
    }

    // MARK: - Persistence

    private func persistLocation(_ coord: CLLocationCoordinate2D) {
        let defaults = UserDefaults.standard
        defaults.set(coord.latitude, forKey: Self.lastLatKey)
        defaults.set(coord.longitude, forKey: Self.lastLngKey)
    }

    /// The best available location: current, last known, or Singapore center
    var effectiveLocation: CLLocationCoordinate2D {
        currentLocation ?? Self.singaporeCenter
    }

    /// Whether we have a real (non-default) location
    var hasRealLocation: Bool {
        currentLocation != nil
    }

    // MARK: - Haversine

    static func haversineDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}
