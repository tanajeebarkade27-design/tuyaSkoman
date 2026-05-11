//
//  CourtViewController.swift
//  SkromanIsra
//
//  Created by Admin on 07/02/26.
//

import UIKit

class AmenityViewController: UIViewController {
    
    @IBOutlet weak var amenityTableView: UITableView!
    var societyId: String = ""
    private var amenities: [Amenity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        print("Received societyId:", societyId)
        fetchAmenities()
        uiNib()
        
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func fetchAmenities() {
            let urlString =
            MainApi.url("skroman/society/amenity/v1/api/admin/amenities?societyId=\(societyId)")

            guard let url = URL(string: urlString) else { return }

            URLSession.shared.dataTask(with: url) { data, _, error in
                 

                if let error = error {
                    print("Amenity API Error:", error)
                    return
                }

                guard let data = data else { return }

                do {
                    let response = try JSONDecoder().decode(AmenityResponse.self, from: data)
                    print("response at\(response)")
                    DispatchQueue.main.async {
                        self.amenities = response.amenities
                        self.amenityTableView.reloadData()
                    }

                } catch {
                    print("Amenity Decode Error:", error)
                }

            }.resume()
        }
   
    
    func uiNib(){
        let uinib = UINib(nibName: "AmenityTableViewCell", bundle: nil)
        amenityTableView.register(uinib, forCellReuseIdentifier: "AmenityTableViewCell")
        amenityTableView.delegate = self
        amenityTableView.dataSource = self
        }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func bookinglist(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AmenityBookListVC") as! AmenityBookListVC
        
        
        navigationController?.pushViewController(vc, animated: true)
        }
    

}


extension AmenityViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amenities.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AmenityTableViewCell",
            for: indexPath
        ) as! AmenityTableViewCell

        let item = amenities[indexPath.row]
        cell.configure(with: item)
        
        let amenity = amenities[indexPath.row]

        cell.configure(with: amenity)

        cell.onAmenityTapped = { [weak self] in
            guard let self = self else { return }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectedAmenityVC") as! SelectedAmenityVC

            vc.amenity = amenity

            self.navigationController?.pushViewController(vc, animated: true)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedAmenity = amenities[indexPath.row]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SelectedAmenityVC") as! SelectedAmenityVC

     print ("click cell")
        vc.amenity = selectedAmenity

        navigationController?.pushViewController(vc, animated: true)
    }

}


struct AmenityResponse: Decodable {
    let msg: String
    let societyId: String
    let total: Int
    let amenities: [Amenity]
}

struct Amenity: Decodable {
    let id: String?
    let amenityId: String
    let societyId: String?
    let name: String
    let description: String
    let category: String?
    let images: [String]
    let isBookable: Bool
    let openTime: String?
    let closeTime: String?
    let bufferTimeMinutes: Int?

    let pricing: Pricing?
    let guestRules: GuestRules?
    let bookingRules: BookingRules?
    let cancellationPolicy: CancellationPolicy?
    let sections: [AmenitySection]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case amenityId
        case societyId
        case name
        case description
        case category
        case images
        case isBookable
        case openTime
        case closeTime
        case bufferTimeMinutes
        case pricing
        case guestRules
        case bookingRules
        case cancellationPolicy
        case sections
    }
}
struct Pricing: Decodable {
    let defaultRate: Int?
    let weekendRate: Int?
    let securityDeposit: Int?
    let peakHours: [PeakHour]?
}
struct PeakHour: Decodable {
    let from: String
    let to: String
    let rate: Int
}
struct GuestRules: Decodable {
    let allowGuests: Bool?
    let guestCharge: Int?
    let maxGuests: Int?
}
struct BookingRules: Decodable {
    let maxHoursPerBooking: Int?
    let maxAdvanceDays: Int?
    let maxBookingsPerDay: Int?
    let timeSlotDuration: Int?
}
struct CancellationPolicy: Decodable {
    let allowed: Bool?
    let hoursBefore: Int?
    let cancellationCharge: Int?
}
struct AmenitySection: Decodable {
    let sectionId: String
    let name: String
    let capacity: Int
    let isAvailable: Bool
}
