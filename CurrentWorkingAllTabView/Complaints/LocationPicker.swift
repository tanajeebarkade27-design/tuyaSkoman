//
//  LocationPicker.swift
//  SkromanIsra
//
//  Created by Admin on 02/12/25.
//

//
//  LocationPickerViewController.swift
//  SkromanIsra
//
//  Created by Admin on 02/12/25.
//

import UIKit
import MapKit
import CoreLocation

class LocationPickerViewController: UIViewController, CLLocationManagerDelegate {

    var mapView = MKMapView()
    var locationManager = CLLocationManager()
    var selectedCoordinate: CLLocationCoordinate2D?
    var hasCenteredOnUser = false

    // RETURN lat, long, address
    var onLocationSelected: ((Double, Double, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Pick Location"
        view.backgroundColor = .white

        setupMapView()
        setupOkButton()
        setupLocationManager()
        if let current = locationManager.location {
               centerMapOn(current.coordinate)
               selectedCoordinate = current.coordinate
               hasCenteredOnUser = true
           }

    }

    
    func centerMapOn(_ coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: true)
        dropPin(at: coordinate)
    }

    // MARK: - Setup map
    func setupMapView() {
        mapView.frame = view.bounds
        mapView.showsUserLocation = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup OK button
    func setupOkButton() {
        let okButton = UIButton(type: .system)
        okButton.setTitle("Add Location", for: .normal)
        okButton.backgroundColor = .white
        okButton.setTitleColor(.black, for: .normal)
        okButton.layer.cornerRadius = 10
        okButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        okButton.addTarget(self, action: #selector(okButtonPressed), for: .touchUpInside)

        okButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(okButton)

        NSLayoutConstraint.activate([
            okButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            okButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            okButton.widthAnchor.constraint(equalToConstant: 140),
            okButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Setup location manager
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - Map tap → update pin
    @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        selectedCoordinate = coordinate
        dropPin(at: coordinate)
    }

    // MARK: - Drop pin
    func dropPin(at coordinate: CLLocationCoordinate2D) {
        mapView.removeAnnotations(mapView.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Selected Location"
        mapView.addAnnotation(annotation)
    }

    // MARK: - Location Manager (Current Location)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasCenteredOnUser else { return }   // zoom only once

        if let location = locations.last {
            hasCenteredOnUser = true

            selectedCoordinate = location.coordinate

            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )

            mapView.setRegion(region, animated: true)
            dropPin(at: location.coordinate)
        }
    }

    // MARK: - Reverse Geocoding
    func fetchAddressFromCoordinates(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in

            if let error = error {
                print("Reverse geocode failed: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }

            var address = ""

            if let name = placemark.name { address += name + ", " }
            if let subLocality = placemark.subLocality { address += subLocality + ", " }
            if let locality = placemark.locality { address += locality + ", " }
            if let state = placemark.administrativeArea { address += state + ", " }
            if let country = placemark.country { address += country }

            completion(address)
        }
    }

    // MARK: - OK button tapped
    @objc func okButtonPressed() {
        guard let coordinate = selectedCoordinate else {
            print("No location selected")
            navigationController?.popViewController(animated: true)
            return
        }

        // Convert lat/long → address
        fetchAddressFromCoordinates(coordinate) { address in
            let finalAddress = address ?? "Address not found"

            print("Selected Address:", finalAddress)

            // Return to main screen
            self.onLocationSelected?(
                coordinate.latitude,
                coordinate.longitude,
                finalAddress
            )

            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
