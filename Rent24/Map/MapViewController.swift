//
//  SecondViewController.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 27/04/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {

    @IBOutlet private weak var map: GMSMapView!
    @IBOutlet weak var pickupButton: UIButton!

    private let locationManager = CLLocationManager()
    private var trip: JobTrip? {
        didSet {
            updateMarkers()
        }
    }
    private var markers: [Int:CLLocation]?
    private let currentLocationMarker = 0
    private let pickupLocationMarker = 1
    private let dropOffLocationMarker = 2
    private let carDistance = 25.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        map.delegate = self

        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .automotiveNavigation

        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("either permission not given or revoked")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            print("have permission, detect location")
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            print("have permission, detect location")
        @unknown default:
            fatalError("you're using an older version of app")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateMarkers()
    }

    @IBAction func onClickListener(_ sender: UIButton) {
        if let currentLocation = markers?[currentLocationMarker],
            let pickupLocation = markers?[pickupLocationMarker],
            !currentLocation.distance(from: pickupLocation).isLess(than: carDistance),
            UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
        }
    }

    func updateMap(for trip: JobTrip) {
        self.trip = trip
    }

    private func showMarkers(on mapView: GMSMapView) {
        map.clear()

        if let markers = markers {
            for location in markers.values {
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                marker.map = mapView
            }
        }
    }

    private func updateMarkers() {
        if let trip = trip {
            if nil == markers {
                markers = [Int:CLLocation]()
            }
            if let pickupLat = trip.pickupLatDouble,
                let pickupLong = trip.pickupLongDouble {
                markers?[pickupLocationMarker] = CLLocation(latitude: pickupLat, longitude: pickupLong)
            }
            if let dropOffLat = trip.dropOffLatDouble,
                let dropOffLong = trip.dropOffLongDouble {
                markers?[dropOffLocationMarker] = CLLocation(latitude: dropOffLat, longitude: dropOffLong)
            }
            showMarkers(on: map)
        }
    }

}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            print("either permission not given or revoked after asking")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            print("have permission, detect location after asking")
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            print("have permission, detect location after asking")
        case .notDetermined:
            print("something's not right when asking")
        @unknown default:
            fatalError("you're using an older version of app")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if nil == markers {
                markers = [Int:CLLocation]()
            }
            markers?[currentLocationMarker] = location
            showMarkers(on: map)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager failed", error.localizedDescription)
        if let error = error as? CLError,
            error.code == .denied {
            manager.stopMonitoringSignificantLocationChanges()
            manager.stopUpdatingLocation()
        }
    }
}

extension MapViewController: GMSMapViewDelegate {
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        if var markers = markers,
            let location = markers[currentLocationMarker] {
            showMarkers(on: mapView)

            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 16.0)
            map.animate(to: camera)
        }
    }
}
