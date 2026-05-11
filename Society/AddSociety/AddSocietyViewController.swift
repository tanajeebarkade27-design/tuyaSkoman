//
//  AddSocietyViewController.swift
//  SkromanIsra
//
//  Created by Admin on 02/02/26.
//

import UIKit
import MapKit
class AddSocietyViewController: UIViewController, UISearchBarDelegate {
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBOutlet weak var societySearchbar: UISearchBar!
    
    private var debounceTimer: Timer?
    private var societies: [Society] = []
    
    private var dimmingView: UIView?
    private var popupView: UIView?
    private var selectedSociety: Society?


    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        setupSearchBar()
           setupTableView()
        setupKeyboardDismiss()
    }
    
    
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupSearchBar() {
           societySearchbar.delegate = self
           societySearchbar.placeholder = "Search society"
       }

       private func setupTableView() {
           tableView.delegate = self
           tableView.dataSource = self
           tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
       }
    
    private func searchSociety(keyword: String) {

        let encodedText = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = MainApi.url("skroman/society-management/societies/search?name=\(encodedText)")

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data else { return }

            do {
                let response = try JSONDecoder().decode(SocietySearchResponse.self, from: data)
print ("society response \(response)")
                DispatchQueue.main.async {
                    self.societies = response.data   // ✅ correct
                    self.tableView.reloadData()
                }

            } catch {
                print("❌ Decoding Error:", error)
            }
        }.resume()
    }


   
}


extension AddSocietyViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        societies.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let society = societies[indexPath.row]
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text =
            "\(society.name)\n\(society.address.fullAddress)"

        return cell
    }



   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedSociety = societies[indexPath.row]

        tableView.isHidden = true
        showSocietyPopup(society: selectedSociety)
    }

}
extension AddSocietyViewController {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        debounceTimer?.invalidate()

        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)

        if trimmedText.isEmpty {
            societies.removeAll()
            tableView.reloadData()
            return
        }

        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.searchSociety(keyword: trimmedText)
        }
    }
    private func showSocietyPopup(society: Society) {

        // Prevent duplicate popup
        guard popupView == nil else { return }
        selectedSociety = society 
        // Dim background
        let dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.alpha = 0
        view.addSubview(dimView)
        self.dimmingView = dimView

        // Popup container
        let popup = UIView()
        popup.backgroundColor = .white
        popup.layer.cornerRadius = 12
        popup.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popup)
        self.popupView = popup

        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popup.widthAnchor.constraint(equalToConstant: 300),
            popup.heightAnchor.constraint(equalToConstant: 300) // increased for button
        ])

        // MARK: - Title
        let titleLabel = UILabel()
        titleLabel.text = "Society Details"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // MARK: - Close Button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        // MARK: - Status Badge
        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 10
        statusLabel.layer.borderWidth = 1.5
        statusLabel.clipsToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        switch society.status.lowercased() {
        case "pending":
            statusLabel.text = "PENDING"
            statusLabel.textColor = .systemYellow
            statusLabel.layer.borderColor = UIColor.systemYellow.cgColor

        case "active":
            statusLabel.text = "ACTIVE"
            statusLabel.textColor = .systemGreen
            statusLabel.layer.borderColor = UIColor.systemGreen.cgColor

        case "blocked":
            statusLabel.text = "BLOCKED"
            statusLabel.textColor = .systemRed
            statusLabel.layer.borderColor = UIColor.systemRed.cgColor

        default:
            statusLabel.text = society.status.uppercased()
            statusLabel.textColor = .gray
            statusLabel.layer.borderColor = UIColor.gray.cgColor
        }

        // MARK: - Details Label
        let detailsLabel = UILabel()
        detailsLabel.numberOfLines = 0
        detailsLabel.font = .systemFont(ofSize: 14)
        detailsLabel.text =
        """
        \(society.name)

        \(society.address.fullAddress)
        """
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false

        // MARK: - Map View
        let mapView = MKMapView()
        mapView.layer.cornerRadius = 8
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.translatesAutoresizingMaskIntoConstraints = false

        if let location = society.location {
            let coordinate = CLLocationCoordinate2D(
                latitude: location.lat,
                longitude: location.lng
            )
        


            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = society.name
            mapView.addAnnotation(annotation)

            mapView.setRegion(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                ),
                animated: false
            )
        }

        // MARK: - Processed Button (ONLY FOR ACTIVE)
        let processedButton = UIButton(type: .system)
        processedButton.setTitle("Proceed. ", for: .normal)
        processedButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        processedButton.backgroundColor = .systemGreen
        processedButton.setTitleColor(.white, for: .normal)
        processedButton.layer.cornerRadius = 8
        processedButton.translatesAutoresizingMaskIntoConstraints = false
        processedButton.isHidden = society.status.lowercased() != "active"

        processedButton.addTarget(self, action: #selector(processedTapped), for: .touchUpInside)

        // MARK: - Add Subviews
        popup.addSubview(titleLabel)
        popup.addSubview(closeButton)
        popup.addSubview(statusLabel)
        popup.addSubview(detailsLabel)
        popup.addSubview(mapView)
        popup.addSubview(processedButton)
      
        // MARK: - Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: popup.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 16),

            closeButton.topAnchor.constraint(equalTo: popup.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            statusLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 6),
            statusLabel.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -12),
            statusLabel.widthAnchor.constraint(equalToConstant: 80),
            statusLabel.heightAnchor.constraint(equalToConstant: 24),

            detailsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            detailsLabel.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 16),
            detailsLabel.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -16),

            mapView.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 12),
            mapView.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 100),

            processedButton.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 12),
            processedButton.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 16),
            processedButton.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -16),
            processedButton.heightAnchor.constraint(equalToConstant: 44)
            
          
        ])

        // Animate
        UIView.animate(withDuration: 0.25) {
            dimView.alpha = 1
        }
    }
    
    @objc private func processedTapped() {
        closePopup()

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "SocietyFormVc"
        ) as? SocietyFormVc else {
            assertionFailure("❌ SocietyFormVc not found")
            return
        }

        vc.society = selectedSociety   // ✅ PASS DATA

        navigationController?.pushViewController(vc, animated: true)
    }



    @objc private func closePopup() {

        UIView.animate(withDuration: 0.25, animations: {
            self.dimmingView?.alpha = 0
        }) { _ in
            self.popupView?.removeFromSuperview()
            self.dimmingView?.removeFromSuperview()

            self.popupView = nil
            self.dimmingView = nil

            self.tableView.isHidden = false
        }
    }

}



struct SocietySearchResponse: Decodable {
    let count: Int
    let data: [Society]
}

struct Society: Decodable {
    let id: String
    let societyId: String
    let name: String
    let address: Address
    let location: Location?
    let status: String
    let blocked: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case societyId
        case name
        case address
        case location
        case status
        case blocked
    }
}

struct Location: Decodable {
    let lat: Double
    let lng: Double
}

struct Address: Decodable {
    let fullAddress: String
    let city: String
    let state: String
    let pincode: String
}
