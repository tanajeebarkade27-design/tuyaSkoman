//
//  ShortcutDeviceButtonCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 05/05/25.
//

import UIKit
 import Alamofire
 import Lottie
protocol ShortcutCellDelegate: AnyObject {
    func showSuccessPopup()
}


class ShortcutDeviceButtonCollectionViewCell: UICollectionViewCell {
    var devices: [Device] = []
    var mode: ShortcutMode = .dimming
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var devicebuttonsCollectionView: UICollectionView!
    weak var delegate: ShortcutCellDelegate?
    var buttons: [(device: DeviceStateArray, index: Int, currentState: String)] = []
    var selectedIndexes: Set<Int> = []

    override func awakeFromNib() {
        super.awakeFromNib()
        registerXib()
    }

    func configure(
          with device: Device,
          allTargets: [(device: DeviceStateArray, index: Int, currentState: String)]
        ) {
            deviceNameLabel.text = device.deviceName

            // filter only this device’s targets:
            buttons = allTargets.filter { $0.device.uniqueID == device.uniqueId }

            // mark selected…
            selectedIndexes.removeAll()
            for (i, btn) in buttons.enumerated() {
                if let detail = SkromanIsraDatabaseHelper.shared
                   .fetchButtonDetails(uniqueId: btn.device.uniqueID)
                   .first(where: { $0.buttonNo == btn.index + 1 && $0.isShortcut == 1 }) {
                    selectedIndexes.insert(i)
                }
            }

            devicebuttonsCollectionView.reloadData()
        }

    private func registerXib() {
        let nib = UINib(nibName: "ShortcutButtonsCollectionViewCell", bundle: nil)
        devicebuttonsCollectionView.register(nib, forCellWithReuseIdentifier: "ShortcutButtonsCollectionViewCell")
        devicebuttonsCollectionView.dataSource = self
        devicebuttonsCollectionView.delegate = self
    }
    
    func submitSelectedButtons() {
        let url = "http://3.7.18.55:3000/skroman/editButtonShortcuts"
        
        var shortcutsPayload: [[String: Any]] = []

        for index in selectedIndexes {
            let target = buttons[index]

            if let detail = SkromanIsraDatabaseHelper.shared
                .fetchButtonDetails(uniqueId: target.device.uniqueID)
                .first(where: { $0.buttonNo == target.index + 1 }) {

                let shortcut = [
                    "deviceServerId": detail.deviceServerId,
                    "isShortcut": 1
                ] as [String : Any]
                shortcutsPayload.append(shortcut)
            }
        }

        let parameters: [String: Any] = [
            "shortcuts": shortcutsPayload
        ]

        print("parameters sh add \(parameters)")

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("✅ API Success: \(value)")
                    
                    self.delegate?.showSuccessPopup()
                    
                    for (i, target) in self.buttons.enumerated() {
                        if let detail = SkromanIsraDatabaseHelper.shared
                            .fetchButtonDetails(uniqueId: target.device.uniqueID)
                            .first(where: { $0.buttonNo == target.index + 1 }) {
                            
                            let newShortcutValue = self.selectedIndexes.contains(i) ? 1 : 0
                            SkromanIsraDatabaseHelper.shared.updateShortcutFlag(buttonId: detail.buttonId, isShortcut: newShortcutValue)
                            
                            print("🛠️ Updated \(detail.buttonId) -> isShortcut: \(newShortcutValue)")
                        }
                    }




                case .failure(let error):
                    print("❌ API Error: \(error.localizedDescription)")
                    if let data = response.data,
                       let str = String(data: data, encoding: .utf8) {
                        print("🔍 Server response: \(str)")
                    }
                }
            }
    }
    
    @objc func showPopupScene() {
           // delegate?.showSuccessPopup()
        }
    
    
   


}


extension ShortcutDeviceButtonCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttons.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
            let cell = cv.dequeueReusableCell(
              withReuseIdentifier: "ShortcutButtonsCollectionViewCell",
              for: ip
            ) as! ShortcutButtonsCollectionViewCell

            let target = buttons[ip.item]

            // 1) Label
            switch mode {
            case .dimming: cell.buttonNamelabel.text = "Light \(target.index + 1)"
            case .fan:      cell.buttonNamelabel.text = "Fan   \(target.index + 1)"
            }

            // 2) Background
            cell.deviceview.backgroundColor = (target.currentState == "1")
                ? UIColor(hex: "#FAEDCB")
                : UIColor(hex: "#FFFFFF")

          
            let iconName = (mode == .dimming)
                ? "bulb.fill"
                : "fan.fill"
            cell.buttonImageView.image = UIImage(systemName: iconName)

    
            cell.selectedImageView.isHidden = !selectedIndexes.contains(ip.item)

            return cell
        }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.item
        if selectedIndexes.contains(index) {
            selectedIndexes.remove(index)
        } else {
            selectedIndexes.insert(index)
        }
        collectionView.reloadItems(at: [indexPath])
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 10
        let insets: CGFloat = 10 // left + right insets (5 each)
        let totalSpacing = (numberOfColumns - 1) * spacing + insets
        let width = (collectionView.frame.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    }


}
extension AddShortcutButtonsViewController: ShortcutCellDelegate {
    func showSuccessPopup() {
//        showPopupPresenter.showPopup1(on: self.view,
//                                      animationName: "success",
//                                      title: "Success!",
//                                      subtitle: "Shortcut Buttons Successfully Selected!")
    }
}
