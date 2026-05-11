//
//  FavouriteButtonViewController.swift
//  SkromanIsra
//
//  Created by Admin on 04/06/25.
//



import UIKit
 import Alamofire


protocol FavouriteButtonCellDelegate: AnyObject {
    func didToggleShortcutSelection(cell: FavouriteButtonCollectionViewCell)
}


class FavouriteButtonViewController: UIViewController, FavouriteButtonCellDelegate {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var buttonsCollectionView: UICollectionView!
    
    var roomList =  ["kitchen","living", "bed1","bed 2", "curtain"]
    
    var rooms: [Room] = []
    var combinedFavouriteButtons: [ButtonDetails] = []
    var allDevices: [Device] = []

    var buttonDetails: [ButtonDetails] = []
    var deviceStateArray: [DeviceState] = []
    var favouriteButtonItems: [FavouriteButtonWithState] = []
    var currentHomeId: String = ""
    var  homeId: String?
    var homeFavIndexPaths: [IndexPath] = []
    

    @IBOutlet weak var saveBtn: UIButton!
    var selectedShortcutCells: [IndexPath] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        registerxib()
        
        saveBtn.backgroundColor = .white
        saveBtn.setTitleColor(.black, for: .normal)
        saveBtn.layer.cornerRadius = 8
        saveBtn.clipsToBounds = true
       
       
        guard let homeId = homeId else {
            print("❌ homeId is nil")
            return
        }
        
        print("📡 Fetching favourite buttons for homeId: \(homeId)")
        
        fetchFavouriteButtonsByHomeId(homeId: homeId) { [weak self] items in
            guard let self = self else { return }
            self.favouriteButtonItems = items
            self.buttonsCollectionView.reloadData()
        }
        let favVC = FavouriteButtonViewController()
        favVC.currentHomeId = homeId
    }

    func registerxib(){
        let uinib = UINib(nibName: "FavouriteButtonCollectionViewCell", bundle: nil)
        buttonsCollectionView.register(uinib, forCellWithReuseIdentifier: "FavouriteButtonCollectionViewCell")
        
        buttonsCollectionView.dataSource = self
        buttonsCollectionView.delegate =  self
        
    }
    
 
    
    @IBAction func saveButton(_ sender: Any) {
        var addList: [String] = []
        var removeList: [String] = []

        for (index, item) in favouriteButtonItems.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            let isCurrentlySelected = selectedShortcutCells.contains(indexPath)
            let wasInitiallyFav = item.button.isHomeFav == 1

            let serverId = item.button.deviceServerId

            if isCurrentlySelected && !wasInitiallyFav {
                addList.append(serverId)
            } else if !isCurrentlySelected && wasInitiallyFav {
                removeList.append(serverId)
            }
        }

        updateHomeFavStatus(addList: addList, removeList: removeList) { success, message in
            DispatchQueue.main.async {
                if success {
                    self.applyHomeFavToLocalDatabase(addList: addList, removeList: removeList)
                    NotificationCenter.default.post(name: .homeFavouritesDidChange, object: nil)
                }
                self.showToast(message: message) {
                    if success {
                        print("✅ Navigating back to Home after success")
                        self.navigateToHomeView()
                    }
                }
            }
        }
    }
    
    private func applyHomeFavToLocalDatabase(addList: [String], removeList: [String]) {
        for serverId in addList {
            SkromanIsraDatabaseHelper.shared.updateIsHomeFav(deviceServerId: serverId, isHomeFav: 1)
        }
        for serverId in removeList {
            SkromanIsraDatabaseHelper.shared.updateIsHomeFav(deviceServerId: serverId, isHomeFav: 0)
        }
    }


    func showToast(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        self.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true) {
                completion?()
            }
        }
    }
    private func navigateToHomeView() {
        // If you used storyboard segue or navigation stack
        if let nav = self.navigationController {
            for controller in nav.viewControllers {
                if controller is MainHomeViewController {
                    nav.popToViewController(controller, animated: true)
                    return
                }
            }
            // If not found, fallback to pop root
            nav.popToRootViewController(animated: true)
        }
    }

    
    
    
    @IBAction func backbutton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func fetchFavouriteButtonsByHomeId(homeId: String, completion: @escaping ([FavouriteButtonWithState]) -> Void) {
        var buttonWithStates: [FavouriteButtonWithState] = []
        var deviceStates: [DeviceState] = []

        SkromanIsraDatabaseHelper.shared.fetchDevicesByHomeId(homeId: homeId) { devices in
            print("🧩 Devices found for homeId \(homeId): \(devices.count)")
            self.allDevices = devices

            for device in devices {
                let uniqueId = device.uniqueId

                let buttons = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
                let favourites = buttons.filter { $0.isFavourite == 1 }
                let ishomeFva =  buttons.filter { $0.isHomeFav == 1 }
            print ("ishomeFva\(ishomeFva)")

                if !favourites.isEmpty {
                    print("✅ Favourite buttons for uniqueId \(uniqueId):")

                    if let state = SkromanIsraDatabaseHelper.shared.fetchDeviceStateByUniqueId(uniqueId: uniqueId) {
                        deviceStates.append(state)

                        for fav in favourites {
                            

                            print("🔹 Button ID: \(fav.buttonId), Name: \(fav.buttonName), Icon: \(fav.buttonIconName), ControlName: \(fav.buttonControlName), Room: \(fav.roomName)")
                            buttonWithStates.append(FavouriteButtonWithState(button: fav, state: state))
                        }
                    } else {
                        print("⚠️ No device state for device: \(uniqueId)")
                    }
                }
            }

            DispatchQueue.main.async {
                print("📦 Total Favourite Buttons with state: \(buttonWithStates.count)")
                self.deviceStateArray = deviceStates
                self.combinedFavouriteButtons = buttonWithStates.map { $0.button }

               
                self.favouriteButtonItems = buttonWithStates

                // 🏷️ Preselect cells with isHomeFav == 1
                self.selectedShortcutCells = []

                for (index, item) in self.favouriteButtonItems.enumerated() {
                    if item.button.isHomeFav == 1 {
                        let indexPath = IndexPath(item: index, section: 0)
                        self.selectedShortcutCells.append(indexPath)
                    }
                }

                // 🔁 Reload collection view
                self.buttonsCollectionView.reloadData()
            }

        }
    }
    
    func didToggleShortcutSelection(cell: FavouriteButtonCollectionViewCell) {
        guard let indexPath = buttonsCollectionView.indexPath(for: cell) else { return }

        if selectedShortcutCells.contains(indexPath) {
            // 🔄 Deselect
            if let index = selectedShortcutCells.firstIndex(of: indexPath) {
                selectedShortcutCells.remove(at: index)
            }
        } else {
            // ✅ Check max limit
            if selectedShortcutCells.count >= 4 {
                showToast(message: "You can select only 4 shortcuts")
                return
            }
            selectedShortcutCells.append(indexPath)
        }

        buttonsCollectionView.reloadItems(at: [indexPath])
    }


    func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        self.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    
    func updateHomeFavStatus(addList: [String], removeList: [String], completion: @escaping (Bool, String) -> Void) {
        let url = MainApi.url("skroman/buttondetails/manageHomeFav")

        let parameters: [String: Any] = [
            "addHomeFav": addList,
            "removeHomeFav": removeList
        ]

        print ("paramters ar \(parameters)")
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
            // Add token if needed: "Authorization": "Bearer YOUR_TOKEN"
        ]

        AF.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: UpdateHomeFavResponse.self) { response in
                switch response.result {
                case .success(let result):
                    print("✅ API Success:", result)
                    completion(true, result.msg)
                case .failure(let error):
                    print("❌ API Error:", error)
                    completion(false, error.localizedDescription)
                }
            }
    }
   


    

}

extension FavouriteButtonViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
   

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favouriteButtonItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavouriteButtonCollectionViewCell", for: indexPath) as! FavouriteButtonCollectionViewCell

        let item = favouriteButtonItems[indexPath.item]
        let matchedDevice = allDevices.first(where: { $0.uniqueId == item.button.uniqueId })

        cell.delegate = self

        let isSelected = selectedShortcutCells.contains(indexPath)
        cell.isShortcutSelected = isSelected
        cell.isshortcutImage.image = isSelected ? UIImage(named: "isSelected") : nil
        cell.isshortcutImage.isHidden = !isSelected
        cell.isShortcutSelect.isHidden = !isSelected

        cell.configure(with: item.button, device: matchedDevice, deviceState: item.state)

        return cell
    }







    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let leftInset: CGFloat = 8
        let rightInset: CGFloat = 8
        let spacing: CGFloat = 8
        let columns: CGFloat = 2

        let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let cellWidth = availableWidth / columns

        return CGSize(width: cellWidth, height: 100)
    }
}

  
extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self
        }
    }
}


struct FavouriteButtonWithState {
    let button: ButtonDetails
    let state: DeviceState?
}

struct UpdateHomeFavResponse: Decodable {
    let msg: String
    let addHomeFavCount: Int
    let removeHomeFavCount: Int
}
