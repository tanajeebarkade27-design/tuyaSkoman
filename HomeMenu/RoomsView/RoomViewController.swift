import UIKit
 import Alamofire

class RoomViewController: UIViewController {

    @IBOutlet weak var menubarview: UIView!
    @IBOutlet var MainBackgroundView: UIView!
    @IBOutlet weak var roomTableView: UITableView!
    @IBOutlet weak var HomeNameLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addRoomButton: UIButton!
    
    @IBOutlet weak var roomColloctionBackView: UIView!
    
    @IBOutlet weak var roomsCollectionView: UICollectionView!
    var isFetchingRooms = false
    var roomName: String?
    var roomImageName: String?
    var homeSeriverId : String?
    
    var homeName : String?
    var rooms: [Room] = []

    
    var bottomSheetView: UIView!
    var roomSettingLabel: UILabel!
    var closeButton: UIButton!
    var editRoomButton: UIButton!
    var deleteRoomButton: UIButton!
    var separatorLine: UIView!
    var addDeviceButton : UIButton!
    var selectedRoomId: String?
    var selectedHomeId: String?
    var selectedRoomName : String?
    

        
    
    let roomsIconType: [RoomIconType] = [
        RoomIconType(name: "Study Room", image: "study-room1"),
        RoomIconType(name: "Bed Room", image: "bedroom"),
        RoomIconType(name: "Theater", image: "theater"),
        RoomIconType(name: "Balcony", image: "balcony"),
        RoomIconType(name: "Dining Hall", image: "table"),
        RoomIconType(name: "Living Room", image: "living_room_1"),
        RoomIconType(name: "Other Room", image: "living_room_1"),
        RoomIconType(name: "Garden", image: "garden_2"),
        RoomIconType(name: "Gate", image: "gate"),
        RoomIconType(name: "Kitchen", image: "kitchen"),
        RoomIconType(name: "Lift", image: "lift_1"),
        RoomIconType(name: "Staircase", image: "staircase 1")
    ]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("", for: .normal)
        addRoomButton.setTitle("", for: .normal)
        reusableCell()
        roomTableView.dataSource = self
        roomTableView.delegate = self
//        roomsCollectionView.dataSource =  self
//        roomsCollectionView.delegate =  self
        setupBottomSheet()
        guard let originalImage = UIImage(named: "plus") else {
            print("Image not found!")
            return
        }
        let targetSize = addRoomButton.bounds.size
        if let resizedImage = resizeImage(image: originalImage, targetSize: targetSize) {
            addRoomButton.setImage(resizedImage, for: .normal)
            addRoomButton.imageView?.contentMode = .scaleAspectFit
        }
        if rooms.isEmpty { // Ensure it doesn't fetch again if data is already loaded
                fetchRooms(homeId: homeSeriverId ?? "")
            }
      print("roomName-\(roomName)")
        applyGradientBackground()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyGradientBackground()
    }
    
    
    func applyGradientBackground() {
        let mainScreen = CAGradientLayer()
        mainScreen.frame = MainBackgroundView.bounds

        if traitCollection.userInterfaceStyle == .dark {
            // Dark Mode: Futuristic Tech Theme (Deep Blue to Dark Gray)
            mainScreen.colors = [
                UIColor(red: 10/255, green: 25/255, blue: 50/255, alpha: 1).cgColor,  // #0A1932 (Deep Blue)
                UIColor(red: 46/255, green: 46/255, blue: 46/255, alpha: 1).cgColor   // #2E2E2E (Dark Gray)
            ]
        } else {
           
            mainScreen.colors = [
                UIColor(red: 180/255, green: 240/255, blue: 255/255, alpha: 1).cgColor, // #B4F0FF (Soft Cyan)
                UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor  // #E6E6E6 (Light Silver)
            ]
        }

        mainScreen.startPoint = CGPoint(x: 0, y: 0)  // Top-left corner
        mainScreen.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right corner

        // Remove existing gradient layers before adding a new one
        MainBackgroundView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        MainBackgroundView.layer.insertSublayer(mainScreen, at: 0)
    }

    
    func fetchRooms(homeId: String) {
        guard !isFetchingRooms else {
            print("Already fetching rooms, skipping request")
            return
        }
        
        isFetchingRooms = true
        print("Fetching rooms for homeId: \(homeId)")

        SkromanIsraDatabaseHelper.shared.fetchRoomsByHomeId(homeServerId: homeId) { [weak self] fetchedRooms in
            guard let self = self else { return }
            self.isFetchingRooms = false

            print("fetchRoomsByHomeId callback executed")

            self.rooms = fetchedRooms.map { roomData in
                let matchingIcon = self.roomsIconType.first { $0.name == roomData.roomIconType }?.image ?? "default_image"
                print("roomData.roomId att \(roomData.roomId)")
                return Room(name: roomData.roomName, imageName: matchingIcon, roomId: roomData.roomId, homeId: homeId)
            }

            DispatchQueue.main.async {
                self.roomTableView.reloadData()
            }
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        fetchRooms(homeId: homeSeriverId ?? "")
    }
    
    
    func reusableCell() {
               let uiNib = UINib(nibName: "RoomTableViewCell", bundle: nil)
               roomTableView.register(uiNib, forCellReuseIdentifier: "RoomTableViewCell")
//        let uiNib =  UINib(nibName: "RoomsCollectionViewCell", bundle: nil)
//        roomsCollectionView.register(uiNib, forCellWithReuseIdentifier: "RoomsCollectionViewCell")
    }
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func addRoomButton(_ sender: Any) {
        let addRoomVc =  storyboard?.instantiateViewController(withIdentifier: "AddRoomViewController") as! AddRoomViewController
        addRoomVc.homeServerId = homeSeriverId
        navigationController?.pushViewController(addRoomVc, animated: true)
    }
    
    
    
    private func setupBottomSheet() {
           let screenWidth = view.frame.width
           let bottomSheetHeight: CGFloat = 300

           // Initialize Bottom Sheet View
           bottomSheetView = UIView()
           bottomSheetView.backgroundColor = .white
           bottomSheetView.layer.cornerRadius = 12
           bottomSheetView.layer.shadowColor = UIColor.black.cgColor
           bottomSheetView.layer.shadowOpacity = 0.2
           bottomSheetView.layer.shadowOffset = CGSize(width: 0, height: -3)
           bottomSheetView.layer.shadowRadius = 5
           bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(bottomSheetView)

           // Room Setting Label
           roomSettingLabel = UILabel()
           roomSettingLabel.text = "Room Settings"
           roomSettingLabel.font = UIFont.boldSystemFont(ofSize: 16)
           roomSettingLabel.textColor = .black

           // Close Button
           closeButton = UIButton(type: .system)
           closeButton.setTitle("✕", for: .normal)
           closeButton.setTitleColor(.black, for: .normal)
           closeButton.addTarget(self, action: #selector(closeBottomSheet), for: .touchUpInside)

           // Separator Line
           separatorLine = UIView()
           separatorLine.backgroundColor = .lightGray

           // Create Buttons
           editRoomButton = createCustomButton(title: "Edit Room", subtitle: "Modify room details", imageName: "edit_icon")
           deleteRoomButton = createCustomButton(title: "Delete Room", subtitle: "Remove this room", imageName: "delete_icon")
           addDeviceButton = createCustomButton(title: "Add Device", subtitle: "Add new device", imageName: "add_icon")

           // Button Actions
           editRoomButton.addTarget(self, action: #selector(editRoomAction), for: .touchUpInside)
           deleteRoomButton.addTarget(self, action: #selector(deleteRoomAction), for: .touchUpInside)
           addDeviceButton.addTarget(self, action: #selector(addDeviceAction), for: .touchUpInside)

           // Apply Styling
           styleButton(editRoomButton)
           styleButton(deleteRoomButton)
           styleButton(addDeviceButton)

           // Stack View for Buttons
           let stackView = UIStackView(arrangedSubviews: [editRoomButton, deleteRoomButton, addDeviceButton])
           stackView.axis = .vertical
           stackView.spacing = 15
           stackView.distribution = .fillEqually

           // Add Subviews
           bottomSheetView.addSubview(roomSettingLabel)
           bottomSheetView.addSubview(closeButton)
           bottomSheetView.addSubview(separatorLine)
           bottomSheetView.addSubview(stackView)

           // Constraints
           applyBottomSheetConstraints(stackView: stackView, bottomSheetHeight: bottomSheetHeight)

           // Hide Initially (For Animation)
           bottomSheetView.frame = CGRect(x: 0, y: view.frame.height, width: screenWidth, height: bottomSheetHeight)
       }

    func createCustomButton(title: String, subtitle: String, imageName: String) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .left

        let iconImageView = UIImageView(image: UIImage(named: imageName))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .gray

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 10
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
   
        mainStack.isUserInteractionEnabled = false // Prevent mainStack from blocking touches

        button.addSubview(mainStack)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true

        // Set constraints to make the button fully cover the mainStack
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: button.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: button.bottomAnchor),

            button.heightAnchor.constraint(equalToConstant: 50) // Ensure enough height for tapping
        ])

        return button
    }
       private func styleButton(_ button: UIButton) {
           button.layer.borderWidth = 1
           button.layer.borderColor = UIColor.lightGray.cgColor
           button.layer.cornerRadius = 8
           button.clipsToBounds = true
       }

       private func applyBottomSheetConstraints(stackView: UIStackView, bottomSheetHeight: CGFloat) {
           bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
           roomSettingLabel.translatesAutoresizingMaskIntoConstraints = false
           closeButton.translatesAutoresizingMaskIntoConstraints = false
           separatorLine.translatesAutoresizingMaskIntoConstraints = false
           stackView.translatesAutoresizingMaskIntoConstraints = false

           NSLayoutConstraint.activate([
               // Bottom Sheet Constraints
               bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               bottomSheetView.heightAnchor.constraint(equalToConstant: bottomSheetHeight),
               bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomSheetHeight),

               // Room Setting Label
               roomSettingLabel.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 15),
               roomSettingLabel.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),

               // Close Button
               closeButton.centerYAnchor.constraint(equalTo: roomSettingLabel.centerYAnchor),
               closeButton.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),

               // Separator Line
               separatorLine.topAnchor.constraint(equalTo: roomSettingLabel.bottomAnchor, constant: 10),
               separatorLine.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
               separatorLine.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),
               separatorLine.heightAnchor.constraint(equalToConstant: 1),

               // Stack View (Buttons)
               stackView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 15),
               stackView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
               stackView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20)
           ])
       }

       // Show Bottom Sheet with Animation
    func showBottomSheet(roomId: String, homeId: String, roomName: String) {
        print("Inside showBottomSheet - Room ID: \(roomId), Home ID: \(homeId), Room Name: \(roomName)")
        
        self.selectedRoomId = roomId
        self.selectedHomeId = homeId
        self.selectedRoomName = roomName
        
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.transform = CGAffineTransform(translationX: 0, y: -300)
        }
    }



       // Hide Bottom Sheet with Animation
       @objc private func closeBottomSheet() {
           UIView.animate(withDuration: 0.3) {
               self.bottomSheetView.transform = .identity
           }
       }

       // Button Actions
       @objc private func editRoomAction() {
           print("Edit Room Clicked")
           closeBottomSheet()
       }

       @objc private func deleteRoomAction() {
           print("Delete Room Clicked")
           closeBottomSheet()
           Delete_rooms()
       }

       @objc private func addDeviceAction() {
           print("Add Device Clicked")
           closeBottomSheet()
           navigateToVersionVc()
       }
    
    
    func navigateToVersionVc(){
        let  versionVc =   storyboard?.instantiateViewController(identifier: "SelectversionViewController") as!
        SelectversionViewController
        versionVc.selectedRoomId = self.selectedRoomId
            versionVc.selectedHomeId = self.selectedHomeId
            versionVc.selectedRoomName = self.selectedRoomName
        versionVc.homeName =  homeName
        
        
        navigationController?.pushViewController(versionVc, animated: true)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
   
    
    func Delete_rooms() {
        guard let rooms_id =  selectedRoomId else { return }
        
        print("API : ==== ",rooms_id)
        
        let room_delete_parameters : Image_Parameters = [
        
            "roomId" : rooms_id
            
        ]
        
        AF.request("http://3.7.18.55:3000/skroman/roomapi/roomdelete", method: .post, parameters: room_delete_parameters, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                     
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if let parseJson = jsonOne,
                       let msg = parseJson["msg"] as? String
                       
                    {
                        if msg == "Delete the room successfully... " {
                            
                            self.showPopup()
                            
                           
                            self.roomTableView.reloadData()
                            
                        }
                        
                        else if msg == "Present the data on room in device First Delete the Devices" {
                            
                            self.showAlert(title: "Device found in this room", message: "Please delete the device first, than try to delete room.")
                            
                        }
//
                    }
                 
                    
                }
                catch {
                    print(error.localizedDescription)
                  
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
                
            }
            
        }.resume()
        
        
    }
    
    @objc func showPopup() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "success",
                                     title: "Success!",
                                     subtitle: " Room Deleted successfully")
        
       
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

}



//extension RoomViewController : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        rooms.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomsCollectionViewCell", for: indexPath) as! RoomsCollectionViewCell
//     
//
//        let room = rooms[indexPath.row]
//        cell.roomNameLabel.text = room.name
//        cell.selectedRoomId = room.roomId
//        cell.selectedHomeId =  room.homeId
//        cell.selectedRoomName = room.name
//        
//        cell.roomImageView.image = UIImage(named: room.imageName)
//        cell.parentVC = self
//            let spacingView = UIView(frame: CGRect(x: 0, y: cell.frame.height - 10, width: cell.frame.width, height: 10))
//            spacingView.backgroundColor = UIColor.clear // Keeps it invisible
//            cell.addSubview(spacingView)
//        
//        return cell
//    }
//    
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//           if indexPath.item == rooms.count {
//               print("Add Room button tapped")
//               //showAddRoomPopup()
//           } else {
//               print("Selected Room: \(rooms[indexPath.item].name)")
//           }
//       }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//            return CGSize(width: 150, height: 170)
//        }
//    
//}


extension RoomViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomTableViewCell", for: indexPath) as! RoomTableViewCell
        let room = rooms[indexPath.row]
        
        cell.roomaNamelLabel.text = room.name
        cell.selecetdRoomId = room.roomId
        cell.selectedHomeid = room.homeId
        cell.selectedRoomName =  room.name
        print("roomd id at cell\(room.roomId)")
        cell.roomIconImage.image = UIImage(named: room.imageName)
        cell.parentVC = self
            let spacingView = UIView(frame: CGRect(x: 0, y: cell.frame.height - 10, width: cell.frame.width, height: 10))
            spacingView.backgroundColor = UIColor.clear // Keeps it invisible
            cell.addSubview(spacingView)
        return cell
    }

    
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deviceVc = storyboard?.instantiateViewController(withIdentifier: "DeviceViewController") as!
        DeviceViewController
        let room = rooms[indexPath.row]
        deviceVc.roomId = room.roomId
        deviceVc.homeId =  room.homeId
        
        
        navigationController?.pushViewController(deviceVc, animated: true)
        
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let spacer = UIView()
       // spacer.backgroundColor = .clear
        return spacer
    }
  
    
}


struct Room {
    var name: String
    var imageName: String
    var roomId : String
    var homeId: String
    
}

struct RoomIconType
{
    let name: String
    let image: String
}
