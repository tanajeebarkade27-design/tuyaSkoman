//
//  AmenityBookListVC.swift
//  SkromanIsra
//
//  Created by Admin on 21/02/26.
//

import UIKit
import SwiftKeychainWrapper

class AmenityBookListVC: UIViewController {
    
    
    @IBOutlet weak var bookingListTableView: UITableView!
    
    var userId : String?
    var bookings: [AmenityBooking] = []
    var groupedBookings: [AmenityBooking] = []
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
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        
        fetchUserAmenityBookings(userId: userId)
        let uiNib =  UINib(nibName: "BookListCell", bundle: nil)
        bookingListTableView.register(uiNib, forCellReuseIdentifier: "BookListCell")
        bookingListTableView.delegate = self
        bookingListTableView.dataSource = self
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func fetchUserAmenityBookings(userId: String) {

        let urlString = MainApi.url("skroman/society/amenity/v1/api/amenities/bookings/user/\(userId)")

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in

            if let error = error {
                print("Booking API error:", error)
                return
            }

            guard let data = data else { return }

            print(String(data: data, encoding: .utf8) ?? "")

            do {
                let result = try JSONDecoder().decode(UserBookingResponse.self, from: data)

                DispatchQueue.main.async {
                    print("Total:", result.total)
                    print("Bookings count:", result.bookings.count)

                    DispatchQueue.main.async {
                        self.bookings = result.bookings
                        self.bookingListTableView.reloadData()
                        
                    }
                }

            } catch {
                print("Decoding error:", error)
            }

        }.resume()
    }
      
    func formatDate(_ iso: String?) -> String {
        guard let iso = iso else { return "" }

        // ISO with milliseconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: iso) {
            return displayDate(date)
        }

        // ISO without milliseconds
        let isoFormatter2 = ISO8601DateFormatter()
        if let date = isoFormatter2.date(from: iso) {
            return displayDate(date)
        }

        // yyyy-MM-dd fallback
        let fallback = DateFormatter()
        fallback.dateFormat = "yyyy-MM-dd"
        fallback.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = fallback.date(from: iso) {
            return displayDate(date)
        }

        return iso
    }

    func displayDate(_ date: Date) -> String {
        let out = DateFormatter()
        out.dateFormat = "dd MMM yyyy"
        out.timeZone = .current
        return out.string(from: date)
    }
    func formatTime(_ time: String?) -> String {
        guard let time = time else { return "" }

        let input = DateFormatter()
        input.dateFormat = "HH:mm"

        let output = DateFormatter()
        output.dateFormat = "h:mm a"

        if let date = input.date(from: time) {
            return output.string(from: date)
        }

        return time
    }
}

extension AmenityBookListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookings.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "BookListCell",
                                                 for: indexPath) as! BookListCell

        let item = bookings[indexPath.row]
        cell.aminityName.text = item.amenity.name
        cell.section.text = "Section: \(item.section.sectionName ?? "")"
        cell.aminityCatgory.text = "Category: \(item.amenity.category ?? "")"
        cell.dateTime.text = formatDate(item.date)

        let slotText = item.slots
            .compactMap {
                "\(formatTime($0.from)) - \(formatTime($0.to))"
            }
            .joined(separator: ", ")

        cell.slot.text = "Slots: \(slotText)"
        cell.status.text =  item.status

        cell.totalPrice.text = "Total paid: \(item.priceSnapshot?.totalPayable ?? 0)/-"
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {

       
        return 170
    }
}
struct UserBookingResponse: Decodable {
    let userId: String
    let total: Int
    let bookings: [AmenityBooking]
}

struct AmenityBooking: Decodable {
    let bookingId: String?
    let amenity: BookingAmenity
    let section: BookingSection
    let date: String?
    let slots: [BookingSlot]
    let priceSnapshot: PriceSnapshot?
    let status: String?
}

struct BookingAmenity: Decodable {
    let amenityId: String?
    let name: String?
    let category: String?
    let images: [String]?
}

struct BookingSection: Decodable {
    let sectionId: String?
    let sectionName: String?
}

struct BookingSlot: Decodable {
    let from: String?
    let to: String?
}

struct PriceSnapshot: Decodable {
    let totalPayable: Int?
}
