//
//  GeofencViewController.swift
//  SkromanIsra
//
//  Created by Admin on 28/04/25.
//

import UIKit
import CoreLocation
import AWSIoT
import AWSCore
import MapKit
import UserNotifications

class GeofencViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    // MARK: - Properties
    let locationManager = CLLocationManager()
    var homeId: String?
    var currentGeofence: CLCircularRegion?
    var currentAnnotation: MKPointAnnotation?
    var MDSP: Int = 10
    var PUB_TOPIC_: String?
    var geofenceExited = false
    var iotDataManager: AWSIoTDataManager!
    var hasZoomedToLocation = false
    // MARK: - Outlets
    @IBOutlet weak var distanceTextField: UITextField!
    @IBOutlet weak var distanceSelectionView: UIView!
    @IBOutlet weak var geoMapView: MKMapView!
    @IBOutlet weak var saveButton: UIButton!
  var isGeoFenceEnabled: Bool = true
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        distanceSelectionView.clipsToBounds =  true
               if isGeoFenceEnabled {
                        print("Geo-fence is enabled")
                    setupGeofenceFromDefaults()
        
                    } else {
                        print("Geo-fence is disabled")
                        
                    }
        if !isGeoFenceEnabled {
            print("Geo-fence is disabled")
            showCurrentLocationOnly()
        }
        
      
        distanceSelectionView.cornerRadius = 15
        if homeId == nil {
               print("Warning: homeId is not set. Please ensure it is initialized.")
           }
        print("homeId at geo: \(homeId ?? "nil")")
        initializeMQTTManager()
        zoomToCurrentLocation()
        distanceSelectionView.isHidden = true
        geoMapView.delegate = self
        geoMapView.showsUserLocation = true
        distanceTextField.keyboardType = .numberPad

        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        fetchDeviceTopics { topics in
                print("Fetched Device Topics: \(topics)")
                
            }
       

        // Add tap gesture to the map
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        geoMapView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        
        // Zoom to current location if it hasn't been done already
        if !hasZoomedToLocation {
            zoomToCurrentLocation()
            hasZoomedToLocation = true
        }
        
        // Geofence check
        guard let geofence = currentGeofence else { return }
        
        if geofence.contains(currentLocation.coordinate) {
            if geofenceExited {
                print("User is inside the geofence.")
                geofenceExited = false
                sendGeofenceState(state: 0)
                showInGeofenceAlert()
            }
        } else {
            if !geofenceExited {
                print("User is outside the geofence.")
                geofenceExited = true
                sendGeofenceState(state: 1)
                showOutOfGeofenceAlert()
            }
        }
    }

    
    func zoomToCurrentLocation() {
        guard let currentLocation = locationManager.location else {
            print("Current location is not available.")
            return
        }
        let coordinate = currentLocation.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000, // Zoom level: increase this to "zoom out"
            longitudinalMeters: 1000
        )
        geoMapView.setRegion(region, animated: true)
    }

    func showCurrentLocationOnly() {
        guard let currentLocation = locationManager.location else {
            print("Current location not available.")
            return
        }

        let coordinate = currentLocation.coordinate

        // 1. Zoom to location
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        geoMapView.setRegion(region, animated: true)

        // 2. Add annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Current Location"
        geoMapView.addAnnotation(annotation)
    }

    
    
    // MARK: - Location Manager Delegate Methods
  
    func setupGeofenceFromDefaults() {
        guard let geofenceData = UserDefaults.standard.dictionary(forKey: "savedGeofence"),
              let latitude = geofenceData["latitude"] as? Double,
              let longitude = geofenceData["longitude"] as? Double,
              let radius = geofenceData["radius"] as? Double else {
            print("No saved geofence data found in UserDefaults.")
            return
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        // Remove any existing geofence and overlays
        if let geofence = currentGeofence {
            locationManager.stopMonitoring(for: geofence)
            geoMapView.removeOverlays(geoMapView.overlays.filter { $0 is MKCircle })
        }

        // Create a new geofence region
        let geofenceRegion = CLCircularRegion(center: coordinate, radius: radius, identifier: UUID().uuidString)
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        locationManager.startMonitoring(for: geofenceRegion)
        currentGeofence = geofenceRegion

        // Add a map overlay
        let circleOverlay = MKCircle(center: coordinate, radius: radius)
        geoMapView.addOverlay(circleOverlay)

        // Add an annotation for the geofence center
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Saved Geofence"
        geoMapView.addAnnotation(annotation)
        currentAnnotation = annotation

        print("Geofence restored from UserDefaults: Center (\(latitude), \(longitude)), Radius \(radius) meters.")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location access granted.")
        case .denied, .restricted:
            print("Location access denied.")
        default:
            break
        }
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let geofence = currentGeofence, region.identifier == geofence.identifier else { return }
        print("Entered geofence: \(geofence.identifier)")

        sendLocalNotification(title: "Geofence Alert", body: "You have entered the geofence.")

        fetchDeviceTopics { topics in
            for topic in topics {
                self.sendPayloadForGeofenceState(to: topic, state: 0) // State 0 = inside geofence
                print("Sent payload to topic \(topic) with state 0")
            }
        }
    }


    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let geofence = currentGeofence, region.identifier == geofence.identifier else { return }
        print("Exited geofence: \(geofence.identifier)")

        sendLocalNotification(title: "Geofence Alert", body: "You have exited the geofence.")

        fetchDeviceTopics { topics in
            for topic in topics {
                self.sendPayloadForGeofenceState(to: topic, state: 1) // State 1 = outside geofence
                print("Sent payload to topic \(topic) with state 1")
            }
        }
    }



    // MARK: - Map Interaction
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: geoMapView)
        let tappedCoordinate = geoMapView.convert(locationInView, toCoordinateFrom: geoMapView)

        // Remove previous annotation and add new one
        if let annotation = currentAnnotation {
            geoMapView.removeAnnotation(annotation)
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = tappedCoordinate
        annotation.title = "Selected Location"
        geoMapView.addAnnotation(annotation)
        currentAnnotation = annotation

        print("Pin added at: \(tappedCoordinate.latitude), \(tappedCoordinate.longitude)")
    }

    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func saveButtonTapped(_ sender: Any) {
        if currentAnnotation == nil {
            // Fallback to the device's current location
            guard let currentLocation = locationManager.location else {
                showAlert("Unable to get the current location. Please enable location services.")
                return
            }
            
            let currentLatitude = currentLocation.coordinate.latitude
            let currentLongitude = currentLocation.coordinate.longitude

            print("Using current location for geofence: \(currentLatitude), \(currentLongitude)")

            // Add annotation for the current location
            let annotation = MKPointAnnotation()
            annotation.coordinate = currentLocation.coordinate
            annotation.title = "Current Location"
            geoMapView.addAnnotation(annotation)
            currentAnnotation = annotation
        }
        // Proceed to show the distance selection view
        distanceSelectionView.isHidden = false
    }



    @IBAction func okButtonTapped(_ sender: Any) {
        guard let distanceText = distanceTextField.text,
              let distance = Double(distanceText),
              distance > 0,
              let currentAnnotation = currentAnnotation else {
            showAlert("Please add a valid distance and select a location.")
            return
        }

        // Remove previous geofence
        if let geofence = currentGeofence {
            locationManager.stopMonitoring(for: geofence)
            geoMapView.removeOverlays(geoMapView.overlays.filter { $0 is MKCircle })
        }

        // Create and monitor the new geofence using the tapped location
        let geofenceRegion = CLCircularRegion(center: currentAnnotation.coordinate, radius: distance, identifier: UUID().uuidString)
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        locationManager.startMonitoring(for: geofenceRegion)
        currentGeofence = geofenceRegion

        // Add map overlay for geofence
        let circleOverlay = MKCircle(center: currentAnnotation.coordinate, radius: distance)
        geoMapView.addOverlay(circleOverlay)

        // Prepare geofence data
        let geofenceData: [String: Any] = [
            "latitude": currentAnnotation.coordinate.latitude,
            "longitude": currentAnnotation.coordinate.longitude,
            "radius": distance
        ]

        // Save geofence data to UserDefaults if isGeoFenceEnabled is true
        if isGeoFenceEnabled {
            UserDefaults.standard.set(geofenceData, forKey: "savedGeofence")
            UserDefaults.standard.synchronize()
            print("Geofence data saved to UserDefaults: \(geofenceData)")
        }

        print("Geofence created with center (\(currentAnnotation.coordinate.latitude), \(currentAnnotation.coordinate.longitude)) and radius \(distance) meters.")
        showAlert("Geofence created with radius \(distance) meters.")
        distanceSelectionView.isHidden = true
    }


    // MARK: - Map View Delegate Methods
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.3)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1.0
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: - Helper Methods
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Geofence", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showOutOfGeofenceAlert() {
        showAlert("You have exited the geofence area.")
    }

    func showInGeofenceAlert() {
        showAlert("You have entered the geofence area.")
    }

    func sendGeofenceState(state: Int) {
        guard let topic = PUB_TOPIC_ else {
            print("No MQTT topic available to send payload.")
            return
        }

        let json = createCommonJSON(type: "M", no: 1, state: state, speed: MDSP, from: "C")
        print("Publishing Geofence JSON to topic \(topic): \(json)")
        publishMessage(message: json, topic: topic)
    }

    func createCommonJSON(type: String, no: Int, state: Int, speed: Int, from: String) -> String {
        let json: [String: Any] = ["control": type, "no": no, "state": state, "speed": speed]
        print("Common JSON: \(json)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) {
            return String(data: jsonData, encoding: .utf8) ?? "NA"
        }
        return "NA"
    }

    func fetchDeviceTopics(completion: @escaping ([String]) -> Void) {
        guard let homeId = homeId else {
            print("Home ID is nil")
            completion([])
            return
        }

        SkromanIsraDatabaseHelper.shared.fetchDevicesByHomeId(homeId: homeId) { devices in
            let topics = devices
                .map { $0.uniqueId }
                .filter { !$0.isEmpty }
                .map { "\($0)/HA/A/req" }

            print("Device Topics:", topics)
            completion(topics)
        }
    }




    func initializeMQTTManager() {
            // Replace with your actual AWS IoT Data manager key
            iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            
            // Check if it's initialized
            if iotDataManager == nil {
                print("Failed to initialize MQTT Manager.")
            } else {
                print("MQTT Manager initialized successfully.")
            }
        }
    func publishMessage(message: String, topic: String) {
           // Check if the manager is initialized before using it
           if let mqttManager = iotDataManager {
               if mqttManager.getConnectionStatus() == .connected {
                   mqttManager.publishString(message, onTopic: topic, qoS: .messageDeliveryAttemptedAtLeastOnce)
                   print("Message published successfully.")
               } else {
                   print("MQTT manager is not connected.")
               }
           } else {
               print("MQTT manager is not initialized.")
           }
       }
    
    
    func sendPayloadForGeofenceState(to topic: String, state: Int) {
        guard !topic.isEmpty else {
            print("No MQTT topic available to send payload.")
            return
        }
        
        // Create the payload JSON
        let json = createCommonJSON(type: "M", no: 1, state: state, speed: MDSP, from: "C")
        print("Publishing Geofence JSON to topic \(topic): \(json)")
        
        // Call publishMessage to send the payload
        publishMessage(message: json, topic: topic)
    }
}

extension GeofencViewController{
    func registerForLocalNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted.")
            } else if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Add an app icon as an attachment (optional)
        if let appIcon = UIImage(named: "AppIcon"), // Replace with your app's icon name
           let imageData = appIcon.pngData() {
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent("appIcon.png")
            try? imageData.write(to: fileURL)
            
            if let attachment = try? UNNotificationAttachment(identifier: "appIcon", url: fileURL, options: nil) {
                content.attachments = [attachment]
            }
        }
        
        // Create the notification trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Add the notification to the current notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

}

