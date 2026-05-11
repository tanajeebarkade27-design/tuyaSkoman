//
//  ManageShortcutTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 07/08/25.
//

import UIKit

protocol ManageShortcutCellDelegate: AnyObject {
    func manageShortcutCell(_ cell: ManageShortcutTableViewCell, didUpdateSelectedServerIds serverIds: Set<String>)
}

class ManageShortcutTableViewCell: UITableViewCell {

    @IBOutlet weak var cellbackgroundView: UIView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var shortcutButtonsCollectionView: UICollectionView!

    private var buttonList: [ButtonDetails] = []
    private var stateList: [DeviceStateArray] = []
    private var selectedServerIdsByCase: [Int: Set<String>] = [:]


    private var predefindServerIds = Set<String>()
    weak var delegate: ManageShortcutCellDelegate?

    private var switchList: [SwitchItem] = []
   
        var selectedIndexbutton: Int?
    var currentDevice: Device?
    @IBOutlet weak var cellabckground: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cellbackgroundView.clipsToBounds = true
        cellbackgroundView.cornerRadius = 15
        cellbackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        cellabckground.clipsToBounds = true
        cellabckground.cornerRadius = 15
        print("switchList..\(switchList)")
        let uiNib = UINib(nibName: "ManageShortcutCollectionViewCell", bundle: nil)
        shortcutButtonsCollectionView.register(uiNib, forCellWithReuseIdentifier: "ManageShortcutCollectionViewCell")
 
    }

    private func notifyDelegate() {
        
        let combinedSet = selectedServerIdsByCase.values.reduce(into: Set<String>()) { $0.formUnion($1) }
        delegate?.manageShortcutCell(self, didUpdateSelectedServerIds: combinedSet)
    }




    func configure(with device: Device, switches: [SwitchItem]) {
        deviceNameLabel.text = device.uniqueId
        self.switchList = switches
        self.currentDevice = device

        guard let selectedIndexbutton = selectedIndexbutton else { return }

        // Reset the array for this case based on pre-selected shortcuts
        selectedServerIdsByCase[selectedIndexbutton] = Set(
            switches.compactMap { switchItem in
                if switchItem.isShortcut == 1,
                   let serverId = switchItem.buttonDetail?.deviceServerId,
                   self.shouldIncludeSwitch(switchItem, forCase: selectedIndexbutton) {
                    return serverId
                }
                return nil
            }
        )

      
        notifyDelegate()

        shortcutButtonsCollectionView.dataSource = self
        shortcutButtonsCollectionView.delegate = self
        shortcutButtonsCollectionView.reloadData()
        
        print("selectedIndexbutton:", selectedIndexbutton ?? -1)
        print("switchList count:", switchList.count)
    }

    private func shouldIncludeSwitch(_ switchItem: SwitchItem, forCase caseIndex: Int) -> Bool {
        switch caseIndex {
        case 0: return switchItem.buttonDetail?.buttonControlName == "L" && switchItem.configDim == "0"
        case 1: return ["O", "C", "Q", "Y"].contains(switchItem.buttonDetail?.buttonControlName ?? "") && switchItem.isShortcut == 1
        case 2: return switchItem.buttonDetail?.buttonControlName == "L" && switchItem.configDim == "1"
        case 3: return switchItem.buttonDetail?.buttonControlName == "F"
        case 4:
            return switchItem.buttonDetail?.buttonControlName == "A"
        default: return false
        }
    }


    private var filteredSwitchList: [SwitchItem] {
        guard let selectedIndexbutton = selectedIndexbutton else { return switchList }
        
        switch selectedIndexbutton {
        case 0:
            return switchList.filter {
                $0.buttonDetail?.buttonControlName == "L" &&
//
                $0.configDim == "0"
            }
        case 1:
            let filtered = switchList.filter {
                if let controlName = $0.buttonDetail?.buttonControlName {
                    return ["O", "C", "Q", "Y"].contains(controlName) &&
                           $0.buttonDetail?.isShortcut == 1
                }
                return false
            }
            print("📌 Case 1 filtered count: \(filtered.count)")
            for item in filtered {
                if let btn = item.buttonDetail {
                    print("➡️ ControlName: \(btn.buttonControlName), Shortcut: \(btn.isShortcut)  total \(btn)")
                }
            }
            return filtered

        case 2:
            return switchList.filter {
                $0.buttonDetail?.buttonControlName == "L" &&
//
                $0.configDim == "1"
            }
        case 3:
            return switchList.filter {
                $0.buttonDetail?.buttonControlName == "F"
//                $0.buttonDetail?.isShortcut == 1
            }
        case 4:
            let filtered = switchList.filter {
                $0.buttonDetail?.buttonControlName == "A"
            }

            print("AC switches count: \(filtered.count)")
            print("AC switches: \(filtered)")
            
            return filtered
           
        default:
            return switchList
        }
    }

    
    
}

extension ManageShortcutTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredSwitchList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ManageShortcutCollectionViewCell",
            for: indexPath
        ) as? ManageShortcutCollectionViewCell else {
            return UICollectionViewCell()
        }
        
      
        let switchItem = filteredSwitchList[indexPath.row]
           if let device = currentDevice {
               print("➡️ Passing device: \(device.uniqueId) to collection cell")
               cell.configure(with: switchItem, device: device)
           } else {
               print("❌ currentDevice is nil")
           }
       // self.shortcutButtonsCollectionView.reloadItems(at: [indexPath])
        
        
        cell.onToggle = { [weak self] buttonId, serverId, newSelected in
            guard let self = self,
                  let selectedIndexbutton = self.selectedIndexbutton else { return }

            // Get current set for this case
            var caseSet = self.selectedServerIdsByCase[selectedIndexbutton] ?? Set<String>()

            if newSelected {
                caseSet.insert(serverId)
            } else {
                caseSet.remove(serverId)
            }

            // Update dictionary
            self.selectedServerIdsByCase[selectedIndexbutton] = caseSet

            print("📌 Case \(selectedIndexbutton) selected IDs: \(caseSet)")

            // Notify VC with combined selections from all cases
            self.notifyDelegate()
        }




        
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







    
    

