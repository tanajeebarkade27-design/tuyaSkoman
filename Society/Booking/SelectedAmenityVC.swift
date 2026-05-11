//
//  SelectedAmenityVC.swift
//  SkromanIsra
//
//  Created by Admin on 09/02/26.
//

import UIKit

class SelectedAmenityVC: UIViewController {
    var amenity: Amenity?
    var rows: [AmenityRow] = []
    var popupCourts: [AmenitySection] = []
    var selectedPopupCourt: AmenitySection?

    
    @IBOutlet weak var amenityCollection: UICollectionView!
    
    @IBOutlet weak var amenityInfoTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let amenity = amenity {
                print("Selected Amenity:", amenity)
            }
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        
        uiNib()
       
        buildRows()
        amenityInfoTableView.reloadData()

            amenityCollection.reloadData()
            
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    @IBAction func backbutton(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    
    func uiNib(){
        let uinib = UINib(nibName: "SelectedAmenityTableViewCell", bundle: nil)
        amenityInfoTableView.register(uinib, forCellReuseIdentifier: "SelectedAmenityTableViewCell")
        amenityInfoTableView.delegate = self
        amenityInfoTableView.dataSource = self
        let uiNib1 =  UINib(nibName: "selAmenityImgCollectionViewCell", bundle: nil)
        amenityCollection.register(uiNib1, forCellWithReuseIdentifier: "selAmenityImgCollectionViewCell")
        amenityCollection.delegate =  self
        amenityCollection.dataSource =  self
    }
    
    
    func buildRows() {
        rows.removeAll()

        guard let amenity = amenity else { return }

        rows.append(.basic)

        if let sections = amenity.sections, !sections.isEmpty {
            rows.append(.courts)
        }

        if amenity.openTime != nil || amenity.closeTime != nil {
            rows.append(.timing)
        }

        if amenity.pricing != nil {
            rows.append(.pricing)
        }

        if let peak = amenity.pricing?.peakHours, !peak.isEmpty {
            rows.append(.peak)
        }

        if amenity.guestRules != nil {
            rows.append(.guests)
        }

        if amenity.bookingRules != nil {
            rows.append(.booking)
        }

        if amenity.cancellationPolicy != nil {
            rows.append(.cancellation)
        }

        if amenity.bufferTimeMinutes != nil {
            rows.append(.buffer)
        }
    }
    
    
    @IBAction func BookBtn(_ sender: Any) {

        guard let amenity = amenity else { return }

        // If courts exist
        if let courts = amenity.sections, !courts.isEmpty {

            showCourtSelectionPopup(courts: courts)

        } else {
            // No courts → direct navigation
            navigateToBooking(selectedCourt: nil)
        }
    }
    func showCourtSelectionPopup(courts: [AmenitySection]) {

        let alert = UIAlertController(
            title: "Select Court",
            message: nil,
            preferredStyle: .actionSheet
        )

        for court in courts {
            let action = UIAlertAction(title: court.name, style: .default) { _ in
                self.navigateToBooking(selectedCourt: court)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX,
                                        y: view.bounds.midY,
                                        width: 0,
                                        height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    func navigateToBooking(selectedCourt: AmenitySection?) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CourtBookingVC") as! CourtBookingVC

        vc.amenity = amenity
        vc.selectedCourt = selectedCourt
        

        navigationController?.pushViewController(vc, animated: true)
    }

}
extension SelectedAmenityVC: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return popupCourts.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return popupCourts[row].name
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        selectedPopupCourt = popupCourts[row]
    }
}


extension SelectedAmenityVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return amenity?.images.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "selAmenityImgCollectionViewCell",
            for: indexPath
        ) as! selAmenityImgCollectionViewCell

        guard let images = amenity?.images,
              images.count > 0 else {

            cell.amenityImageView.image = UIImage(named: "profile")
            return cell
        }

        let urlString = images[indexPath.item]

        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.amenityImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(
            width: collectionView.frame.width,
            height: collectionView.frame.height
        )
    }
}


extension SelectedAmenityVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count

    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedAmenityTableViewCell", for: indexPath) as! SelectedAmenityTableViewCell

        guard let amenity = amenity else { return cell }

        switch rows[indexPath.row]
 {

        case .basic:
            cell.textLabel?.text = "\(amenity.name)\n\(amenity.description)"

        case .courts:
            let courts = amenity.sections!.map {
                "\($0.name) • Capacity \($0.capacity)"
            }.joined(separator: "\n")
            cell.textLabel?.text = "🏸 Courts\n\(courts)"

        case .timing:
            cell.textLabel?.text = "⏰ Timing\n\(amenity.openTime!) - \(amenity.closeTime!)"

        case .pricing:
            let price = amenity.pricing?.defaultRate ?? 0
            cell.textLabel?.text = "💰 Pricing\n₹\(price)/hr"

        case .peak:
            let peak = amenity.pricing!.peakHours!.first!
            cell.textLabel?.text = "🔥 Peak\n\(peak.from)-\(peak.to)"

        case .guests:
            let g = amenity.guestRules!
            cell.textLabel?.text = "👥 Guests\nMax \(g.maxGuests ?? 0)"

        case .booking:
            let b = amenity.bookingRules!
            cell.textLabel?.text = "📅 Booking\nMax hrs \(b.maxHoursPerBooking ?? 0)"

        case .cancellation:
            let c = amenity.cancellationPolicy!
            cell.textLabel?.text = "❌ Cancel\nBefore \(c.hoursBefore ?? 0) hrs"

        case .buffer:
            cell.textLabel?.text = "⏳ Buffer\n\(amenity.bufferTimeMinutes!) min"

        }

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .white
 
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none

        return cell


       
    }
}

enum AmenityRow {
    case basic
    case courts
    case timing
    case pricing
    case peak
    case guests
    case booking
    case cancellation
    case buffer
}
