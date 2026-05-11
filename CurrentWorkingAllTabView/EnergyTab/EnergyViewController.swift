//
//  EnergyViewController.swift
//  SkromanIsra
//
//  Created by Admin on 04/08/25.
//

import UIKit
import Alamofire
class EnergyViewController: UIViewController {

    @IBOutlet weak var enegrybackgroundView: UIView!
    @IBOutlet weak var totalEnegryView: UIView!
    @IBOutlet weak var engImageview: UIView!
    @IBOutlet weak var totalEnergylabel: UILabel!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var dayEnegryBtn: UIButton!
    @IBOutlet weak var monthengeryBtn: UIButton!
    @IBOutlet weak var graphbackgroundView: UIView!
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var roomBackgroundView: UIView!
    @IBOutlet weak var energyGraphContainer: UIView!
    private var energyLineGraph: EnergyLineGraphView?
    
    @IBOutlet weak var roomsEnegryTableView: UITableView!
    var liveEnergy : String?
    @IBOutlet weak var selcetDateView: UIView!
    
    @IBOutlet weak var fromDatePicker: UIDatePicker!
    
    var  roomTabledata: Bool =  false
    @IBOutlet weak var toDtatePicker: UIDatePicker!
    
    var roomEnergyDataList: [RoomEnergyData] = []
  
    @IBOutlet weak var todaysEnergy: UILabel!
    
    @IBOutlet weak var theseMonthEnergy: UILabel!
    var fromDate: Date?
    var toDate: Date?

    @IBOutlet weak var eneLabel: UILabel!
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    var rooms: [Room] = []
    var roomEnergies: [RoomEnergy] = [] // from API
    var totalEnergy: Double = 0.0
    
    var homeId : String?
    override func viewDidLoad() {
        super.viewDidLoad()
        [totalEnegryView, buttonView, roomBackgroundView].forEach {
            $0?.layer.cornerRadius = 15
            $0?.clipsToBounds = true
            $0?.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        }
        
        print("at ene homeId \(homeId)")
        totalEnegryView.layer.cornerRadius = 10
        totalEnegryView.backgroundColor = UIColor.white.withAlphaComponent(0.30)
        engImageview.layer.cornerRadius = engImageview.frame.height / 2
        engImageview.clipsToBounds = true
        engImageview.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let graph = EnergyLineGraphView(frame: energyGraphContainer.bounds)
        graph.backgroundColor = .clear
        graph.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        energyGraphContainer.addSubview(graph)
        energyLineGraph = graph
       
        guard let homeId = homeId else {
            print("⚠️ homeId is nil — cannot fetch rooms.")
            return
        }
      
        selcetDateView.isHidden =  true
        registerXib()
       
        selcetDateView.backgroundColor =  UIColor.white
        selcetDateView.cornerRadius =  15
        selcetDateView.clipsToBounds =  true
        
        roomsEnegryTableView.dataSource = self
        roomsEnegryTableView.delegate =  self
        
        
        let today = Date()
           let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today)!
           let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!

           fromDatePicker.minimumDate = threeMonthsAgo
           fromDatePicker.maximumDate = sevenDaysAgo

           toDtatePicker.minimumDate = threeMonthsAgo
           toDtatePicker.maximumDate = today
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let selectedId = MainHomeViewController.sharedSelectedHomeId {
            self.homeId = selectedId
            print("Updated homeId = \(selectedId)")

            
            fetchRoomsForSelectedHome(homeId: selectedId)

            fetchLiveEnergyConsumption(for: selectedId) { response in
                    if let data = response {
                        print("Home ID: \(data.homeId)")
                        print("Total Consumption: \(data.totalHomeEnergyConsumption)")
                        
                       
                        self.todaysEnergy.text = "\(data.totalHomeEnergyConsumption)kWh"
                        self.eneLabel.text = "\(data.totalHomeEnergyConsumption)kWh"
                    }
                }
            fetchEnergyForDateRange(homeId: selectedId) { response in
                if let energyData = response {
                    DispatchQueue.main.async {
                        print("✅ Received energy data: \(energyData)")

                        let last7DaysData = self.getLast7Days(from: energyData.data.totalHomeEnergyConsumption)

                        // Clear existing graph
                        self.energyLineGraph?.removeFromSuperview()

                        // 🔹 Format dates to "Aug 05"
                        let rawDates = last7DaysData.map { $0.date }
                        let formattedDates: [String] = rawDates.compactMap { raw in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            if let date = formatter.date(from: raw) {
                                let displayFormatter = DateFormatter()
                                displayFormatter.dateFormat = "MMM dd"
                                return displayFormatter.string(from: date)
                            }
                            return nil
                        }

                        let values = last7DaysData.map { CGFloat($0.value) }

                        // Setup new graph
                        let graph = EnergyLineGraphView(frame: self.energyGraphContainer.bounds)
                        graph.backgroundColor = .clear
                        graph.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        self.energyGraphContainer.addSubview(graph)
                        graph.updateGraph(with: formattedDates, values: values)
                        self.energyLineGraph = graph

                        // ✅ ROOM ENERGY DATA
                        var roomEnergyList: [RoomEnergyData] = []
                        for room in energyData.data.rooms {
                            let last7 = self.getLast7Days(from: room.totalEnergyConsumption)
                            let roomData = RoomEnergyData(
                                roomId: room.roomId,
                                allEntries: room.totalEnergyConsumption, // ✅ New line
                                last7DaysEnergy: last7
                            )
                            roomEnergyList.append(roomData)
                        }

                        self.roomEnergyDataList = roomEnergyList
                        
                        self.roomsEnegryTableView.reloadData()
                        
                    }
                    
                } else {
                    print("❌ Failed to fetch energy data")
                }
            }
        }

       
        energyLineGraph?.values = []
        energyLineGraph?.months = []
    }



    @IBAction func DaywiseEnegryBtn(_ sender: Any) {
        
        selcetDateView.isHidden =  false
    }
    
    

    
    @IBAction func cancelDateSelection(_ sender: UIButton) {
        selcetDateView.isHidden = true
    }

    
    
    @IBAction func monthDataBtn(_ sender: Any) {
        guard let selectedId = MainHomeViewController.sharedSelectedHomeId else { return }

        self.homeId = selectedId

        fetchEnergyForDateRange(homeId: selectedId) { [weak self] response in
            guard let self = self else { return }

            if let energyData = response {
                DispatchQueue.main.async {
                    print("✅ Received energy data (for month button): \(energyData)")

                    // ✅ Filter last 2 months only
                    let last2MonthsData = self.getLast2Months(from: energyData.data.totalHomeEnergyConsumption)

                    // ✅ Group by "yyyy-MM"
                    var monthTotals: [String: CGFloat] = [:]
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"

                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "LLLL" // "June", "July", etc.

                    for entry in last2MonthsData {
                        guard let date = dateFormatter.date(from: entry.date) else { continue }
                        let monthKey = Calendar.current.dateComponents([.year, .month], from: date)

                        if let monthDate = Calendar.current.date(from: monthKey) {
                            let monthName = displayFormatter.string(from: monthDate)
                            monthTotals[monthName, default: 0] += CGFloat(entry.value)
                        }
                    }

                    // ✅ Sort by month order
                    let sortedMonthNames = monthTotals.keys.sorted { (m1, m2) -> Bool in
                        let df = DateFormatter()
                        df.dateFormat = "LLLL"
                        if let d1 = df.date(from: m1), let d2 = df.date(from: m2) {
                            return d1 < d2
                        }
                        return false
                    }

                    let values = sortedMonthNames.map { monthTotals[$0] ?? 0 }

                    // ✅ Clear old graph
                    self.energyLineGraph?.removeFromSuperview()

                    // ✅ Setup and show new graph
                    let graph = EnergyLineGraphView(frame: self.energyGraphContainer.bounds)
                    graph.backgroundColor = .clear
                    graph.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.energyGraphContainer.addSubview(graph)
                    graph.updateGraph(with: sortedMonthNames, values: values)
                    self.energyLineGraph = graph
                }
            } else {
                print("❌ Failed to fetch monthly data")
            }
        }
    }

    
    func getEnergyEntriesBetween(startDate: Date, endDate: Date, from entries: [EnergyEntry]) -> [EnergyEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return entries.compactMap { entry in
            guard let entryDate = dateFormatter.date(from: entry.date) else { return nil }
            return (entryDate >= startDate && entryDate <= endDate) ? entry : nil
        }.sorted { $0.date < $1.date }
    }

    
    @IBAction func submitDateSelection(_ sender: UIButton) {
        guard let homeId = homeId else {
            showAlert("Home ID not available.")
            return
        }

        let fromDate = fromDatePicker.date
        let toDate = toDtatePicker.date
        fetchEnergyForDateRange(homeId: homeId) { response in
                if let energyData = response {
                    DispatchQueue.main.async {
                        print("✅ Received energy data: \(energyData)")

                       
                        let filteredHomeEntries = self.getEnergyEntriesBetween(
                            startDate: fromDate,
                            endDate: toDate,
                            from: energyData.data.totalHomeEnergyConsumption
                        )

                      
                        let rawDates = filteredHomeEntries.map { $0.date }
                        let formattedDates: [String] = rawDates.compactMap { raw in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            if let date = formatter.date(from: raw) {
                                let displayFormatter = DateFormatter()
                                displayFormatter.dateFormat = "MMM dd"
                                return displayFormatter.string(from: date)
                            }
                            return nil
                        }

                        let values = filteredHomeEntries.map { CGFloat($0.value) }

                      
                        self.energyLineGraph?.removeFromSuperview()

                        let graph = EnergyLineGraphView(frame: self.energyGraphContainer.bounds)
                        graph.backgroundColor = .clear
                        graph.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        self.energyGraphContainer.addSubview(graph)
                        graph.updateGraph(with: formattedDates, values: values)
                        self.energyLineGraph = graph

               

                      
                        self.selcetDateView.isHidden = true
                        
                    }
                } else {
                    print("❌ Failed to fetch energy data")
                }
            }
        print("Selected fromDate = \(fromDate)")
        print("Selected toDate = \(toDate)")

        let today = Date()
        let calendar = Calendar.current

      
        if let maxFromDate = calendar.date(byAdding: .month, value: -3, to: today), fromDate < maxFromDate {
            showAlert("From date should not be older than 3 months.")
            return
        }

        if toDate > today {
            showAlert("To date cannot be in the future.")
            return
        }
        if fromDate > toDate {
            showAlert("From date should be earlier than To date.")
            return
        }

        // 4. Maximum range = 7 days
        let dateDiff = calendar.dateComponents([.day], from: fromDate, to: toDate).day ?? 0
        if dateDiff > 7 {
            showAlert("At Day Button You can see only 7 days Energy data.")
            return
        }

        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateStr = dateFormatter.string(from: fromDate)
        let endDateStr = dateFormatter.string(from: toDate)

        selcetDateView.isHidden = true
    }

    func getDateRange() -> (start: String, end: String) {
        let calendar = Calendar.current
        let today = Date()
        
        // Get first date of the previous month
        var components = calendar.dateComponents([.year, .month], from: today)
        components.month = (components.month ?? 1) - 1
        components.day = 1
        let previousMonthStartDate = calendar.date(from: components) ?? today
        
        // Format both dates
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return (start: formatter.string(from: previousMonthStartDate),
                end: formatter.string(from: today))
    }

    
    func getLast7Days(from entries: [EnergyEntry]) -> [EnergyEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let datedEntries = entries.compactMap { entry -> (Date, EnergyEntry)? in
            guard let date = dateFormatter.date(from: entry.date) else { return nil }
            return (date, entry)
        }

        let sortedEntries = datedEntries.sorted { $0.0 > $1.0 }
        let last7 = sortedEntries.prefix(7).map { $0.1 }
        
        return last7.reversed()
    }

    func updateTotalEnergyLabel(from entries: [EnergyEntry]) {
        let total = entries.reduce(0.0) { $0 + $1.value }

        DispatchQueue.main.async {
            self.totalEnergylabel.text = String(format: "%.2f kWh", total)
        }
    }



    func getLast2Months(from entries: [EnergyEntry]) -> [EnergyEntry] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Calculate start of last month and end of current month
        let now = Date()
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: currentMonthStart) else {
            return []
        }

        // Filter and convert entries
        let filtered = entries.compactMap { entry -> (Date, EnergyEntry)? in
            guard let date = dateFormatter.date(from: entry.date) else { return nil }
            if date >= lastMonthStart && date < nextMonthStart {
                return (date, entry)
            }
            return nil
        }

        // Sort ascending by date
        let sortedEntries = filtered.sorted { $0.0 < $1.0 }

        return sortedEntries.map { $0.1 }
    }

    
    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Invalid Date", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    let roomsIconType: [RoomIconType] = [
        RoomIconType(name: "Study Room", image: "study"),
        RoomIconType(name: "Bed Room", image: "Bed"),
        RoomIconType(name: "Theater", image: "theater"),
        RoomIconType(name: "Balcony", image: "balcony"),
        RoomIconType(name: "Dining Hall", image: "Dining"),
        RoomIconType(name: "Living Room", image: "livingRoom"),
        RoomIconType(name: "Other Room", image: "other"),
        RoomIconType(name: "Garden", image: "garden"),
        RoomIconType(name: "Gate", image: "gate"),
        RoomIconType(name: "Kitchen", image: "Kitchen"),
        RoomIconType(name: "Lift", image: "lift"),
        RoomIconType(name: "Staircase", image: "staircase 1"),
        RoomIconType(name: "Lobby", image: "lobby")
    ]
    
    
    @IBAction func selecteDateRangeButton(_ sender: Any) {
        let alert = UIAlertController(title: "Select Date Range", message: "\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)

        let fromDatePicker = UIDatePicker()
        fromDatePicker.datePickerMode = .date
        fromDatePicker.preferredDatePickerStyle = .wheels
        fromDatePicker.frame = CGRect(x: 0, y: 40, width: 270, height: 100)

        let toDatePicker = UIDatePicker()
        toDatePicker.datePickerMode = .date
        toDatePicker.preferredDatePickerStyle = .wheels
        toDatePicker.frame = CGRect(x: 0, y: 130, width: 270, height: 100)

        alert.view.addSubview(fromDatePicker)
        alert.view.addSubview(toDatePicker)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let fromDate = fromDatePicker.date
            let toDate = toDatePicker.date

            // Update energy entries per room
            for i in 0..<self.roomEnergyDataList.count {
                let originalEntries = self.roomEnergyDataList[i].allEntries // 💡 You must keep all raw entries stored
                let filtered = self.filterEntries(originalEntries, from: fromDate, to: toDate)
                self.roomEnergyDataList[i].last7DaysEnergy = filtered
            }

            self.roomsEnegryTableView.reloadData()
        }))

        present(alert, animated: true, completion: nil)
    }

    func filterEntries(_ entries: [EnergyEntry], from fromDate: Date, to toDate: Date) -> [EnergyEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return entries.filter { entry in
            guard let entryDate = dateFormatter.date(from: entry.date) else {
                return false
            }
            return entryDate >= fromDate && entryDate <= toDate
        }
    }

    
    func registerXib(){
        let uiNib =  UINib(nibName: "EnergyTableViewCell", bundle: nil)
        roomsEnegryTableView.register(uiNib, forCellReuseIdentifier: "EnergyTableViewCell")
    }
    
    func fetchRoomsForSelectedHome(homeId: String) {
        SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { fetchedRooms in
            
            print("fetchedRooms:", fetchedRooms)
            
            let mappedRooms = fetchedRooms.map { roomTuple in
                print("  mapping room:", roomTuple.roomName, roomTuple.roomIconType)
                
                let matchingIcon = self.roomsIconType
                    .first { $0.name == roomTuple.roomIconType }?
                    .image ?? "default_image"
                
                return Room(
                    name: roomTuple.roomName,
                    imageName: matchingIcon,
                    roomId: roomTuple.roomId,
                    homeId: homeId
                )
            }
            
            DispatchQueue.main.async {
                self.rooms = mappedRooms  // ✅ Assign to the array
                self.roomsEnegryTableView.reloadData()  // ✅ Refresh the table

               
            }
        }
    }
    
    
    func fetchEnergyForDateRange(homeId: String, completion: @escaping (EnergyConsumptionResponse?) -> Void) {
        let url = URL(string: MainApi.url("skroman/getEnergyConsumption"))!
        let (startDate, endDate) = getDateRange()
        
        let requestBody = EnergyRequestBody(homeId: homeId, startdate: startDate, enddate: endDate)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let bodyData = try JSONEncoder().encode(requestBody)
            request.httpBody = bodyData
        } catch {
            print("❌ Failed to encode request body:", error)
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Request error:", error)
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(nil)
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(EnergyConsumptionResponse.self, from: data)
                completion(decoded)
            } catch {
                print("❌ Decoding error:", error)
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func fetchLiveEnergyConsumption(for homeId: String, completion: @escaping (HomeEnergyResponse?) -> Void) {
        let urlString = MainApi.url("skroman/liveEnergyConsumptionForHomeRoomDevice/\(homeId)")

        AF.request(urlString, method: .get)
            .validate()
            .responseDecodable(of: HomeEnergyResponse.self) { response in
                switch response.result {
                case .success(let data):
                    print("✅ Energy Data: \(data)")
                    completion(data)
                case .failure(let error):
                    print("❌ Error: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }


}

extension EnergyViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "EnergyTableViewCell") as! EnergyTableViewCell

        guard indexPath.row < rooms.count else {
            return cell
        }

        let room = rooms[indexPath.row]

        if let energyData = roomEnergyDataList.first(where: { $0.roomId == room.roomId }) {

            let totalEnergy = energyData.last7DaysEnergy.reduce(0) { $0 + $1.value }
            cell.configure(with: room, energy: totalEnergy)

        } else {

            cell.configure(with: room, energy: 0.0)
        }

        return cell
    }



    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 5
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let spacer = UIView()
        spacer.backgroundColor = .clear // or your background color
        return spacer
    }

}
 

struct EnergyConsumptionResponse: Codable {
    let msg: String
    let data: EnergyData
}

// MARK: - Main data block
struct EnergyData: Codable {
    let homeId: String
    let totalHomeEnergyConsumption: [EnergyEntry]
    let rooms: [RoomEnergy]
    let totalHomeEnergy: Double
    
}

// MARK: - Individual energy entry (date + value)
struct EnergyEntry: Codable {
    let date: String
    let value: Double
}

// MARK: - Room-level energy data
struct RoomEnergy: Codable {
    let roomId: String
    let totalRoomEnergyConsumption: Double
    let devices: [DeviceEnergy]
    let totalEnergyConsumption: [EnergyEntry]
}

// MARK: - Device (empty array in current data)
struct DeviceEnergy: Codable {
     
}
struct EnergyRequestBody: Codable {
    let homeId: String
    let startdate: String
    let enddate: String
}
 

struct RoomEnergyData {
    let roomId: String
    let allEntries: [EnergyEntry]
    var last7DaysEnergy: [EnergyEntry]
}
