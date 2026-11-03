// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import CoreLocation
import Foundation

struct Place: Equatable {
    let latitude: Double
    let longitude: Double
}

/// The person's approximate location: read while the app is open, kept on
/// this iPhone, and forgotten when location access is withdrawn.
@Observable
final class SolarPlace: NSObject, CLLocationManagerDelegate {
    private(set) var place: Place?
    private(set) var authorization: CLAuthorizationStatus = .notDetermined

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private let defaults = UserDefaults.standard

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
        authorization = manager.authorizationStatus
        if let latitude = defaults.object(forKey: SettingKey.latitude) as? Double,
           let longitude = defaults.object(forKey: SettingKey.longitude) as? Double {
            place = Place(latitude: latitude, longitude: longitude)
        }
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    func request() {
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            refresh()
        }
    }

    func refresh() {
        if isAuthorized { manager.requestLocation() }
    }

    private func update(_ status: CLAuthorizationStatus) {
        authorization = status
        if status == .denied || status == .restricted {
            place = nil
            defaults.removeObject(forKey: SettingKey.latitude)
            defaults.removeObject(forKey: SettingKey.longitude)
        }
        refresh()
    }

    private func store(_ coordinate: CLLocationCoordinate2D) {
        place = Place(latitude: coordinate.latitude, longitude: coordinate.longitude)
        defaults.set(coordinate.latitude, forKey: SettingKey.latitude)
        defaults.set(coordinate.longitude, forKey: SettingKey.longitude)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { update(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        MainActor.assumeIsolated { store(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
