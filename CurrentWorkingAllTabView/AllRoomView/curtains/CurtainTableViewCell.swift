//
//  CurtainTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 10/08/25.
//

import UIKit

class CurtainTableViewCell: UITableViewCell {

    @IBOutlet weak var cellBackgroundView: UIView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    @IBOutlet weak var curtainCollectionView:
    UICollectionView!
    
    @IBOutlet weak var isonlineImage: UIImageView!
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var curtainAvaiblityLabel: UILabel!
    
    
    let sliderButton = masterSlideDevicerButton()
    var buttonDetails: [ButtonDetails] = []
    var filteredButtonDetails: [ButtonDetails] = []
    var deviceUniqueid: String?
    var currentDevice: Device?
    var receivedDeviceStates: [DeviceStateArray] = []
    private var customSlider :  CustomSlider?
    var deviceScene: [DeviceScene] = []
    var deviceSchdeule:[Schedule] =  []
    var visibleButtonDetails: [ButtonDetails] {
        return filteredButtonDetails.filter { btn in
            let controlName = btn.buttonControlName.uppercased()
            return controlName != "C" && controlName != "Y"
        }
       
        
        if let layout = curtainCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }

    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        cellBackgroundView.backgroundColor = .clear
        print("receivedDeviceStates curtain")
        registerxib()
        DispatchQueue.main.async {
            self.reloadCollectionViewAndResize()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }
    
    func configure(with device: Device, deviceStates: [DeviceStateArray]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.reloadCollectionData()
        }
        self.currentDevice = device
        self.deviceUniqueid = device.uniqueId
        self.deviceNameLabel.text = device.uniqueId
        self.receivedDeviceStates = deviceStates
        fetchButtonsDetails(SelectedUniqueUid: device.uniqueId)
        let hasMatchingState = deviceStates.contains(where: { $0.uniqueID == device.uniqueId })
        isonlineImage.tintColor = hasMatchingState ? .systemGreen : .red

    }
    
    func reloadCollectionData() {
       
        curtainCollectionView.reloadData()
        curtainCollectionView.layoutIfNeeded()
        collectionViewHeight.constant = curtainCollectionView.contentSize.height
        
        // Force table view to re-layout
        if let tableView = self.superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func reloadCollectionViewAndResize() {
        curtainCollectionView.reloadData()
        curtainCollectionView.layoutIfNeeded()
         
    }
    
    func fetchButtonsDetails(SelectedUniqueUid: String) {

        // Reset
        buttonDetails.removeAll()
        filteredButtonDetails.removeAll()

        // Step 1: Fetch + sort
        buttonDetails = SkromanIsraDatabaseHelper.shared
            .fetchButtonDetails(uniqueId: SelectedUniqueUid)
            .sorted { $0.buttonNo < $1.buttonNo }

        print("✅ All DB Buttons:",
              buttonDetails.map { "\($0.buttonName)-\($0.buttonNo)" })

        // Step 2: Get device state
        guard let state = receivedDeviceStates.first(where: { $0.uniqueID == SelectedUniqueUid }) else {
            print("❌ Device state not found")
            return
        }

        let cNm = state.cNm
        print("📡 cNm:", cNm)

        // Step 3: Filter using device state (IMPORTANT)
        filteredButtonDetails = buttonDetails.filter { button in

            let index = button.buttonNo - 1

            guard index >= 0 && index < cNm.count else {
                return false
            }

            let char = cNm[cNm.index(cNm.startIndex, offsetBy: index)]

            // 👉 Curtain only
            return char == "O" || char == "C"
        }

        print("🎯 Curtain buttons:",
              filteredButtonDetails.map { "\($0.buttonName)-\($0.buttonNo)" })

       
        DispatchQueue.main.async {
            self.curtainCollectionView.reloadData()
        }
    }
    func registerxib(){
        let uiNib = UINib(nibName: "CurtaimCollectionViewCell", bundle:nil)
        curtainCollectionView.register(uiNib, forCellWithReuseIdentifier: "CurtaimCollectionViewCell")
        curtainCollectionView.dataSource =  self
        curtainCollectionView.delegate =  self
    }
    
    
}

extension CurtainTableViewCell : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleButtonDetails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let buttonDetail = visibleButtonDetails[indexPath.item]

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "CurtaimCollectionViewCell",for: indexPath) as! CurtaimCollectionViewCell

        cell.configure(with: buttonDetail, device: currentDevice, deviceStates: receivedDeviceStates)
        
        
        return cell 
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let leftInset: CGFloat = 8
        let rightInset: CGFloat = 8
        let spacing: CGFloat = 8
        let columns: CGFloat = 2

        let totalSpacing = leftInset + rightInset + spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let baseCellWidth = availableWidth / columns

        return CGSize(width: baseCellWidth, height: 100)
    }
    
}
