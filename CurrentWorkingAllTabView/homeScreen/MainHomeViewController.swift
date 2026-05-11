//
//  MainHomeViewController.swift
//  SkromanIsra
//
//  Created by Admin on 27/05/25.
//

import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

protocol HomeMasterDelegate: AnyObject {
   func didChangehomeMasterState(to state: Int)
}


class MainHomeViewController: UIViewController{
    
    @IBOutlet weak var backgroudView: UIView!
    @IBOutlet weak var profileImageView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var backgroundbottomSheetView: UIView!
    @IBOutlet weak var slideButtonView: UIView!
    @IBOutlet weak var bottomSheetView: UIView!
    @IBOutlet weak var seeAlllButton: UIButton!
    @IBOutlet weak var engeryGraphImageView: UIImageView!
    @IBOutlet weak var selectedHomeImage: UIImageView!
    @IBOutlet weak var selectedHomeNamelabel: UILabel!
    
    @IBOutlet weak var totalActiveDeiveLabel: UILabel!
    
    @IBOutlet weak var barImageview: UIView!
    
    @IBOutlet weak var activeDeviceLabel: UILabel!
    
    @IBOutlet weak var engergyCountlabel: UILabel!
    
//    @IBOutlet weak var backgroundImageView: UIImageView!
  
    @IBOutlet weak var noRoomView: UIView!
    
    @IBOutlet weak var addroomView: UIView!
    
    
    @IBOutlet weak var backgroundimage: UIImageView!
    
    @IBOutlet weak var activeCount: UILabel!
    
    
    @IBOutlet weak var totalDeviceCount: UILabel!
    
    @IBOutlet weak var noRoomButtonView: UIView!
    
    
    @IBOutlet weak var exploreLabel: UILabel!
    
    @IBOutlet weak var sceneCollectionView: UICollectionView!
    
    @IBOutlet weak var shortcutCollectionView: UICollectionView!
    
    @IBOutlet weak var backgroundBottomSheetHeight: NSLayoutConstraint!
    
    @IBOutlet weak var energyunitLabel: UILabel!
    
    
    @IBOutlet weak var roomsCollectionView: UICollectionView!
    
    @IBOutlet weak var backgroundImageshow: UIImageView!
    
    var selectedHomeName: String?

    @IBOutlet weak var explorerRoomView: UIView!
    
    @IBOutlet weak var shortcutCollectionViewHeight: NSLayoutConstraint!
    
    
    var blurEffectView: UIVisualEffectView?
    var isExpanded = false
    var homeListpopupView: UIView!
    var isPopupVisible = false
    var homeListTableView: UITableView!
    var hasLaidOutSubviews = false
    private var emptyRoomsView: UIView?
    private var emptyshortcutView: UIView?
    
    var isDefaultHomeSelected = false
    var defaultHomeId: String?

    @IBOutlet weak var deviceCountView: UIView!
    
    var  passSelectedHomeName: String?
    var favouriteDevices: [FavouriteDeviceData] = []

    var allDevices: [Device] = []
    var homes: [Home] = []
    var rooms: [Room] = []
    var devices: [Device] = []
    
    var primaryHomes: [Home] = []
    var familyHomes: [Home] = []

    private var allHomeFavouriteButtons: [ButtonDetails] = []
    weak var delegate: HomeMasterDelegate?
    var  homeScene:  [String] = ["Scene 1", "Scene 2", "Scene 3", "Scene 4"]
    var homeSceneicon = ["scene1","Scene","scene3","scene4"]
   
    var receivedDeviceStates: [DeviceStateArray] = []
    var favouriteButtonsList: [FavouriteDeviceData] = []
    var flattenedFavouriteButtons: [FavouriteButtonItem] = []
    var flatList: [FavouriteButtonItem] = []
    var favouriteDeviceDataList: [FavouriteDeviceData] = []

    private var favouriteDeviceUids: Set<String> = []
    var connected = false
     
    var logTextView: UITextView!
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot:AWSIoT!
    var connectIoTDataWebSocket: UIButton!
    var connectButton: UIButton!
    var homeBottomSheetView: UIView!
    var homeSettingLabel: UILabel!
    var closeHomeButton: UIButton!
    var editHomeButton: UIButton!
    var deleteHomeButton: UIButton!
    var sheetseparatorLine: UIView!
    var addLocationButton :UIButton!
    var isGeoFenceEnabled: Bool = true
    var passEng : String?
    
    var tuyaHomeId : Int64?
    static var sharedSelectedHomeId: String?
    private var emptyHomeView: UIView?
        var selectedHomeid: String? {
            didSet {
                MainHomeViewController.sharedSelectedHomeId = selectedHomeid
            }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noRoomView.isHidden = true
        let homeVC = MainHomeViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: resizedImage(named: "home1btn"),
            selectedImage: resizedImage(named: "homebtn")
        )
        makeTabBarCapsuleStyle()
 
        let emaiildshow  =  KeychainWrapper.standard.string(forKey: "emailId") ?? ""
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        let userData =  SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
            print("userData at home: \(userData)")
            
        let homedata = SkromanIsraDatabaseHelper.shared.fetchAllHomesData()
        print ("homedata\(homedata)")
        
        if let user = userData.first {
               if let name = user.userName, !name.isEmpty {
                   let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                   let first = trimmed.split(whereSeparator: { $0.isWhitespace }).first.map(String.init)
                   usernameLabel.text = (first?.isEmpty == false) ? first : trimmed
               } else if let emailPrefix = KeychainWrapper.standard.string(forKey: "emailId")?.components(separatedBy: "@").first {
                   usernameLabel.text = emailPrefix.capitalized
               } else {
                   usernameLabel.text = "User"
               }
               
               if let imageUrlString = user.imageUser, let imageUrl = URL(string: imageUrlString) {
                   // Using URLSession for async image loading
                   URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                       guard let data = data, error == nil else { return }
                       DispatchQueue.main.async {
                           self.userImageView.image = UIImage(data: data)
                           self.userImageView.contentMode = .scaleAspectFill
                           self.userImageView.clipsToBounds = true
                           self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width / 2
                           self.userImageView.layer.masksToBounds = true
                           
                          
                       }

                   }.resume()
               } else {
                  
                   self.userImageView.image = UIImage(named: "user-4")
               }
           }
        
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSyncCompleted),
            name: .syncCompleted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onHomeAdded),
            name: .homeAdded,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAddHomePopupDismissed),
            name: .addHomePopupDismissed,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onHomeFavouritesDidChange),
            name: .homeFavouritesDidChange,
            object: nil
        )

        fetchHomesFromDatabase()
        
        
        backgroundimage.contentMode = .scaleAspectFill
        backgroundimage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundimage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundimage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundimage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundimage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        backgroundbottomSheetView.sendSubviewToBack(backgroundImageshow)
        backgroundImageshow.cornerRadius = 20
        backgroundImageshow.clipsToBounds =  true
        backgroundImageshow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageshow.leadingAnchor.constraint(equalTo: backgroundbottomSheetView.leadingAnchor),
            backgroundImageshow.trailingAnchor.constraint(equalTo: backgroundbottomSheetView.trailingAnchor),
            backgroundImageshow.topAnchor.constraint(equalTo: backgroundbottomSheetView.topAnchor),
            backgroundImageshow.bottomAnchor.constraint(equalTo: backgroundbottomSheetView.bottomAnchor)
        ])
        
        engeryGraphImageView.contentMode = .scaleAspectFill
        engeryGraphImageView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(engeryGraphImageView, belowSubview: deviceCountView)

        NSLayoutConstraint.activate([
            engeryGraphImageView.topAnchor.constraint(equalTo: deviceCountView.bottomAnchor, constant: 12),
            engeryGraphImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            engeryGraphImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            engeryGraphImageView.heightAnchor.constraint(equalToConstant: 180)
        ])
        backgroundBottomSheetHeight.constant = 550
        exploreLabel.numberOfLines = 2
        exploreLabel.lineBreakMode = .byWordWrapping
        exploreLabel.text = "Explore All"
        noRoomButtonView.cornerRadius = 12
        noRoomButtonView.borderWidth = 1
        noRoomButtonView.borderColor = .lightGray
      
     
         print("userDataat home \(userData)")
       
       
        seeAlllButton.isHidden = false

        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderColor = UIColor.systemGreen.cgColor
        profileImageView.layer.borderWidth = 2.0

        engeryGraphImageView.image = UIImage(named: "backgroundimage")

        //bottomSheetView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
       // explorerRoomView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        explorerRoomView.cornerRadius = 15
       
      
        NotificationCenter.default.addObserver(self, selector: #selector(onHomesSynced), name: .homesSynced, object: nil)
           fetchHomesFromDatabase()
    
        setupPopupView()
        registerXib()
       
        
        homeListpopupView.layer.cornerRadius = 10
        homeListpopupView.clipsToBounds = true

        bottomSheetView.layer.cornerRadius = 25
        bottomSheetView.clipsToBounds = true
        explorerRoomView.isUserInteractionEnabled = true
        slideButtonView.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSlideButtonTap))
        slideButtonView.addGestureRecognizer(tapGesture)
        
        let tapGestureProfile = UITapGestureRecognizer(target: self, action: #selector(navigateToprofile))
        profileImageView.addGestureRecognizer(tapGestureProfile)

        
        
        let tapGestureroom = UITapGestureRecognizer(target: self, action: #selector(navigateToRegistedRoom))
        explorerRoomView.addGestureRecognizer(tapGestureroom)

        

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        backgroundbottomSheetView.addGestureRecognizer(panGesture)
        backgroundbottomSheetView.isUserInteractionEnabled = true
       
        setupHomeBottomSheet()
        // Ensure MQTT is connected for global shortcut publishing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIoTConnectionRequested),
            name: .iotConnectionRequested,
            object: nil
        )
        connetion_aws_function()
        self.tabBarController?.delegate = self
        
        
        let tapGestureroomview = UITapGestureRecognizer(target: self, action: #selector(addRoomViewTapped))
            addroomView.isUserInteractionEnabled = true
            addroomView.addGestureRecognizer(tapGestureroomview)
        
       
    }
    
    
    @objc func onSyncCompleted() {
        print("🔁 Sync completed, refreshing homes...")
        fetchHomesFromDatabase()
        // Sync finished → remove blur overlay and show tab bar.
        hideBlurBackground()
        tabBarController?.tabBar.isHidden = false
    }

    @objc private func onHomesSynced() {
        print("🔁 Re-fetching homes after sync complete")
        fetchHomesFromDatabase()
    }
    
    @objc private func onHomeFavouritesDidChange() {
        guard let homeId = selectedHomeid else {
            print("⚠️ homeFavouritesDidChange — no selected home")
            return
        }
        print("🔁 Refreshing home shortcuts after favourite editor save")
        fetchDeviceByHomeId(homeId: homeId)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if homes.isEmpty {
            fetchHomesFromDatabase()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchHomesFromDatabase()
        if !connected {
            connetion_aws_function()
        }
        
        checkForUpdate()
        
        // After first layout pass, collection view has valid bounds — refresh grid height without animation (fixes missing cells on cold start).
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.shortcutCollectionView.collectionViewLayout.invalidateLayout()
            self.updateShortcutCollectionHeight(animated: false)
        }
    }
//    func checkAppUpdate() {
//
//        AppVersionChecker.checkForUpdate { isUpdateAvailable, latestVersion in
//
//            if isUpdateAvailable {
//                DispatchQueue.main.async {
//                    self.showUpdateAlert()
//                }
//            }
//        }
//    }
    
  
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

       
        let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
        backgroundBottomSheetHeight.constant = isExpanded ? safeAreaHeight * 1.04 : safeAreaHeight * 0.7

        backgroundImageshow.translatesAutoresizingMaskIntoConstraints = false
        backgroundbottomSheetView.addSubview(backgroundImageshow)
        backgroundbottomSheetView.sendSubviewToBack(backgroundImageshow)

       
        updateShortcutCollectionHeight(animated: false)

    }
    
    func checkForUpdate() {

        let bundleID = Bundle.main.bundleIdentifier ?? ""
        print("bundleID is \(bundleID)")
        
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleID)"
        
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let appStoreVersion = results.first?["version"] as? String {

                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

                let lastAlertedVersion = UserDefaults.standard.string(forKey: "lastAlertedVersion") ?? ""

                print("Current Version: \(currentVersion)")
                print("App Store Version: \(appStoreVersion)")
                print("Last Alerted Version: \(lastAlertedVersion)")

                if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending &&
                    appStoreVersion != lastAlertedVersion {

                    DispatchQueue.main.async {

                        // Save alerted version
                       

                        self.showUpdateAlert(
                            appStoreURL: "https://apps.apple.com/app/6757840982",
                            appStoreVersion: appStoreVersion
                        )
                    }
                }
            }

        }.resume()
    }
    func showUpdateAlert(appStoreURL: String, appStoreVersion: String) {
        
        let alert = UIAlertController(
            title: "Update Available",
            message: "A new version of the app is available. Please update to continue.",
            preferredStyle: .alert
        )

        let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
            
            // Save version so alert won't show again
            UserDefaults.standard.set(appStoreVersion, forKey: "lastAlertedVersion")
            
            if let url = URL(string: appStoreURL) {
                UIApplication.shared.open(url)
            }
        }

        let laterAction = UIAlertAction(title: "Later", style: .cancel) { _ in
            
            // Save version so alert won't show again
            UserDefaults.standard.set(appStoreVersion, forKey: "lastAlertedVersion")
        }

        alert.addAction(updateAction)
        alert.addAction(laterAction)

        present(alert, animated: true)
    }
    
    
    private func resizedImage(named name: String, size: CGSize = CGSize(width: 28, height: 28)) -> UIImage? {
        guard let image = UIImage(named: name) else {
            print("Image not found: \(name)")
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.withRenderingMode(.alwaysOriginal)
    }

    
    @IBAction func addRoomButton(_ sender: Any) {
        let newRoomvc =  storyboard?.instantiateViewController(identifier: "AddNewRoomViewController") as! AddNewRoomViewController
        newRoomvc.HomeId = selectedHomeid
        navigationController?.pushViewController(newRoomvc, animated: true)
    }
    
    @objc func addRoomViewTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addRoomVC = storyboard.instantiateViewController(withIdentifier: "AddNewRoomViewController") as? AddNewRoomViewController {
            addRoomVC.HomeId = self.selectedHomeid
            addRoomVC.homeName = self.selectedHomeName
            self.navigationController?.pushViewController(addRoomVC, animated: true)
        }
    }

    
    private func updateBottomSheetBackgroundImage(for height: CGFloat) {
        let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
        let collapsedHeight = safeAreaHeight * 0.7
        let expandedHeight = safeAreaHeight * 1.04
        
        if abs(height - collapsedHeight) < 5 {
           
            backgroundImageshow.image = UIImage(named: "bottomshteet")
            backgroundImageshow.isHidden = false
           
        } else if abs(height - expandedHeight) < 5 {
           
            backgroundImageshow.image = UIImage(named: "bottomsheetExtend")
            backgroundImageshow.isHidden = false
            
        } else {
            print("In-between height: no image change")
        }
    }




    func fetchHomesFromDatabase() {
        SkromanIsraDatabaseHelper.shared.fetchAllHomes { fetchedHomes in
            self.homes = fetchedHomes.map { homeTuple in

                Home(
                    homeServerId: homeTuple.homeServerId,
                    homeName: homeTuple.homeName,
                    homeUrl: homeTuple.homeUrl,
                    isFamilyHome: homeTuple.isFamilyHome,
                    tuyaHomeId: homeTuple.tuyaHomeId
                )
            }
            let primaryHomes = fetchedHomes.filter { $0.isFamilyHome == 0 }
                    let familyHomes  = fetchedHomes.filter { $0.isFamilyHome == 1 }

                    
                    self.homes = primaryHomes + familyHomes
            
            DispatchQueue.main.async {
                if self.homes.isEmpty {
                    print("Fetched 0 homes from DB")
                    
                    self.showEmptyHomeView()
                    
                    // hide unnecessary UI
                    self.bottomSheetView.isHidden = true
                    self.explorerRoomView.isHidden = true
                    self.sceneCollectionView.isHidden = true
                    self.shortcutCollectionView.isHidden = true
                    
                    return
                } else {
                    self.removeEmptyHomeView()
                    
                    self.bottomSheetView.isHidden = false
                    self.explorerRoomView.isHidden = false
                    self.sceneCollectionView.isHidden = false
                    self.shortcutCollectionView.isHidden = false
                }
                
                // Keep popup list in sync with current data.
                self.homeListTableView?.reloadData()

                var selectedHome: Home

                // ✅ Check if user has already selected a default home
                if self.isDefaultHomeSet(),
                   let savedHome = self.loadDefaultHome().id,
                   let matchedHome = self.homes.first(where: { $0.homeServerId == savedHome }) {
                    selectedHome = matchedHome
                    print("🏠 Using saved default home: \(matchedHome.homeName)")
                } else {
                    // ✅ Default to first home
                    selectedHome = self.homes.first!
                    print("🏠 Using first home as default: \(selectedHome.homeName)")
                    self.saveDefaultHome(id: selectedHome.homeServerId, name: selectedHome.homeName ?? "")
                }

                // ✅ Update UI
                self.tuyaHomeId =  selectedHome.tuyaHomeId
                self.selectedHomeNamelabel.text = selectedHome.homeName
                self.passSelectedHomeName = selectedHome.homeName
                self.selectedHomeid = selectedHome.homeServerId
                self.selectedHomeName = selectedHome.homeName
                if selectedHome.isFamilyHome == 1 {
                                self.addroomView.isHidden = true
                            } else {
                                self.addroomView.isHidden = false     
                            }
                // ✅ Fetch devices immediately (next run loop). Avoid arbitrary delay — was hiding shortcuts / Explore until tab switch.
                DispatchQueue.main.async {
                    self.fetchDeviceByHomeId(homeId: selectedHome.homeServerId)
                }

                self.fetchLiveEnergyConsumption(for: selectedHome.homeServerId) { response in
                    if let data = response {
                        print("Home ID: \(data.homeId)")
                        print("Total Consumption: \(data.totalHomeEnergyConsumption)")
                        self.engergyCountlabel.text = "\(data.totalHomeEnergyConsumption)"
                        self.passEng = "\(data.totalHomeEnergyConsumption)"
                        for room in data.roomEnergyConsumption {
                            print("Room: \(room.roomName), Energy: \(room.totalRoomEnergyConsumption)")
                        }
                    }
                }

                self.fetchRoomsForSelectedHome(homeId: selectedHome.homeServerId)
                self.homeListTableView.reloadData()
            }
        }
    }
    
    // MARK: - Default Home Helpers
    func saveDefaultHome(id: String, name: String) {
        UserDefaults.standard.set(id, forKey: "defaultHomeId")
        UserDefaults.standard.set(name, forKey: "defaultHomeName")
        UserDefaults.standard.set(true, forKey: "isDefaultHomeSelected")
        UserDefaults.standard.synchronize()
    }

    func loadDefaultHome() -> (id: String?, name: String?) {
        let id = UserDefaults.standard.string(forKey: "defaultHomeId")
        let name = UserDefaults.standard.string(forKey: "defaultHomeName")
        return (id, name)
    }

    func isDefaultHomeSet() -> Bool {
        return UserDefaults.standard.bool(forKey: "isDefaultHomeSelected")
    }


    func makeTabBarCapsuleStyle() {
        guard let tabBar = self.tabBarController?.tabBar else { return }

        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true
        tabBar.backgroundColor = UIColor.clear

        // Remove previous custom layers if any
        if let oldShapeLayer = tabBar.layer.sublayers?.first(where: { $0.name == "CustomTabBarShape" }) {
            oldShapeLayer.removeFromSuperlayer()
        }

        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "CustomTabBarShape"

        let bounds = tabBar.bounds.insetBy(dx: -10, dy: 5)
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.withAlphaComponent(0.25).cgColor  // Slightly transparent

        // Shadow (for floating effect)
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 3)
        shapeLayer.shadowOpacity = 0.2
        shapeLayer.shadowRadius = 8

        tabBar.layer.insertSublayer(shapeLayer, at: 0)
    }
    
    
    @objc private func handleCenterButtonNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let devices = userInfo["deviceList"] as? [String],
               let buttons = userInfo["buttonDetails"] as? [ButtonDetails],
            let receivedState = userInfo["receivedDeviceStates"] as? [DeviceStateArray] {
                print("📩 Received from tab bar button: \(devices), \(buttons)")
                 
            }
        }
    }
    
    func handleCenterButtonAction(devices: [Device]) {

        let receivedStates = self.receivedDeviceStates
        guard !receivedStates.isEmpty else { return }

        let ones = receivedStates.filter { $0.master == 1 }.count
        let zeros = receivedStates.filter { $0.master == 0 }.count

        let majorityState = ones >= zeros ? 1 : 0
        let toggleState = (majorityState == 1) ? 0 : 1

        let actionTitle = toggleState == 1 ? "Turn ON Master" : "Turn OFF Master"

        
        let alert = UIAlertController(
            title: "Confirm",
            message: "Are you sure you want to \(actionTitle)?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }

            for state in receivedStates {
                self.publish_button_to_topic(
                    control: "M",
                    no: 1,
                    state: toggleState,
                    speed: 1,
                    topic: state.uniqueID
                )
            }

            // success popup
            self.showPopupScene(state: toggleState)

            // update tab bar icon
            self.delegate?.didChangehomeMasterState(to: toggleState)
        }))

        self.present(alert, animated: true)
    }

    @objc func showPopupScene(state: Int) {
        let title = "Success!"
        let subtitle: String

        if state == 0 {
            subtitle = "Master Off"
        } else {
            subtitle = "Master On"
        }

        showPopupPresenter.showPopup1(
            on: self.view,
            animationName: "success",
            title: title,
            subtitle: subtitle
        )
    }
    
    func publish_button_to_topic(control: String, no: Int, state: Int, speed: Int, topic: String) {
        let parameters: Parameters = [
            "control": control,
            "no": no,
            "state": state,
            "speed": speed,
            "from": "A",
            "topic": topic
        ]

        print("📤 Publishing to \(topic)/HA/A/req: \(parameters)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    @IBAction func sellAllHomeButton(_ sender: Any) {
        isPopupVisible.toggle()

        if isPopupVisible {
            showPopupWithBlur()
            homeListpopupView.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.homeListpopupView.alpha = 1
            }
        } else {
            
            UIView.animate(withDuration: 0.25, animations: {
                self.homeListpopupView.alpha = 0
                self.blurEffectView?.alpha = 0
            }) { _ in
                self.homeListpopupView.isHidden = true
                self.hideBlurBackground()
            }
        }
    }


    @IBAction func homeSettingButton(_ sender: Any) {
        showHomeBottomSheet(selectedHomeId: selectedHomeid ?? "", selectedHomeName: selectedHomeName ?? "")
    }
    


    func setupPopupView() {
        
        // Single surface color for panel + list (table uses .clear so no mismatch stripe).
        let homePopupPanelColor = UIColor.white.withAlphaComponent(0.14)
        
        // Set popup size to 350x200
        homeListpopupView = UIView(frame: CGRect(
            x: (view.frame.width - 350) / 2,
            y: (view.frame.height - 250) / 2,
            width: 350,
            height: 250
        ))
        homeListpopupView.backgroundColor = homePopupPanelColor
        homeListpopupView.layer.cornerRadius = 12
        homeListpopupView.layer.shadowColor = UIColor.black.cgColor
        homeListpopupView.layer.shadowOpacity = 0.3
        homeListpopupView.layer.shadowOffset = CGSize(width: 0, height: 2)
        homeListpopupView.layer.shadowRadius = 6
        homeListpopupView.alpha = 0
        homeListpopupView.isHidden = true

        // Add label at top-left
        let titleLabel = UILabel()
        titleLabel.text = "Select Desired Home"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        homeListpopupView.addSubview(titleLabel)

        // Close Button (top-right)
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("X", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(handleClosePopupButton), for: .touchUpInside)
        homeListpopupView.addSubview(closeButton)

        // Setup table view
        homeListTableView = UITableView(frame: .zero, style: .plain)
        homeListTableView.delegate = self
        homeListTableView.dataSource = self
        homeListTableView.backgroundColor = .clear
        homeListTableView.register(homeListTableViewCell.self, forCellReuseIdentifier: "Cell")
      
        homeListTableView.translatesAutoresizingMaskIntoConstraints = false
        
        homeListTableView.cornerRadius =  0
        homeListTableView.clipsToBounds = true
        homeListTableView.separatorStyle = .singleLine
        homeListTableView.separatorColor = UIColor.white.withAlphaComponent(0.18)
        homeListTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) // optional

        homeListpopupView.addSubview(homeListTableView)
       

       
        
        let addHomeLabel = UILabel()
        addHomeLabel.text = "New Home"
        addHomeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        addHomeLabel.textColor = .white
        addHomeLabel.translatesAutoresizingMaskIntoConstraints = false

        
        let addHomeButton = UIButton(type: .system)
        addHomeButton.setImage(UIImage(named: "addHome"), for: .normal)
       
        addHomeButton.translatesAutoresizingMaskIntoConstraints = false
        addHomeButton.contentMode = .scaleAspectFit
        addHomeButton.tintColor = .yellow
        addHomeButton.contentHorizontalAlignment = .fill
        addHomeButton.contentVerticalAlignment = .fill
        addHomeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        addHomeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        addHomeButton.addTarget(self, action: #selector(showAddHomePopup), for: .touchUpInside)
        // addHomeButton.addTarget(self, action: #selector(addNewHomeTapped), for: .touchUpInside)

        
        let addHomeStackView = UIStackView(arrangedSubviews: [addHomeLabel, addHomeButton])
        addHomeStackView.axis = .horizontal
        addHomeStackView.spacing = 8
        addHomeStackView.alignment = .center
        addHomeStackView.translatesAutoresizingMaskIntoConstraints = false

        homeListpopupView.addSubview(addHomeStackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: homeListpopupView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: homeListpopupView.leadingAnchor, constant: 12),

            closeButton.topAnchor.constraint(equalTo: homeListpopupView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: homeListpopupView.trailingAnchor, constant: -8),

            homeListTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            homeListTableView.leadingAnchor.constraint(equalTo: homeListpopupView.leadingAnchor),
            homeListTableView.trailingAnchor.constraint(equalTo: homeListpopupView.trailingAnchor),
            homeListTableView.bottomAnchor.constraint(equalTo: addHomeStackView.topAnchor, constant: -8),

            addHomeStackView.trailingAnchor.constraint(equalTo: homeListpopupView.trailingAnchor, constant: -12),
            addHomeStackView.bottomAnchor.constraint(equalTo: homeListpopupView.bottomAnchor, constant: -8)
        ])

        view.addSubview(homeListpopupView)
    }
    func showPopupWithBlur() {
        showBlurBackground()
        homeListpopupView.alpha = 1
        homeListpopupView.isHidden = false
        view.bringSubviewToFront(homeListpopupView)
    }

    // Handler for close button
    @objc func handleClosePopupButton() {
        // Hide popup
        homeListpopupView.isHidden = true
        homeListpopupView.alpha = 0

        // Remove blur effect from background
        hideBlurBackground()
    }


    
    @objc func navigateToprofile(){
        let menueprofile =  storyboard?.instantiateViewController(withIdentifier: "MenuViewController") as!
        MenuViewController
     
        
        navigationController?.pushViewController(menueprofile, animated: true)
        
    }
    
    
    @objc func navigateToRegistedRoom(){
        let registerRoomVc =  storyboard?.instantiateViewController(withIdentifier: "RegisteredRoomViewController") as!
        RegisteredRoomViewController
        registerRoomVc.slectedHomeId = self.selectedHomeid
        
        navigationController?.pushViewController(registerRoomVc, animated: true)
        
    }
    

    @objc func handleSlideButtonTap() {
        isExpanded.toggle()

      
        self.seeAlllButton.isHidden = self.isExpanded
        self.selectedHomeImage.isHidden = self.isExpanded
        self.selectedHomeNamelabel.isHidden = self.isExpanded
        self.barImageview.isHidden = self.isExpanded
        self.engergyCountlabel.isHidden = self.isExpanded
        self.totalActiveDeiveLabel.isHidden = self.isExpanded
        self.activeDeviceLabel.isHidden = self.isExpanded
        self.activeCount.isHidden = self.isExpanded
        self.totalDeviceCount.isHidden = self.isExpanded
        self.energyunitLabel.isHidden =  self.isExpanded

      
        let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
        let newHeight = isExpanded ? safeAreaHeight * 1.04 : safeAreaHeight * 0.7
        backgroundBottomSheetHeight.constant = newHeight

       
        updateBottomSheetBackgroundImage(for: newHeight)

     
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }


    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
        let minHeight = safeAreaHeight * 0.7
        let maxHeight = safeAreaHeight * 1.04// expanded

        switch gesture.state {
        case .changed:
            let newHeight = backgroundBottomSheetHeight.constant - translation.y
            backgroundBottomSheetHeight.constant = max(minHeight, min(maxHeight, newHeight))
            gesture.setTranslation(.zero, in: view)

           
            updateBottomSheetBackgroundImage(for: backgroundBottomSheetHeight.constant)

            UIView.animate(withDuration: 0.05) {
                self.view.layoutIfNeeded()
            }


        case .ended:
            // Determine if user intended to expand or collapse based on velocity
            let shouldExpand = velocity.y < 0
            backgroundBottomSheetHeight.constant = shouldExpand ? maxHeight : minHeight
            isExpanded = shouldExpand
            updateBottomSheetBackgroundImage(for: backgroundBottomSheetHeight.constant)
            seeAlllButton.isHidden = isExpanded
            selectedHomeImage.isHidden = isExpanded
            selectedHomeNamelabel.isHidden = isExpanded
            barImageview.isHidden = isExpanded
            engergyCountlabel.isHidden =  isExpanded
            totalActiveDeiveLabel.isHidden = isExpanded
            activeDeviceLabel.isHidden =  isExpanded
            energyunitLabel.isHidden =  isExpanded
            activeCount.isHidden =  isExpanded
            totalDeviceCount.isHidden =  isExpanded
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.view.layoutIfNeeded()
            }

        default:
            break
        }
    }
    func  registerXib(){
        let uinib =  UINib(nibName: "RoomsShCollectionViewCell", bundle: nil)
        roomsCollectionView.register(uinib, forCellWithReuseIdentifier: "RoomsShCollectionViewCell")
        let uinib1 =  UINib(nibName: "homeListTableViewCell", bundle: nil)
        homeListTableView.register(uinib1, forCellReuseIdentifier: "homeListTableViewCell")
        let uinib2 =  UINib(nibName: "ShortcutCollectionViewCell", bundle: nil)
        shortcutCollectionView.register(uinib2, forCellWithReuseIdentifier: "ShortcutCollectionViewCell")
        
        let uinib3 =  UINib(nibName: "ShortcutSceneCollectionViewCell", bundle: nil)
        sceneCollectionView.register(uinib3, forCellWithReuseIdentifier: "ShortcutSceneCollectionViewCell")
        
        shortcutCollectionView.dataSource =  self
        shortcutCollectionView.delegate =  self
        
        sceneCollectionView.dataSource = self
        sceneCollectionView.delegate =  self
        // Add left space before the first scene cell.
        sceneCollectionView.contentInset.left = 8
        sceneCollectionView.horizontalScrollIndicatorInsets.left = 8
        
        roomsCollectionView.dataSource = self
        roomsCollectionView.delegate =  self
        
        homeListTableView.dataSource =  self
        homeListTableView.delegate =  self
        
        
        
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
                print("mappedRooms:", mappedRooms.map { $0.name })
                self.rooms = mappedRooms
                self.roomsCollectionView.reloadData()

                // ✅ Change background image based on room count
                if self.rooms.isEmpty {
                    self.noRoomView.isHidden = false
                    self.roomsCollectionView.isHidden = true
                    self.engeryGraphImageView.image = UIImage(named: "zeroEnergyImage")
                    self.explorerRoomView.isHidden = true
                   
                } else {
                    self.engeryGraphImageView.image = UIImage(named: "backgroundimage")
                    self.roomsCollectionView.isHidden = false
                    self.explorerRoomView.isHidden = false
                    self.noRoomView.isHidden = true
                }

                if let firstRoom = self.rooms.first {
                    print("firstRoom:", firstRoom.name)
                    // self.fetchDevicesForSelectedRoom(roomId: firstRoom.roomId)
                }
            }
        }
    }
    
    
    
    

    let roomsIconType: [RoomIconType] = [
     
        RoomIconType(name: "Living Room", image: "Living Room"),
        RoomIconType(name: "Living Room 1", image: "Living Room 1"),
        RoomIconType(name: "Living Room 2", image: "Living Room 2"),
      
       
        RoomIconType(name: "Bed Room", image: "Bed"),
        RoomIconType(name: "Bed Room 1", image: "Bed Room 1"),
        RoomIconType(name: "Bed Room 2", image: "Bed Room 2"),
        
        RoomIconType(name: "Study Room", image: "study"),
        RoomIconType(name: "Kitchen", image: "Kitchen"),
        RoomIconType(name: "DiningHall", image: "Dining"),
       
        RoomIconType(name: "Wash Room", image: "Wash Room"),
        RoomIconType(name: "Wash Room 1", image: "Wash Room 1"),
        RoomIconType(name: "Wash Room 2", image: "Wash Room 2"),
        
        RoomIconType(name: "Toilet", image: "Wash Room"),
        RoomIconType(name: "Patio", image: "Patio"),
        RoomIconType(name: "Lobby", image: "lobby"),
        
        RoomIconType(name: "Balcony", image: "Balcony"),
        RoomIconType(name: "Garden", image: "garden"),
        RoomIconType(name: "Varanda", image: "Varanda"),
        
      
        RoomIconType(name: "Theater", image: "theater"),
        RoomIconType(name: "Lift", image: "lift"),
        RoomIconType(name: "Staircase", image: "Staircase"),
        
        RoomIconType(name: "Gate", image: "gate"),

        RoomIconType(name: "Other Room", image: "other")
        
    ]
    @objc func showAddHomePopup() {
        // Hide current popup and blur
        homeListpopupView.isHidden = true
        homeListpopupView.alpha = 0
        showBlurBackground()
        
        // Hide tab bar while popup is visible
        tabBarController?.tabBar.isHidden = true
        
        // Show AddHomePopupView
        let popupView = AddHomePopupView(frame: CGRect(
            x: (view.frame.width - 350) / 2,
            y: (view.frame.height - 250) / 2,
            width: 350,
            height: 250
        ))
        
        popupView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        popupView.delegate = self
        popupView.alpha = 0
        view.addSubview(popupView)
        view.bringSubviewToFront(popupView)
        
        UIView.animate(withDuration: 0.25) {
            popupView.alpha = 1
        }
    }

    private func showBlurBackground() {
        if blurEffectView == nil {
            let blurEffect = UIBlurEffect(style: .dark)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            blurView.alpha = 0
            view.addSubview(blurView)
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: view.topAnchor),
                blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            blurEffectView = blurView
        }
        
        if let blurView = blurEffectView {
            view.bringSubviewToFront(blurView)
            UIView.animate(withDuration: 0.2) {
                blurView.alpha = 1
            }
        }
    }
    
    private func hideBlurBackground() {
        guard let blurView = blurEffectView else { return }
        UIView.animate(withDuration: 0.2, animations: {
            blurView.alpha = 0
        }, completion: { _ in
            blurView.removeFromSuperview()
            self.blurEffectView = nil
        })
    }
    
    @objc private func onAddHomePopupDismissed() {
        hideBlurBackground()
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func onHomeAdded() {
        // Keep blur while syncing so user sees "syncing" overlay.
        showBlurBackground()
        tabBarController?.tabBar.isHidden = true
        
        // Immediately refresh from local DB (AddHomePopupView already inserted the home).
        fetchHomesFromDatabase()
        
        // Sync full data after successfully adding home.
        // IMPORTANT: don't wipe DB here, otherwise the newly inserted home can disappear
        // if backend sync doesn't include it immediately.
        syncServer()
    }

    
    func publishScene(to uniqueId: String, controlNo: String) {
        let topic = uniqueId
        
        let scenePubParameters: Parameters = [
            "control": "scene_control",
            "no": Int(controlNo) ?? 0,
            "from": "A",
            "topic": topic
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: scenePubParameters, options: []),
           let theJSONText = String(data: theJSONData, encoding: .ascii) {

            print("📤 Publishing to \(topic)/HA/A/req:\n\(theJSONText)")
            
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.publishString(theJSONText, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
        } else {
            print("Failed to create JSON for device:\(uniqueId)")
        }
    }

    
    @IBAction func allShortcutbutton(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "FavouriteButtonViewController")  as! FavouriteButtonViewController
        vc.rooms =  rooms
        vc.homeId =  selectedHomeid
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func updateShortcutCollectionHeight(animated: Bool = false) {

        let count = flattenedFavouriteButtons.count

        // Same logic as numberOfItemsInSection
        let itemCount: Int
        if count < 4 {
            itemCount = count + 1   // Add shortcut button
        } else {
            itemCount = 4
        }

        let columns: CGFloat = 2
        let cellHeight: CGFloat = 100
        let spacing: CGFloat = 8
        let topInset: CGFloat = 8
        let bottomInset: CGFloat = 8

        let rows = ceil(CGFloat(itemCount) / columns)

        let totalHeight =
            (rows * cellHeight) +
            ((rows - 1) * spacing) +
            topInset +
            bottomInset

        shortcutCollectionViewHeight.constant = totalHeight

        let applyLayout = {
            self.view.layoutIfNeeded()
            self.shortcutCollectionView.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: applyLayout)
        } else {
            UIView.performWithoutAnimation(applyLayout)
        }
    }

    
    func setupHomeBottomSheet() {
        let screenWidth = view.frame.width
        let bottomSheetHeight: CGFloat = 350

        homeBottomSheetView = UIView(frame: CGRect(x: 0, y: view.frame.height, width: screenWidth, height: bottomSheetHeight))
        homeBottomSheetView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        homeBottomSheetView.layer.cornerRadius = 12
        homeBottomSheetView.layer.shadowColor = UIColor.black.cgColor
        homeBottomSheetView.layer.shadowOpacity = 0.2
        homeBottomSheetView.layer.shadowOffset = CGSize(width: 0, height: -3)
        homeBottomSheetView.layer.shadowRadius = 5
        view.addSubview(homeBottomSheetView)

        // Labels & Buttons
        homeSettingLabel = UILabel()
        homeSettingLabel.text = "Home Settings"
        homeSettingLabel.font = UIFont.boldSystemFont(ofSize: 16)
        homeSettingLabel.textColor = .white
        homeSettingLabel.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(homeSettingLabel)

        closeHomeButton = UIButton()
        closeHomeButton.setTitle("✕", for: .normal)
        closeHomeButton.setTitleColor(.white, for: .normal)
        closeHomeButton.addTarget(self, action: #selector(closeHomeBottomSheet), for: .touchUpInside)
        closeHomeButton.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(closeHomeButton)

        sheetseparatorLine = UIView()
        sheetseparatorLine.backgroundColor = .lightGray
        sheetseparatorLine.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(sheetseparatorLine)

        // Action Buttons
        editHomeButton = createCustomHomeButton(title: "Edit Home", subtitle: "Edit home name & image", imageName: "edit 1")
        deleteHomeButton = createCustomHomeButton(title: "Delete Home", subtitle: "Remove this home", imageName: "delete")
        
       
        let addLocationButton = createCustomHomeButton(title: "Add Home Location", subtitle: "Geo fencing", imageName: "map")
        
        // Create the Toggle Button
        let toggleButton = UISwitch()
        toggleButton.isOn = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(toggleButtonChanged), for: .valueChanged)
        
        // Stack view for "Add Home Location" button and Toggle button
        let buttonWithToggleStackView = UIStackView(arrangedSubviews: [addLocationButton, toggleButton])
        buttonWithToggleStackView.axis = .horizontal
        buttonWithToggleStackView.spacing = 10
        buttonWithToggleStackView.alignment = .center
        buttonWithToggleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply styles to buttons
        stylesheetButton(editHomeButton)
        stylesheetButton(deleteHomeButton)
        stylesheetButton(addLocationButton)

        // Actions for buttons
        editHomeButton.addTarget(self, action: #selector(editHomeAction), for: .touchUpInside)
        deleteHomeButton.addTarget(self, action: #selector(deleteHomeAction), for: .touchUpInside)
        addLocationButton.addTarget(self, action: #selector(addLocationBtn), for: .touchUpInside)

        // Stack View for all buttons (with "Add Home Location" + toggle)
        let stackView = UIStackView(arrangedSubviews: [editHomeButton, deleteHomeButton, buttonWithToggleStackView])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        homeBottomSheetView.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            homeSettingLabel.topAnchor.constraint(equalTo: homeBottomSheetView.topAnchor, constant: 10),
            homeSettingLabel.leadingAnchor.constraint(equalTo: homeBottomSheetView.leadingAnchor, constant: 20),

            closeHomeButton.centerYAnchor.constraint(equalTo: homeSettingLabel.centerYAnchor),
            closeHomeButton.trailingAnchor.constraint(equalTo: homeBottomSheetView.trailingAnchor, constant: -20),

            sheetseparatorLine.topAnchor.constraint(equalTo: homeSettingLabel.bottomAnchor, constant: 5),
            sheetseparatorLine.leadingAnchor.constraint(equalTo: homeBottomSheetView.leadingAnchor, constant: 20),
            sheetseparatorLine.trailingAnchor.constraint(equalTo: homeBottomSheetView.trailingAnchor, constant: -20),
            sheetseparatorLine.heightAnchor.constraint(equalToConstant: 1),

            stackView.topAnchor.constraint(equalTo: sheetseparatorLine.bottomAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: homeBottomSheetView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: homeBottomSheetView.trailingAnchor, constant: -20)
        ])
    }

    @objc func toggleButtonChanged(sender: UISwitch) {
        if sender.isOn {
            print("Location is enabled")
            isGeoFenceEnabled = true
        } else {
            print("Location is disabled")
            isGeoFenceEnabled = false
        }
    }

    private func stylesheetButton(_ button: UIButton) {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
        }

        func createCustomHomeButton(title: String, subtitle: String, imageName: String) -> UIButton {
            let button = UIButton()
            button.backgroundColor = .clear
            button.contentHorizontalAlignment = .left
            button.translatesAutoresizingMaskIntoConstraints = false

            let iconImageView = UIImageView(image: UIImage(named: imageName))
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            iconImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            iconImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            titleLabel.textColor = .white

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
            mainStack.isUserInteractionEnabled = false

            button.addSubview(mainStack)

            NSLayoutConstraint.activate([
                mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                mainStack.topAnchor.constraint(equalTo: button.topAnchor),
                mainStack.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])

            return button
        }

    func showHomeBottomSheet(selectedHomeId: String, selectedHomeName: String) {
        print("selectedHomeId at btmsheet \(selectedHomeId)")

        // Add background image (if not already added)
        if view.viewWithTag(998) == nil {
            let backgroundImageView = UIImageView(frame: view.bounds)
            backgroundImageView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            backgroundImageView.image = UIImage(named: "Screen Background")
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundImageView.tag = 998
            view.addSubview(backgroundImageView)
        }

        guard let homeBottomSheetView = self.homeBottomSheetView else {
            print("❌ Bottom sheet not initialized!")
            return
        }

        // Bring bottom sheet to front
        view.bringSubviewToFront(homeBottomSheetView)

        // Animate sheet in
        UIView.animate(withDuration: 0.3) {
            homeBottomSheetView.frame.origin.y = self.view.frame.height - 350
        }
    }


    @objc func closeHomeBottomSheet() {
        UIView.animate(withDuration: 0.3, animations: {
            self.homeBottomSheetView.frame.origin.y = self.view.frame.height
        }) { _ in
            // ✅ Remove the background image after animation finishes
            self.view.viewWithTag(998)?.removeFromSuperview()
        }
    }


        // Actions
        @objc func editHomeAction() {
            print("Edit Home Clicked")
            closeHomeBottomSheet()
        }

    @objc func deleteHomeAction() {
        print("Delete Home Clicked")
        
        let alert = UIAlertController(title: "Delete Home",
                                      message: "Are you sure you want to delete this home?",
                                      preferredStyle: .alert)

        // Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("❌ Delete cancelled")
        }

       
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            print("✅ Home deleted")
            
            self.Delete_Home()
            self.closeHomeBottomSheet()
        }

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)

        self.present(alert, animated: true, completion: nil)
    }


    @objc func addLocationBtn() {
        print("Add Location Button Clicked")
        closeHomeBottomSheet()
        
        // Passing the toggle state to the GeofencViewController
        geoFenceVc(isGeoFenceEnabled: isGeoFenceEnabled)
    }
    
    
    func geoFenceVc(isGeoFenceEnabled: Bool) {
        let geoVc = storyboard?.instantiateViewController(identifier: "GeofencViewController") as! GeofencViewController
       // geoVc.homeId = self.selectedHomeId
        geoVc.isGeoFenceEnabled = isGeoFenceEnabled  // Pass the value of isGeoFenceEnabled
        navigationController?.pushViewController(geoVc, animated: true)
    }
    
    
    
    func Delete_Home() {
        
        
        guard let home_id = selectedHomeid else { return }
        
        // CONDITION: If any room is present in this home, do NOT delete the home.
        SkromanIsraDatabaseHelper.shared.fetchRoomCountByHomeId(homeServerId: home_id) { [weak self] count in
            guard let self else { return }
            if count > 0 {
                self.showPopupForRoomsPresent()
                return
            }
            
            self.performHomeDeleteRequest(home_id: home_id)
        }
    }
    
    private func performHomeDeleteRequest(home_id: String) {
        
        let delete_home_parameters: [String: Any] = [
            "homeId": home_id
        ]
        
        AF.request(MainApi.url("skroman/homeapi/homedelete"),
                   method: .post,
                   parameters: delete_home_parameters,
                   encoding: JSONEncoding.default,
                   headers: nil)
        .response { response in
            switch response.result {
            case .success(let data):
                guard let data = data else { return }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let msg = json["msg"] as? String {
                        
                        if msg == "Delete the home successfully... " {
                            print("✅ Home deleted successfully")
                            self.showPopupedit()
                            SkromanIsraDatabaseHelper.shared.deleteHomeCascadeFromLocal(homeServerId: home_id)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.fetchHomesFromDatabase()
                                self.homeListTableView.reloadData()
                            }
                        }
                        else if msg == "Present the data on Home in Room First Delete the Rooms " {
                            print("⚠️ Home has rooms — show popup")
                            self.showPopupForRoomsPresent()
                        }
                        else {
                            print("ℹ️ Unknown response message: \(msg)")
                        }
                    }
                } catch {
                    print("❌ JSON Parsing Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")
            }
        }
    }

    @objc func showPopupedit() {
        PopupPresenter.showPopup(
            on: self.view,
            animationName: "success",
            title: "Success!",
            subtitle: " Home Delete successfully"
        )
    }

    func showPopupForRoomsPresent() {
        let alert = UIAlertController(
            title: "Cannot Delete Home",
            message: "This home contains rooms. Please delete the rooms first.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}
extension MainHomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
        
    }
    
    private func showEmptyRoomsView() {
        if emptyRoomsView != nil { return }
        
        explorerRoomView.isHidden = true
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(white: 1.0, alpha: 0.05) // semi-dark
        container.layer.cornerRadius = 16
        container.layer.borderColor = UIColor.darkGray.cgColor
        container.layer.borderWidth = 1
        
        // Circle icon background
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        iconContainer.layer.cornerRadius = 24
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = UIColor.white.cgColor
        
        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.translatesAutoresizingMaskIntoConstraints = false
        plusIcon.tintColor = .white
        plusIcon.contentMode = .scaleAspectFit
        iconContainer.addSubview(plusIcon)
        
        // "Add a room to continue…" label
        let addRoomLabel = UILabel()
        addRoomLabel.translatesAutoresizingMaskIntoConstraints = false
        addRoomLabel.text = "Add a room to continue..."
        addRoomLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addRoomLabel.textColor = UIColor.green
        
        // "0 Rooms" label
        let subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "0 Rooms"
        subLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subLabel.textColor = UIColor.lightGray
        
        // Stack for labels
        let labelsStack = UIStackView(arrangedSubviews: [addRoomLabel, subLabel])
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .vertical
        labelsStack.spacing = 2
        
        // Horizontal stack
        let horizontalStack = UIStackView(arrangedSubviews: [iconContainer, labelsStack])
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 12
        
        container.addSubview(horizontalStack)
        view.addSubview(container)
        self.emptyRoomsView = container
        
        // Constraints
        NSLayoutConstraint.activate([
            // container covers both roomsCollectionView and explorerRoomView
            container.topAnchor.constraint(equalTo: roomsCollectionView.topAnchor),
            container.leadingAnchor.constraint(equalTo: roomsCollectionView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: roomsCollectionView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: explorerRoomView.bottomAnchor),
            
            // icon size
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            // plus icon center
            plusIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            plusIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            plusIcon.widthAnchor.constraint(equalToConstant: 20),
            plusIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // stack in container
            horizontalStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            horizontalStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
    private func showEmptyHomeView() {
        
        if emptyHomeView != nil { return }
        
        // Hide tab bar while showing empty-home overlay
        tabBarController?.tabBar.isHidden = true
        
        // MARK: - Blur Background
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(blurView)
        
        // MARK: - Container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: - Icon container
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        iconContainer.layer.cornerRadius = 35
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = UIColor.lightGray.cgColor
        
        // MARK: - Image (Add Home)
        let imageView = UIImageView(image: UIImage(named: "addHome"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemYellow
        
        iconContainer.addSubview(imageView)
        
        // MARK: - Labels
        let titleLabel = UILabel()
        titleLabel.text = "No Homes Found"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        
        let subLabel = UILabel()
        subLabel.text = "Tap to add your first home"
        subLabel.textColor = .lightGray
        subLabel.font = UIFont.systemFont(ofSize: 14)
        subLabel.textAlignment = .center
        
        // Stack
        let stack = UIStackView(arrangedSubviews: [iconContainer, titleLabel, subLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        // Put content INSIDE blur view so removing blur removes everything.
        blurView.contentView.addSubview(container)
        
        self.emptyHomeView = blurView   
        
        // MARK: - Tap Gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(emptyHomeTapped))
        blurView.addGestureRecognizer(tap)
        
        // MARK: - Constraints
        NSLayoutConstraint.activate([
          
            blurView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant:60),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            container.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
     
            
            // Stack center
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            // Icon size
            iconContainer.widthAnchor.constraint(equalToConstant: 70),
            iconContainer.heightAnchor.constraint(equalToConstant: 70),
            
            imageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    @objc private func emptyHomeTapped() {
        showAddHomePopup()
    }
    
    private func removeEmptyHomeView() {
        emptyHomeView?.removeFromSuperview()
        emptyHomeView = nil
        tabBarController?.tabBar.isHidden = false
    }
    
    private func showEmptyShortcutView() {
        
        if emptyshortcutView != nil { return }
        
        // Empty state only replaces the shortcut grid; keep "Explore All" visible when there are rooms.
        explorerRoomView.isHidden = rooms.isEmpty
        shortcutCollectionView.isHidden = true
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: - Icon Container
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        iconContainer.layer.cornerRadius = 12
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = UIColor.gray.cgColor
        
        // MARK: - Plus Icon
        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.translatesAutoresizingMaskIntoConstraints = false
        plusIcon.tintColor = .systemYellow
        plusIcon.contentMode = .scaleAspectFit
        iconContainer.addSubview(plusIcon)
        
        // MARK: - Labels
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Add shortcut Buttons"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .systemGreen
        
        let subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "0 buttons"
        subLabel.font = UIFont.systemFont(ofSize: 13)
        subLabel.textColor = .lightGray
        
        // MARK: - Stack Views
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalStack = UIStackView(arrangedSubviews: [iconContainer, labelStack])
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 12
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(horizontalStack)
        view.addSubview(container)
        
        // ✅ Store reference
        self.emptyshortcutView = container
        
        // MARK: - Tap Gesture (IMPORTANT)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(emptyShortcutTapped))
        container.isUserInteractionEnabled = true
        container.addGestureRecognizer(tapGesture)
        
        // MARK: - Constraints
        NSLayoutConstraint.activate([
            
            // Container fills collection area
            container.topAnchor.constraint(equalTo: shortcutCollectionView.topAnchor),
            container.leadingAnchor.constraint(equalTo: shortcutCollectionView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: shortcutCollectionView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: shortcutCollectionView.bottomAnchor),
            
            // Icon size
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            // Plus icon center
            plusIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            plusIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            plusIcon.widthAnchor.constraint(equalToConstant: 20),
            plusIcon.heightAnchor.constraint(equalToConstant: 20),
            
            // Stack position
            horizontalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 30),
            horizontalStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
    
    @objc private func emptyShortcutTapped() {
        print("Empty shortcut tapped")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let favVC = storyboard.instantiateViewController(withIdentifier: "FavouriteButtonViewController") as? FavouriteButtonViewController {
            
            favVC.homeId = selectedHomeid
            self.navigationController?.pushViewController(favVC, animated: true)
        }
    }
    
    private func removeEmptyRoomsView() {
        emptyRoomsView?.removeFromSuperview()
        emptyRoomsView = nil
        explorerRoomView.isHidden = false
    }
    
    @objc private func addRoomButtonTapped() {
        print("Add Room tapped")
        
    }
    
    
    func fetchDeviceByHomeId(homeId: String) {

        SkromanIsraDatabaseHelper.shared.fetchDevicesByHomeId(homeId: homeId) { devices in

            DispatchQueue.global(qos: .userInitiated).async {

                var favouriteDeviceDataList: [FavouriteDeviceData] = []
                var tempFlatList: [FavouriteButtonItem] = []

                for device in devices {

                    let uniqueId = device.uniqueId
                    let allButtons = SkromanIsraDatabaseHelper.shared.fetchButtonDetails(uniqueId: uniqueId)
                    let favButtons = allButtons.filter { $0.isHomeFav == 1 }

                    if !favButtons.isEmpty {
                        favouriteDeviceDataList.append(
                            FavouriteDeviceData(device: device, favouriteButtons: favButtons)
                        )

                        for button in favButtons {
                            tempFlatList.append(
                                FavouriteButtonItem(device: device, button: button)
                            )
                        }
                    }
                }

                DispatchQueue.main.async {

                    print("✅ FINAL DEVICE COUNT:", devices.count)

                    self.devices = devices
                    self.favouriteButtonsList = favouriteDeviceDataList
                    self.flattenedFavouriteButtons = tempFlatList

                   
                    self.totalDeviceCount.text = "\(devices.count)"

                   
                    self.receivedDeviceStates.removeAll()
                    self.subscribeToAllDevicesSerially(devices)

                    self.reloadShortcutUIOptimized()
                }
            }
        }
    }
    
    func reloadShortcutUIOptimized() {

        UIView.performWithoutAnimation {
            self.shortcutCollectionView.reloadData()
        }

        self.updateShortcutCollectionHeight(animated: false)
        self.updateShortcutUI()
    }

    func subscribeToAllDevicesSerially(_ devices: [Device], index: Int = 0) {
        guard index < devices.count else { return }

        let device = devices[index]
        print("⏳ Delayed subscribing to: \(device.uniqueId)")

        subscribeToTopic(for: device.uniqueId)

        // Delay next subscription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.subscribeToAllDevicesSerially(devices, index: index + 1)
        }
    }

    
    func subscribeToTopic(for uniqueId: String) {
        MQTTSubscriptionManager.shared.subscribeToAckIfNeeded(uniqueId: uniqueId) { [weak self] data in
            guard let self = self else { return }

            guard let jsonString = String(data: data, encoding: .utf8),
                  let jsonData = jsonString.data(using: .utf8) else {
                print("⚠️ Invalid payload")
                return
            }

            // Ack-only messages (e.g. {"ack":"MQTT disconnects"}) are not full device state — skip quietly.
            if let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               obj["unique_id"] == nil {
                return
            }

            let deviceState: DeviceStateArray
            do {
                deviceState = try JSONDecoder().decode(DeviceStateArray.self, from: jsonData)
            } catch {
                print("❌ Decode error:", error)
                return
            }

            // ✅ Update or insert state
            if let index = self.receivedDeviceStates.firstIndex(where: {
                $0.uniqueID == deviceState.uniqueID
            }) {
                self.receivedDeviceStates[index] = deviceState
            } else {
                self.receivedDeviceStates.append(deviceState)
            }

            // ✅ UPDATE ONLINE COUNT (CORRECT)
            let onlineCount = self.receivedDeviceStates.count
            self.activeCount.text = "\(onlineCount)"

            // ✅ UPDATE TOTAL COUNT (optional safety)
            self.totalDeviceCount.text = "\(self.devices.count)"

            // ✅ UPDATE UI (ONLY REQUIRED PART)
            if let index = self.flattenedFavouriteButtons.firstIndex(where: {
                $0.device.uniqueId == deviceState.uniqueID
            }) {
                self.shortcutCollectionView.performBatchUpdates {
                    self.shortcutCollectionView.reloadItems(at: [
                        IndexPath(item: index, section: 0)
                    ])
                }
            }

            print("✅ Updated:", deviceState.uniqueID, "ACK:", deviceState.ack)
        }

        // ✅ VERY IMPORTANT → REQUEST STATE AFTER SUBSCRIBE
        requestLatestDeviceState(topic: uniqueId)
    }
    func requestLatestDeviceState(topic: String) {
        let fetch_all_params: Parameters = [
            "control": "fetch_all",
            "no": 0,
            "state": 0,
            "speed": 0,
            "from": "A",
            "topic": topic
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: fetch_all_params, options: []) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Requesting latest state: \(jsonString)")

                let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
                iotDataManager.publishString(jsonString, onTopic: topic + "/HA/A/req", qoS: .messageDeliveryAttemptedAtMostOnce)
            }
        }
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

    func updateShortcutUI() {
        if flattenedFavouriteButtons.isEmpty {
            showEmptyShortcutView()
        } else {
            emptyshortcutView?.removeFromSuperview()
            emptyshortcutView = nil
            shortcutCollectionView.isHidden = false
            // Empty-shortcut placeholder hid explorer; restore when shortcuts exist (matches rooms row visibility).
            explorerRoomView.isHidden = rooms.isEmpty
        }
    }
    
    

}

extension MainHomeViewController: UITableViewDataSource, UITableViewDelegate {
    
   

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == homeListTableView {
            return homes.count
        }
 
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "homeListTableViewCell",
            for: indexPath
        ) as! homeListTableViewCell

        // Protect against async updates (delete/sync) causing stale index paths.
        guard homes.indices.contains(indexPath.row) else {
            cell.homeNameLabel.text = ""
            return cell
        }
        
        let home = homes[indexPath.row]

        // HOME NAME
        if home.isFamilyHome == 1 {
            cell.homeNameLabel.text = "\(home.homeName ?? "")  (Family Home)"
        } else {
            cell.homeNameLabel.text = home.homeName
        }

        return cell
    }




    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == homeListTableView {
            if indexPath.row == homes.count {
                print("Add New Home tapped")
                tableView.deselectRow(at: indexPath, animated: true)

                // Close popup
                isPopupVisible = false
                UIView.performWithoutAnimation {
                    self.view.layoutIfNeeded()
                }

                self.homeListpopupView.isHidden = true
                self.blurEffectView?.removeFromSuperview()
                self.blurEffectView = nil
                self.showAddHomePopup()
                return
            }

            let selectedHome = homes[indexPath.row]
            selectedHomeid = selectedHome.homeServerId
            selectedHomeNamelabel.text = selectedHome.homeName
            self.passSelectedHomeName = selectedHome.homeName

            
            if selectedHome.isFamilyHome == 1 {
                addroomView.isHidden = true
                } else {
                    addroomView.isHidden = false       // show for primary home
                }
            // ✅ Save as default home (set flag true)
            self.saveDefaultHome(id: selectedHome.homeServerId, name: selectedHome.homeName ?? "")
            print("🏠 Saved default home: \(selectedHome.homeName) [\(selectedHome.homeServerId)]")

            
            
            // ✅ Update image
            if let urlString = selectedHome.homeUrl,
               let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let data = data, error == nil {
                        DispatchQueue.main.async {
                            self.selectedHomeImage.image = UIImage(data: data)
                        }
                    }
                }.resume()
            }

            // ✅ Refresh data for this home
            fetchRoomsForSelectedHome(homeId: selectedHome.homeServerId)
            fetchDeviceByHomeId(homeId: selectedHome.homeServerId)
            fetchLiveEnergyConsumption(for: selectedHome.homeServerId) { response in
                if let data = response {
                    print("Home ID: \(data.homeId)")
                    print("Total Consumption: \(data.totalHomeEnergyConsumption)")
                    self.engergyCountlabel.text = "\(data.totalHomeEnergyConsumption)"
                    self.passEng = "\(data.totalHomeEnergyConsumption)"
                    for room in data.roomEnergyConsumption {
                        print("Room: \(room.roomName), Energy: \(room.totalRoomEnergyConsumption)")
                    }
                }
            }

            // ✅ Close popup after selection
            isPopupVisible = false
            UIView.animate(withDuration: 0.25) {
                self.homeListpopupView.alpha = 0
            } completion: { _ in
                self.homeListpopupView.isHidden = true
                self.blurEffectView?.removeFromSuperview()
                self.blurEffectView = nil
            }

            tableView.deselectRow(at: indexPath, animated: true)
        }
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

 


}

extension MainHomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == shortcutCollectionView {
               
               let count = flattenedFavouriteButtons.count
               
               // ❌ No cells when empty
               if count == 0 {
                   return 0
               }
               
               // ✅ Show items + Add Shortcut cell
               return count < 4 ? count + 1 : 4
           }
           
       else if collectionView == sceneCollectionView {
            return homeScene.count
        } else if collectionView == roomsCollectionView {
           
            return rooms.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == shortcutCollectionView {
            if indexPath.row < flattenedFavouriteButtons.count {
                // Normal shortcut cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortcutCollectionViewCell", for: indexPath) as! ShortcutCollectionViewCell
                let item = flattenedFavouriteButtons[indexPath.row]
                let matchedState = receivedDeviceStates.first { $0.uniqueID == item.device.uniqueId }
                cell.configure(with: item.device, button: item.button, state: matchedState)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ShortcutCollectionViewCell",
                    for: indexPath
                ) as! ShortcutCollectionViewCell

               
                cell.prepareForReuse()

                // Hide controls
                cell.resetForAddShortcut()

                cell.deviceImageView.image = UIImage(named: "plus")
                cell.roomname.text = "Add Shortcut"

                return cell
            }
        }

        else if collectionView == sceneCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortcutSceneCollectionViewCell", for: indexPath) as! ShortcutSceneCollectionViewCell
            let scene = homeScene[indexPath.row]
            cell.sceneNameLabel.text = scene
            let sceneImageName = homeSceneicon[indexPath.row]
            cell.sceneImage.image = UIImage(named: sceneImageName)
            return cell
        }

        else if collectionView == roomsCollectionView {
           
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomsShCollectionViewCell", for: indexPath) as! RoomsShCollectionViewCell
            let room = rooms[indexPath.row]
            cell.configure(with: room)
            return cell
        }

        return UICollectionViewCell()
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == shortcutCollectionView {
            if indexPath.row < flattenedFavouriteButtons.count {
                // No change
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let favVC = storyboard.instantiateViewController(withIdentifier: "FavouriteButtonViewController") as? FavouriteButtonViewController {
                    favVC.rooms = rooms
                    favVC.homeId = selectedHomeid
                    self.navigationController?.pushViewController(favVC, animated: true)
                }
            }
        }
        else if collectionView == sceneCollectionView {
            let controlNo = "\(indexPath.row + 1)"

            for room in rooms {
                SkromanIsraDatabaseHelper.shared.fetchDevicesByRoomId(roomId: room.roomId) { [weak self] roomDevices in
                    guard let self = self else { return }

                    for device in roomDevices {
                        self.publishScene(to: device.uniqueId, controlNo: controlNo)
                    }
                }
            }
        }
        else if collectionView == roomsCollectionView {
            let selectedRoom = rooms[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            if let allRoomsVC = storyboard.instantiateViewController(withIdentifier: "AllRoomsViewController") as? AllRoomsViewController {
                allRoomsVC.selectedRoomId = selectedRoom.roomId
                allRoomsVC.HomeId = selectedRoom.homeId
                allRoomsVC.homeNameshow = selectedHomeName
                allRoomsVC.tuyaHomeId = tuyaHomeId

                // Access tab bar controller
                if let tabBarController = self.tabBarController as? MainTabBarController {
                    
                    // Save reference for later if needed
                    tabBarController.latestAllRoomsVC = allRoomsVC

                    // ✅ Switch tab visually to "Rooms" (tab index 1)
                    tabBarController.selectedIndex = 1

                    // ✅ Refresh tab bar icons
                    tabBarController.updateTabBarItems()

                    // ✅ Push AllRoomsVC inside the navigation stack of Rooms tab
                    if let roomsNavController = tabBarController.viewControllers?[1] as? UINavigationController {
                        roomsNavController.pushViewController(allRoomsVC, animated: true)
                    }
                }
            }
        }

        

    }


    
    func collectionView(_ collectionView: UICollectionView,
                         layout collectionViewLayout: UICollectionViewLayout,
                         sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == shortcutCollectionView {
            let leftInset: CGFloat = 8
            let rightInset: CGFloat = 8
            let spacing: CGFloat = 8
            let columns: CGFloat = 2

            let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
            let availableWidth = collectionView.bounds.width - totalSpacing
            let cellWidth = availableWidth / columns

            return CGSize(width: cellWidth, height: 100)

        } else if collectionView == sceneCollectionView {
            // Show 4 cells per row, fully visible without scrolling
            let leftInset: CGFloat = 8
            let rightInset: CGFloat = 8
            let spacing: CGFloat = 8
            let columns: CGFloat = 4

            let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
            let availableWidth = collectionView.bounds.width - totalSpacing
            let cellWidth = availableWidth / columns

            return CGSize(width: cellWidth, height: cellWidth) // square cells
        }
        else if collectionView == roomsCollectionView {
            // Show 4 cells per row, fully visible without scrolling
            let leftInset: CGFloat = 8
            let rightInset: CGFloat = 8
            let spacing: CGFloat = 8
            let columns: CGFloat = 5

            let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
            let availableWidth = collectionView.bounds.width - totalSpacing
            let cellWidth = availableWidth / columns

            return CGSize(width: 70, height: 80) // square cells
        }


        return CGSize(width: 0, height: 0)
    }

}

extension MainHomeViewController: AddHomePopupViewDelegate {
    func showSuccessPopup() {
        showPopupPresenter.showPopup1(on: self.view,
                                      animationName: "success",
                                      title: "Success!",
                                      subtitle: "Home Added successfully")
    }
    
    
}
extension MainHomeViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        // Check for DeviceVcViewController on 2nd tab (index 1)
     
        
        // Check for AllRoomsViewController on 4th tab (index 3)
        if let navController = tabBarController.viewControllers?[3] as? UINavigationController,
           let energyvC = navController.viewControllers.first as? EnergyViewController {
            energyvC.homeId = self.selectedHomeid
          
           
          

            
            print("homeid at  room pass  \(selectedHomeid)")
        }
        
        
        // Check for AllRoomsViewController on 4th tab (index 3)
        if let navController = tabBarController.viewControllers?[1] as? UINavigationController,
           let roomVC = navController.viewControllers.first as? AllRoomsViewController {
            roomVC.HomeId = self.selectedHomeid
            roomVC.homeNameshow = self.passSelectedHomeName
            print("homeid at  room pass  \(selectedHomeid)")
             
        }
        return true
    }
}








extension MainHomeViewController
{
    func connetion_aws_function() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:AWS_REGION,
                                                                identityPoolId:IDENTITY_POOL_ID)
        initializeControlPlane(credentialsProvider: credentialsProvider)
        initializeDataPlane(credentialsProvider: credentialsProvider)
        
        // Important: MainHome should "ensure connected", not toggle disconnect.
        // Other screens rely on this shared MQTT connection.
        guard connected == false else {
            print("✅ AWS IoT already connected — skipping reconnect")
            return
        }
        handleConnectViaCert()
        
    }
    
    func handleDisconnect() {
        self.connectButton?.isHidden = false
        self.connectIoTDataWebSocket?.isHidden = false
        
        logTextView?.text = "Disconnecting..."
        
        DispatchQueue.global(qos: .default).async {
            self.iotDataManager.disconnect()
            DispatchQueue.main.async {
                self.connected = false
            }
        }
    }

    func handleConnectViaCert() {
        
        let defaults = UserDefaults.standard
        let certificateId = defaults.string( forKey: "certificateId")
        if (certificateId == nil) {
            DispatchQueue.main.async {
                
            }
            let certificateIdInBundle = searchForExistingCertificateIdInBundle()
            
            if (certificateIdInBundle == nil) {
                DispatchQueue.main.async {
                    
                }
                createCertificateIdAndStoreinNSUserDefaults(onSuccess: {generatedCertificateId in
                    let uuid = UUID().uuidString
                    
                    self.iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:generatedCertificateId, statusCallback: self.mqttEventCallback)
                }, onFailure: {error in
                    print("Received error: \(error)")
                })
            }
        } else {
            let uuid = UUID().uuidString;
            // Connect to the AWS IoT data plane service w/ certificate
            iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:certificateId!, statusCallback: self.mqttEventCallback)
        }
    }
    
    func createCertificateIdAndStoreinNSUserDefaults(onSuccess:  @escaping (String)->Void,
                                                     onFailure: @escaping (Error) -> Void) {
        let defaults = UserDefaults.standard
        let csrDictionary = [ "commonName": CertificateSigningRequestCommonName,
                              "countryName": CertificateSigningRequestCountryName,
                              "organizationName": CertificateSigningRequestOrganizationName,
                              "organizationalUnitName": CertificateSigningRequestOrganizationalUnitName]
        
        self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary) { (response) -> Void in
            guard let response = response else {
                DispatchQueue.main.async {
                    self.connectButton.isEnabled = true
                    // self.activityIndicatorView.stopAnimating()
                    self.logTextView.text = "Unable to create keys and/or certificate, check values in Constants.swift"
                }
                onFailure(NSError(domain: "No response on iotManager.createKeysAndCertificate", code: -2, userInfo: nil))
                return
            }
            defaults.set(response.certificateId, forKey:"certificateId")
            defaults.set(response.certificateArn, forKey:"certificateArn")
            let certificateId = response.certificateId
            print("response: [\(String(describing: response))]")
            
            let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
            attachPrincipalPolicyRequest?.policyName = POLICY_NAME
            attachPrincipalPolicyRequest?.principal = response.certificateArn
            
            // Attach the policy to the certificate
            self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continueWith (block: { (task) -> AnyObject? in
                if let error = task.error {
                    print("Failed: [\(error)]")
                    onFailure(error)
                } else  {
                    print("result: [\(String(describing: task.result))]")
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        if let certificateId = certificateId {
                            onSuccess(certificateId)
                        } else {
                            onFailure(NSError(domain: "Unable to generate certificate id", code: -1, userInfo: nil))
                        }
                    })
                }
                return nil
            })
        }
    }
    func mqttEventCallback( _ status: AWSIoTMQTTStatus ) {
        DispatchQueue.main.async {
            let iot_sample_vc = Iot_sample_ViewController()
            print("connection status = \(status.rawValue)")
            
            switch status {
            case .connecting:
                iot_sample_vc.mqttStatus = "Connecting..."
                print( iot_sample_vc.mqttStatus )
                
                
            case .connected:
                iot_sample_vc.mqttStatus = "Connected"
               
                self.connected = true
                IoTConnectionState.shared.setConnected(true)
                NotificationCenter.default.post(name: .iotConnectionStatusChanged, object: nil, userInfo: ["connected": true])
                
                let uuid = UUID().uuidString;
                let defaults = UserDefaults.standard
                let certificateId = defaults.string( forKey: "certificateId")
                
                
            case .disconnected:
                iot_sample_vc.mqttStatus = "Disconnected"
                self.connected = false
                IoTConnectionState.shared.setConnected(false)
                NotificationCenter.default.post(name: .iotConnectionStatusChanged, object: nil, userInfo: ["connected": false])
                
                print( iot_sample_vc.mqttStatus )
                
            case .connectionRefused:
                iot_sample_vc.mqttStatus = "Connection Refused"
                self.connected = false
                IoTConnectionState.shared.setConnected(false)
                NotificationCenter.default.post(name: .iotConnectionStatusChanged, object: nil, userInfo: ["connected": false])
                print( iot_sample_vc.mqttStatus )
                
            case .connectionError:
                iot_sample_vc.mqttStatus = "Connection Error"
                self.connected = false
                IoTConnectionState.shared.setConnected(false)
                NotificationCenter.default.post(name: .iotConnectionStatusChanged, object: nil, userInfo: ["connected": false])
                print( iot_sample_vc.mqttStatus )
                
            case .protocolError:
                iot_sample_vc.mqttStatus = "Protocol Error"
                self.connected = false
                IoTConnectionState.shared.setConnected(false)
                NotificationCenter.default.post(name: .iotConnectionStatusChanged, object: nil, userInfo: ["connected": false])
                print( iot_sample_vc.mqttStatus )
                
            default:
                iot_sample_vc.mqttStatus = "Unknown State"
                self.connected = false
                IoTConnectionState.shared.setConnected(false)
                NotificationCenter.default.post(name: .iotConnectionStatusChanged, object: nil, userInfo: ["connected": false])
                print("unknown state: \(status.rawValue)")
                
            }
            
            NotificationCenter.default.post( name: Notification.Name(rawValue: "connectionStatusChanged"), object: self )
        }
    }

    @objc private func handleIoTConnectionRequested() {
        connetion_aws_function()
    }
    
    
    
    func searchForExistingCertificateIdInBundle() -> String? {
        let defaults = UserDefaults.standard
        
        let myBundle = Bundle.main
        let myImages = myBundle.paths(forResourcesOfType: "p12" as String, inDirectory:nil)
        let uuid = UUID().uuidString
        
        guard let certId = myImages.first else {
            let certificateId = defaults.string(forKey: "certificateId")
            return certificateId
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: certId)) else {
            print("[ERROR] Found PKCS12 File in bundle, but unable to use it")
            let certificateId = defaults.string( forKey: "certificateId")
            return certificateId
        }
        
        DispatchQueue.main.async {
            self.logTextView.text = "found identity \(certId), importing..."
        }
        if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase:"", certificateId:certId) {
            
            defaults.set(certId, forKey:"certificateId")
            defaults.set("from-bundle", forKey:"certificateArn")
            DispatchQueue.main.async {
                self.logTextView.text = "Using certificate: \(certId))"
                self.iotDataManager.connect( withClientId: uuid,
                                             cleanSession:true,
                                             certificateId:certId,
                                             statusCallback: self.mqttEventCallback)
            }
        }
        
        let certificateId = defaults.string( forKey: "certificateId")
        return certificateId
    }
    
    func initializeDataPlane(credentialsProvider: AWSCredentialsProvider) {
        
        
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        
        let iotDataConfiguration = AWSServiceConfiguration(region: AWS_REGION,
                                                           endpoint: iotEndPoint,
                                                           credentialsProvider: credentialsProvider)
        
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: AWS_IOT_DATA_MANAGER_KEY)
        iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
    }
    
    
    func initializeControlPlane(credentialsProvider: AWSCredentialsProvider) {
        
        let controlPlaneServiceConfiguration = AWSServiceConfiguration(region:AWS_REGION, credentialsProvider:credentialsProvider)
        
        
        AWSServiceManager.default().defaultServiceConfiguration = controlPlaneServiceConfiguration
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
    }
    
    
  
}


struct FavouriteDeviceData {
    let device: Device
   
    let favouriteButtons: [ButtonDetails]
}

 

struct HomeEnergyResponse: Codable {
    let homeId: String
    let totalHomeEnergyConsumption: Double
    let roomEnergyConsumption: [homeRoomEnergy]
}

struct homeRoomEnergy: Codable {
    let roomId: String
    let roomName: String
    let totalRoomEnergyConsumption: Double
    let devices: [homeDeviceEnergy]
}

// Optional: Define DeviceEnergy if the devices array contains elements in the future
struct homeDeviceEnergy: Codable {
   
}
struct FavouriteButtonItem {
    let device: Device
    let button: ButtonDetails
}
extension Notification.Name {
    static let homesSynced = Notification.Name("homesSynced")
}
extension Notification.Name {
    static let syncCompleted = Notification.Name("syncCompleted")
    /// Posted after home favourite shortcuts are saved (local DB + API); Main Home refreshes shortcuts.
    static let homeFavouritesDidChange = Notification.Name("homeFavouritesDidChange")
}


struct Home {
    var homeServerId: String
    var homeName: String?
    var homeUrl: String?
    var isFamilyHome: Int
    var tuyaHomeId: Int64?
}
extension MainHomeViewController {
    
    func SyncPostData() {
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SkromanIsraDatabaseHelper.shared.deleteAllTablesData { success in
                if success {
                    print("✅ Deleted all old data")
                    SkromanIsraDatabaseHelper.shared.printHomeTableSchema()
                    self.syncServer()
                } else {
                    print("❌ Failed to delete old data")
                }
            }
        }
    }
    
    
    
    
    func syncServer() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? "Nothing"
        
        let syncDataParameters: [String: Any] = [
            "userId": userId
        ]
        print("call api ")
        AF.request(MainApi.sync_everything, method: .post, parameters: syncDataParameters, encoding: JSONEncoding.default, headers: nil)
            .response { response in
                switch response.result {
                case .success(let data):
                    if let responseData = data {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                                print("Parsed sync JSON: \(json)")
                                
                                // Insert User Data
                                if let userData = json["userData"] as? [String: Any] {
                                    SkromanIsraDatabaseHelper.shared.insertUser(
                                        userId: userData["userId"] as? String ?? "",
                                        userName: userData["userName"] as? String,
                                        emailId: userData["emailId"] as? String,
                                        mobileNumber: userData["mobileNumber"] as? String,
                                        address1: userData["address1"] as? String,
                                        address2: userData["address2"] as? String,
                                        city: userData["city"] as? String,
                                        state: userData["state"] as? String,
                                        pinCode: userData["pinCode"] as? String,
                                        loginType: userData["loginType"] as? String,
                                        imageUser: userData["imageUser"] as? String,
                                        verifyAlexa: userData["verifyAlexa"] as? String,
                                        verifyGoogle: userData["verifyGoogle"] as? String,
                                        password: userData["password"] as? String
                                        
                                        
                                    )
                                    print("✅ User data inserted successfully")
                                }
                                
                                
                                if let syncData = json["syncData"] as? [[String: Any]] {
                                    self.insertHomeAndRoomsIntoDB(syncData: syncData) {
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: .syncCompleted, object: nil)
                                        }
                                    }
                                }
                                
                                if let familySync = json["familySync"] as? [[String: Any]] {
                                    print("📌 Found Family Sync")
                                    
                                    for familyEntry in familySync {
                                        if let homes = familyEntry["homes"] as? [[String: Any]] {
                                            
                                            self.insertFamilyHomeAndRoomsIntoDB(familyHomes: homes) {
                                                print("✅ Family Sync inserted successfully")
                                                DispatchQueue.main.async {
                                                    NotificationCenter.default.post(name: .syncCompleted, object: nil)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                
                                
                            }
                        } catch {
                            print("JSON Parsing Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("No data received from the API.")
                    }
                    
                case .failure(let error):
                    print("API Sync Error: \(error.localizedDescription)")
                }
            }
    }
    
    
    func insertHomeAndRoomsIntoDB(syncData: [[String: Any]], completion: @escaping () -> Void) {
        let database = SkromanIsraDatabaseHelper.shared
        DispatchQueue.global(qos: .background).async {
            
            for home in syncData {
                if let homeId = home["homeId"] as? String,
                   let homeName = home["homeName"] as? String {
                    let homeImage = home["homeImage"] as? String ?? ""
                    let tuyaHomeId: Int64? = {
                        if let id = home["tuyaHomeId"] as? Int64 {
                            return id
                        } else if let id = home["tuyaHomeId"] as? Int {
                            return Int64(id)
                        }
                        return nil
                    }()
                    
                    print("🏠 Home → \(homeName), TuyaID: \(tuyaHomeId ?? -1)")
                    print("home url  at\(homeImage)  home   name  is\(homeName) ")
                    
                    
                    database.insertHome(homeServerId: homeId, homeName: homeName, homeUrl: homeImage, tuyaHomeId: tuyaHomeId, isFamilyHome: 0)
                    
                    if let rooms = home["rooms"] as? [[String: Any]] {
                        for room in rooms {
                            
                            if let roomId = room["roomId"] as? String,
                               let roomName = room["roomName"] as? String {
                                
                                let roomIconId = room["roomIconId"] as? String ?? ""
                                let roomIconType = room["roomIconType"] as? String ?? ""
                                
                                // ✅ Parse tuyaRoomId
                                let tuyaRoomId: Int64? = {
                                    let raw = room["tuyaRoomId"]
                                    
                                    if let id = raw as? Int64 {
                                        return id
                                    }
                                    
                                    if let id = raw as? Int {
                                        return Int64(id)
                                    }
                                    
                                    if let str = raw as? String {
                                        if str == "<null>" || str.isEmpty {
                                            return nil
                                        }
                                        return Int64(str)
                                    }
                                    
                                    return nil
                                }()
                                
                                // ✅ Pass it here
                                database.insertRoom(
                                    roomId: roomId,
                                    roomName: roomName,
                                    roomIconId: roomIconId,
                                    roomIconType: roomIconType,
                                    tuyaRoomId: tuyaRoomId,   // 🔥 FIX
                                    homeId: homeId
                                )
                                
                                if let roomScenes = room["roomScene"] as? [[String: Any]] {
                                    for scene in roomScenes {
                                        let sceneNo: String? = {
                                            if let intValue = scene["sceneNo"] as? Int {
                                                return String(intValue)
                                            } else if let strValue = scene["sceneNo"] as? String {
                                                return strValue
                                            }
                                            return nil
                                        }()
                                        
                                        let sceneName = scene["sceneName"] as? String ?? ""
                                        let sceneIcon = scene["sceneIcon"] as? String ?? ""
                                        
                                        print("➡️ inserting scene → roomId: \(roomId), sceneNo: \(sceneNo ?? "nil")")
                                        
                                        database.insertRoomScene(
                                            roomId: roomId,
                                            sceneNo: sceneNo,
                                            sceneName: sceneName,
                                            sceneIcon: sceneIcon
                                        )
                                    }
                                }
                                
                                
                                // Insert Devices
                                if let devices = room["devices"] as? [[String: Any]] {
                                    for device in devices {
                                        if room["roomId"] as! String == "ROOM_Id-JjFsBo53D" {
                                            print  ( "here ios room: \(device) ")
                                        }
                                        
                                        if
                                            let deviceUid = device["deviceUid"] as? String,
                                            let deviceName = device["deviceName"] as? String,
                                            let uniqueId = device["unique_id"] as? String,
                                            let POP = device["POP"] as? String,
                                            let deviceModelNo = device["deviceModelNo"] as? String,
                                            let deviceType = device["deviceType"] as? String,
                                            let connectedSsid = device["connectedSsid"] as? String,
                                            let connectedPassword = device["connectedPassword"] as? String
                                        {
                                            
                                            let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                            let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                            
                                            
                                            database.insertDevice(
                                                deviceUid: deviceUid,
                                                roomId: roomId,
                                                homeId: homeId,
                                                userId: home["userId"] as? String ?? "",
                                                deviceName: deviceName,
                                                uniqueId: uniqueId,
                                                POP: POP,
                                                deviceModelNo: deviceModelNo,
                                                deviceDimmingType: deviceDimmingType,
                                                deviceType: deviceType,
                                                connectedSsid: connectedSsid,
                                                connectedPassword: connectedPassword,
                                                deviceCategory: deviceCategory
                                            )
                                            if let buttons = device["button_Details"] as? [[String: Any]] {
                                                for button in buttons {
                                                    print("🔄 Processing button: \(button)")
                                                    
                                                    let buttonId = button["_id"] as? String
                                                    let buttonControlName = button["buttonControlName"] as? String
                                                    let buttonIconId = button["buttonIconId"] as? Int
                                                    let buttonName = button["buttonName"] as? String
                                                    let buttonNo = button["buttonNo"] as? Int
                                                    let deviceServerId = button["deviceServerId"] as? String
                                                    let power = button["power"] as? Int
                                                    let switchName = button["switchName"] as? String
                                                    let isShortcut = button["isShortcut"] as? Int
                                                    let buttonIconName = button["buttonIconName"] as? String
                                                    let buttonIconColor = button["buttonIconColor"] as? String
                                                    let isFavourite = button["isFavourite"] as? Int
                                                    let isHomeFav = button["isHomeFav"] as? Int                // ✅ Extracted
                                                    
                                                    
                                                    database.insertButtonDetails(
                                                        buttonId: buttonId,
                                                        buttonControlName: buttonControlName,
                                                        buttonIconId: buttonIconId,
                                                        buttonName: buttonName,
                                                        buttonNo: buttonNo,
                                                        deviceServerId: deviceServerId,
                                                        deviceUid: deviceUid,
                                                        power: power,
                                                        roomName: roomName,
                                                        switchName: switchName,
                                                        uniqueId: uniqueId,
                                                        isShortcut: isShortcut,
                                                        buttonIconName: buttonIconName,
                                                        buttonIconColor: buttonIconColor,
                                                        isFavourite: isFavourite, isHomeFav: isHomeFav
                                                    )
                                                }
                                                
                                                
                                                if let deviceStates = device["deviceStates"] as? [[String: Any]] {
                                                    for state in deviceStates {
                                                        let deviceStateUid = state["deviceStateUid"] as? String ?? ""
                                                        let workingMode = state["working_mode"] as? String ?? ""
                                                        let master = state["master"] as? String ?? ""
                                                        let childLockF = state["child_lock_f"] as? String ?? ""
                                                        let childLockL = state["child_lock_l"] as? String ?? ""
                                                        let childLockM = state["child_lock_m"] as? String ?? ""
                                                        let configButtons = state["config_buttons"] as? String ?? ""
                                                        let configDim = state["config_dim"] as? String ?? ""
                                                        let connectivity = state["connectivity"] as? String ?? ""
                                                        let destButton = state["dest_button"] as? String ?? ""
                                                        let fSpeed = state["F_speed"] as? String ?? ""
                                                        let fState = state["F_state"] as? String ?? ""
                                                        let fanDest = state["fan_dest"] as? String ?? ""
                                                        let lSpeed = state["L_speed"] as? String ?? ""
                                                        let lState = state["L_state"] as? String ?? ""
                                                        let series = state["series"] as? String ?? ""
                                                        
                                                        
                                                        // ✅ Optional ota_status
                                                        let otaStatus = state["ota_status"] as? Int
                                                        let fRegulator =  state["F_regulator"] as?  String ?? ""
                                                        
                                                        database.insertDeviceState(
                                                            deviceUid: deviceUid,
                                                            deviceStateUid: deviceStateUid,
                                                            uniqueId: uniqueId,
                                                            working_mode: workingMode,
                                                            master: master,
                                                            child_lock_f: childLockF,
                                                            child_lock_l: childLockL,
                                                            child_lock_m: childLockM,
                                                            config_buttons: configButtons,
                                                            config_dim: configDim,
                                                            connectivity: connectivity,
                                                            dest_button: destButton,
                                                            f_speed: fSpeed,
                                                            f_state: fState,
                                                            fan_dest: fanDest,
                                                            l_speed: lSpeed,
                                                            l_state: lState,
                                                            series: series,
                                                            ota_status: otaStatus, F_regulator: fRegulator
                                                        )
                                                    }
                                                }
                                                
                                                
                                                if let scenes = device["scenes"] as? [[String: Any]] {
                                                    for scene in scenes {
                                                        if let sceneId = scene["sceneId"] as? String,
                                                           let sceneName = scene["sceneName"] as? String,
                                                           let sceneNo = "\(scene["sceneNo"] ?? "")" as String? {
                                                            
                                                            let configButtons = "\(scene["config_buttons"] ?? "")"
                                                            let configDim = "\(scene["config_dim"] ?? "")"
                                                            let destButton = "\(scene["dest_button"] ?? "")"
                                                            let fanDest = "\(scene["fan_dest"] ?? "")"
                                                            let fSpeed = "\(scene["F_speed"] ?? "")"
                                                            let fState = "\(scene["F_state"] ?? "")"
                                                            let lSpeed = "\(scene["L_speed"] ?? "")"
                                                            let lState = "\(scene["L_state"] ?? "")"
                                                            let fRedundant = scene["F_redundant"] as? String ?? "NA"
                                                            let lRedundant = scene["L_redundant"] as? String ?? "NA"
                                                            
                                                            database.insertScene(
                                                                sceneId: sceneId,
                                                                deviceUid: deviceUid,
                                                                homeId: homeId,
                                                                roomId: roomId,
                                                                uniqueId: uniqueId,
                                                                modelNo: deviceModelNo,
                                                                deviceType: deviceType,
                                                                sceneNo: sceneNo,
                                                                sceneName: sceneName,
                                                                destButton: destButton,
                                                                configButtons: configButtons,
                                                                configDim: configDim,
                                                                LState: lState,
                                                                LSpeed: lSpeed,
                                                                FState: fState,
                                                                FSpeed: fSpeed,
                                                                fanDest: fanDest,
                                                                LRedundant: lRedundant,
                                                                FRedundant: fRedundant
                                                            )
                                                        }
                                                        
                                                    }
                                                    
                                                    if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                        print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                        
                                                        for schedule in schedules {
                                                            
                                                            if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                                print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                                
                                                                for schedule in schedules {
                                                                    let scheduleId = schedule["sheduleId"] as? String ?? UUID().uuidString
                                                                    
                                                                    // ✅ Handle scheduleNumber safely
                                                                    let scheduleNumber: String
                                                                    if let num = schedule["sheduleNumber"] as? Int {
                                                                        scheduleNumber = String(num)
                                                                    } else if let num = schedule["sheduleNumber"] as? String {
                                                                        scheduleNumber = num
                                                                    } else {
                                                                        scheduleNumber = ""
                                                                    }
                                                                    
                                                                    let time = schedule["time"] as? String ?? ""
                                                                    let date = schedule["date"] as? String ?? ""
                                                                    let weekSchedule = schedule["week_schedule"] as? String ?? ""
                                                                    let fSpeed = "\(schedule["F_speed"] ?? "0")"
                                                                    let fState = "\(schedule["F_state"] ?? "0")"
                                                                    let lSpeed = "\(schedule["L_speed"] ?? "0")"
                                                                    let lState = "\(schedule["L_state"] ?? "0")"
                                                                    let configButtons = schedule["config_buttons"] as? String ?? ""
                                                                    let destButton = "\(schedule["dest_button"] ?? "")"
                                                                    let fanDest = "\(schedule["fan_dest"] ?? "")"
                                                                    let master = schedule["master"] as? String ?? "0"
                                                                    let modelNo = "\(schedule["modelNo"] ?? "")"
                                                                    let sceneId = schedule["sceneId"] as? String ?? ""
                                                                    
                                                                    print("Inserting schedule: ID=\(scheduleId), Number=\(scheduleNumber), Device=\(deviceUid), Time=\(time)")
                                                                    
                                                                    database.insertSchedule(
                                                                        scheduleId: scheduleId,
                                                                        scheduleNumber: scheduleNumber,
                                                                        deviceUid: deviceUid,
                                                                        uniqueId: uniqueId,
                                                                        date: date,
                                                                        time: time,
                                                                        weekSchedule: weekSchedule,
                                                                        LState: lState,
                                                                        LSpeed: lSpeed,
                                                                        FState: fState,
                                                                        FSpeed: fSpeed,
                                                                        configButtons: configButtons,
                                                                        destButton: destButton,
                                                                        fanDest: fanDest,
                                                                        master: master,
                                                                        modelNo: modelNo,
                                                                        sceneId: sceneId
                                                                    )
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    
                                                }
                                            }
                                        }else {
                                            print("Device insert not data found:")
                                            
                                            let deviceUid = device["deviceUid"] as? String ?? "null"
                                            let deviceName = device["deviceName"] as? String ?? "null"
                                            let uniqueId = device["unique_id"] as? String ?? "null"
                                            let POP = device["POP"] as? String ?? "null"
                                            let deviceModelNo = device["deviceModelNo"] as? String ?? "null"
                                            let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                            let deviceType = device["deviceType"] as? String ?? "null"
                                            let connectedSsid = device["connectedSsid"] as? String ?? "null"
                                            let connectedPassword = device["connectedPassword"] as? String ?? "null"
                                            let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                            
                                            print("""
                                            🧩 Device Info:
                                              • deviceUid: \(deviceUid)
                                              • deviceName: \(deviceName)
                                              • uniqueId: \(uniqueId)
                                              • POP: \(POP)
                                              • deviceModelNo: \(deviceModelNo)
                                              • deviceDimmingType: \(deviceDimmingType)
                                              • deviceType: \(deviceType)
                                              • connectedSsid: \(connectedSsid)
                                              • connectedPassword: \(connectedPassword)
                                              • deviceCategory: \(deviceCategory)
                                            """)
                                        }
                                        
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
            
            
            print("✅ Sync data inserted into SQLite successfully!")
            DispatchQueue.main.async {
                completion()
            }
            
        }
        
    }
    
    
    
    func insertFamilyHomeAndRoomsIntoDB(familyHomes: [[String: Any]], completion: @escaping () -> Void) {
        
        let database = SkromanIsraDatabaseHelper.shared
        
        DispatchQueue.global(qos: .background).async {
            
            for home in familyHomes {
                
                guard let homeId = home["homeId"] as? String,
                      let homeName = home["homeName"] as? String else { continue }
                
                let homeImage = home["homeImage"] as? String ?? ""
                
                print("🏠 FAMILY HOME → \(homeName)")
                let tuyaHomeId: Int64? = {
                    if let id = home["tuyaHomeId"] as? Int64 {
                        return id
                    } else if let id = home["tuyaHomeId"] as? Int {
                        return Int64(id)
                    }
                    return nil
                }()
                
                database.insertHome(
                    homeServerId: homeId,
                    homeName: homeName,
                    homeUrl: homeImage, tuyaHomeId: tuyaHomeId,
                    isFamilyHome: 1
                )
                
                // INSERT ROOMS
                if let rooms = home["rooms"] as? [[String: Any]] {
                    for room in rooms {
                        
                        if let roomId = room["roomId"] as? String,
                           let roomName = room["roomName"] as? String {
                            
                            let roomIconId = room["roomIconId"] as? String ?? ""
                            let roomIconType = room["roomIconType"] as? String ?? ""
                            
                            // ✅ Parse tuyaRoomId
                            let tuyaRoomId: Int64? = {
                                let raw = room["tuyaRoomId"]
                                
                                if let id = raw as? Int64 {
                                    return id
                                }
                                
                                if let id = raw as? Int {
                                    return Int64(id)
                                }
                                
                                if let str = raw as? String {
                                    if str == "<null>" || str.isEmpty {
                                        return nil
                                    }
                                    return Int64(str)
                                }
                                
                                return nil
                            }()
                            
                            // ✅ Pass it here
                            database.insertRoom(
                                roomId: roomId,
                                roomName: roomName,
                                roomIconId: roomIconId,
                                roomIconType: roomIconType,
                                tuyaRoomId: tuyaRoomId,
                                homeId: homeId
                            )
                            
                            // INSERT DEVICES (same as your old logic)
                            if let devices = room["devices"] as? [[String: Any]] {
                                for device in devices {
                                    if room["roomId"] as! String == "ROOM_Id-JjFsBo53D" {
                                        print  ( "here ios room: \(device) ")
                                    }
                                    
                                    if
                                        let deviceUid = device["deviceUid"] as? String,
                                        let deviceName = device["deviceName"] as? String,
                                        let uniqueId = device["unique_id"] as? String,
                                        let POP = device["POP"] as? String,
                                        let deviceModelNo = device["deviceModelNo"] as? String,
                                        let deviceType = device["deviceType"] as? String,
                                        let connectedSsid = device["connectedSsid"] as? String,
                                        let connectedPassword = device["connectedPassword"] as? String
                                    {
                                        
                                        let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                        let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                        
                                        
                                        database.insertDevice(
                                            deviceUid: deviceUid,
                                            roomId: roomId,
                                            homeId: homeId,
                                            userId: home["userId"] as? String ?? "",
                                            deviceName: deviceName,
                                            uniqueId: uniqueId,
                                            POP: POP,
                                            deviceModelNo: deviceModelNo,
                                            deviceDimmingType: deviceDimmingType,
                                            deviceType: deviceType,
                                            connectedSsid: connectedSsid,
                                            connectedPassword: connectedPassword,
                                            deviceCategory: deviceCategory
                                        )
                                        if let buttons = device["button_Details"] as? [[String: Any]] {
                                            for button in buttons {
                                                print("🔄 Processing button: \(button)")
                                                
                                                let buttonId = button["_id"] as? String
                                                let buttonControlName = button["buttonControlName"] as? String
                                                let buttonIconId = button["buttonIconId"] as? Int
                                                let buttonName = button["buttonName"] as? String
                                                let buttonNo = button["buttonNo"] as? Int
                                                let deviceServerId = button["deviceServerId"] as? String
                                                let power = button["power"] as? Int
                                                let switchName = button["switchName"] as? String
                                                let isShortcut = button["isShortcut"] as? Int
                                                let buttonIconName = button["buttonIconName"] as? String
                                                let buttonIconColor = button["buttonIconColor"] as? String
                                                let isFavourite = button["isFavourite"] as? Int
                                                let isHomeFav = button["isHomeFav"] as? Int                // ✅ Extracted
                                                
                                                
                                                database.insertButtonDetails(
                                                    buttonId: buttonId,
                                                    buttonControlName: buttonControlName,
                                                    buttonIconId: buttonIconId,
                                                    buttonName: buttonName,
                                                    buttonNo: buttonNo,
                                                    deviceServerId: deviceServerId,
                                                    deviceUid: deviceUid,
                                                    power: power,
                                                    roomName: roomName,
                                                    switchName: switchName,
                                                    uniqueId: uniqueId,
                                                    isShortcut: isShortcut,
                                                    buttonIconName: buttonIconName,
                                                    buttonIconColor: buttonIconColor,
                                                    isFavourite: isFavourite, isHomeFav: isHomeFav
                                                )
                                            }
                                            
                                            
                                            if let deviceStates = device["deviceStates"] as? [[String: Any]] {
                                                for state in deviceStates {
                                                    let deviceStateUid = state["deviceStateUid"] as? String ?? ""
                                                    let workingMode = state["working_mode"] as? String ?? ""
                                                    let master = state["master"] as? String ?? ""
                                                    let childLockF = state["child_lock_f"] as? String ?? ""
                                                    let childLockL = state["child_lock_l"] as? String ?? ""
                                                    let childLockM = state["child_lock_m"] as? String ?? ""
                                                    let configButtons = state["config_buttons"] as? String ?? ""
                                                    let configDim = state["config_dim"] as? String ?? ""
                                                    let connectivity = state["connectivity"] as? String ?? ""
                                                    let destButton = state["dest_button"] as? String ?? ""
                                                    let fSpeed = state["F_speed"] as? String ?? ""
                                                    let fState = state["F_state"] as? String ?? ""
                                                    let fanDest = state["fan_dest"] as? String ?? ""
                                                    let lSpeed = state["L_speed"] as? String ?? ""
                                                    let lState = state["L_state"] as? String ?? ""
                                                    let series = state["series"] as? String ?? ""
                                                    
                                                    // ✅ Optional ota_status
                                                    let otaStatus = state["ota_status"] as? Int
                                                    let fRegulator =  state["F_regulator"] as?  String ?? ""
                                                    database.insertDeviceState(
                                                        deviceUid: deviceUid,
                                                        deviceStateUid: deviceStateUid,
                                                        uniqueId: uniqueId,
                                                        working_mode: workingMode,
                                                        master: master,
                                                        child_lock_f: childLockF,
                                                        child_lock_l: childLockL,
                                                        child_lock_m: childLockM,
                                                        config_buttons: configButtons,
                                                        config_dim: configDim,
                                                        connectivity: connectivity,
                                                        dest_button: destButton,
                                                        f_speed: fSpeed,
                                                        f_state: fState,
                                                        fan_dest: fanDest,
                                                        l_speed: lSpeed,
                                                        l_state: lState,
                                                        series: series,
                                                        ota_status: otaStatus, F_regulator: fRegulator
                                                    )
                                                }
                                            }
                                            
                                            
                                            if let scenes = device["scenes"] as? [[String: Any]] {
                                                for scene in scenes {
                                                    if let sceneId = scene["sceneId"] as? String,
                                                       let sceneName = scene["sceneName"] as? String,
                                                       let sceneNo = "\(scene["sceneNo"] ?? "")" as String? {
                                                        
                                                        let configButtons = "\(scene["config_buttons"] ?? "")"
                                                        let configDim = "\(scene["config_dim"] ?? "")"
                                                        let destButton = "\(scene["dest_button"] ?? "")"
                                                        let fanDest = "\(scene["fan_dest"] ?? "")"
                                                        let fSpeed = "\(scene["F_speed"] ?? "")"
                                                        let fState = "\(scene["F_state"] ?? "")"
                                                        let lSpeed = "\(scene["L_speed"] ?? "")"
                                                        let lState = "\(scene["L_state"] ?? "")"
                                                        let fRedundant = scene["F_redundant"] as? String ?? "NA"
                                                        let lRedundant = scene["L_redundant"] as? String ?? "NA"
                                                        
                                                        database.insertScene(
                                                            sceneId: sceneId,
                                                            deviceUid: deviceUid,
                                                            homeId: homeId,
                                                            roomId: roomId,
                                                            uniqueId: uniqueId,
                                                            modelNo: deviceModelNo,
                                                            deviceType: deviceType,
                                                            sceneNo: sceneNo,
                                                            sceneName: sceneName,
                                                            destButton: destButton,
                                                            configButtons: configButtons,
                                                            configDim: configDim,
                                                            LState: lState,
                                                            LSpeed: lSpeed,
                                                            FState: fState,
                                                            FSpeed: fSpeed,
                                                            fanDest: fanDest,
                                                            LRedundant: lRedundant,
                                                            FRedundant: fRedundant
                                                        )
                                                    }
                                                    
                                                }
                                                
                                                if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                    print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                    
                                                    for schedule in schedules {
                                                        
                                                        if let schedules = device["timeShedules"] as? [[String: Any]] {
                                                            print("Found \(schedules.count) schedules for device \(uniqueId)")
                                                            
                                                            for schedule in schedules {
                                                                let scheduleId = schedule["sheduleId"] as? String ?? UUID().uuidString
                                                                
                                                                // ✅ Handle scheduleNumber safely
                                                                let scheduleNumber: String
                                                                if let num = schedule["sheduleNumber"] as? Int {
                                                                    scheduleNumber = String(num)
                                                                } else if let num = schedule["sheduleNumber"] as? String {
                                                                    scheduleNumber = num
                                                                } else {
                                                                    scheduleNumber = ""
                                                                }
                                                                
                                                                let time = schedule["time"] as? String ?? ""
                                                                let date = schedule["date"] as? String ?? ""
                                                                let weekSchedule = schedule["week_schedule"] as? String ?? ""
                                                                let fSpeed = "\(schedule["F_speed"] ?? "0")"
                                                                let fState = "\(schedule["F_state"] ?? "0")"
                                                                let lSpeed = "\(schedule["L_speed"] ?? "0")"
                                                                let lState = "\(schedule["L_state"] ?? "0")"
                                                                let configButtons = schedule["config_buttons"] as? String ?? ""
                                                                let destButton = "\(schedule["dest_button"] ?? "")"
                                                                let fanDest = "\(schedule["fan_dest"] ?? "")"
                                                                let master = schedule["master"] as? String ?? "0"
                                                                let modelNo = "\(schedule["modelNo"] ?? "")"
                                                                let sceneId = schedule["sceneId"] as? String ?? ""
                                                                
                                                                print("Inserting schedule: ID=\(scheduleId), Number=\(scheduleNumber), Device=\(deviceUid), Time=\(time)")
                                                                
                                                                database.insertSchedule(
                                                                    scheduleId: scheduleId,
                                                                    scheduleNumber: scheduleNumber,
                                                                    deviceUid: deviceUid,
                                                                    uniqueId: uniqueId,
                                                                    date: date,
                                                                    time: time,
                                                                    weekSchedule: weekSchedule,
                                                                    LState: lState,
                                                                    LSpeed: lSpeed,
                                                                    FState: fState,
                                                                    FSpeed: fSpeed,
                                                                    configButtons: configButtons,
                                                                    destButton: destButton,
                                                                    fanDest: fanDest,
                                                                    master: master,
                                                                    modelNo: modelNo,
                                                                    sceneId: sceneId
                                                                )
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                
                                            }
                                        }
                                    }else {
                                        print("Device insert not data found:")
                                        
                                        let deviceUid = device["deviceUid"] as? String ?? "null"
                                        let deviceName = device["deviceName"] as? String ?? "null"
                                        let uniqueId = device["unique_id"] as? String ?? "null"
                                        let POP = device["POP"] as? String ?? "null"
                                        let deviceModelNo = device["deviceModelNo"] as? String ?? "null"
                                        let deviceDimmingType = device["deviceDimmingType"] as? String ?? "null"
                                        let deviceType = device["deviceType"] as? String ?? "null"
                                        let connectedSsid = device["connectedSsid"] as? String ?? "null"
                                        let connectedPassword = device["connectedPassword"] as? String ?? "null"
                                        let deviceCategory = device["deviceCategory"] as? String ?? "null"
                                        
                                        print("""
                                    🧩 Device Info:
                                      • deviceUid: \(deviceUid)
                                      • deviceName: \(deviceName)
                                      • uniqueId: \(uniqueId)
                                      • POP: \(POP)
                                      • deviceModelNo: \(deviceModelNo)
                                      • deviceDimmingType: \(deviceDimmingType)
                                      • deviceType: \(deviceType)
                                      • connectedSsid: \(connectedSsid)
                                      • connectedPassword: \(connectedPassword)
                                      • deviceCategory: \(deviceCategory)
                                    """)
                                    }
                                    
                                }
                            }
                            
                        }
                    }
                }
                
                print("✅ FAMILY Homes + Rooms inserted successfully!")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}
