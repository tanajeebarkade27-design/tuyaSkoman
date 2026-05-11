//
//  roomsDeviceCollectionViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 23/06/25.
//
import UIKit
import SwiftKeychainWrapper
import AWSCore
import AWSIoT
import Alamofire

class roomsDeviceCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var deviceImage: UIImageView!

    var devices: [Device] = []
    
    // ✅ Dictionary to store state by uniqueID
    var deviceStateMap: [String: DeviceStateArray] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.cornerRadius = 23.5
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    }

    /// Configure the cell
    func configure(buttonTitle: String, imageName: String, devices: [Device], deviceStates: [DeviceStateArray]) {
        self.deviceName.text = buttonTitle
        self.devices = devices
        self.deviceStateMap = Dictionary(uniqueKeysWithValues: deviceStates.map { ($0.uniqueID, $0) })

        self.deviceImage.tintColor = .white
        self.deviceImage.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)

        if buttonTitle == "Lights" {
            if shouldHighlightLightBulb() {
                deviceImage.tintColor = .orange
            }
        } else if buttonTitle.lowercased() == "curtains" {
            let curtainStatus = shouldHighlightCurtains()
            self.deviceImage.image = UIImage(named: curtainStatus.imageName)?.withRenderingMode(.alwaysTemplate)
            self.deviceImage.tintColor = curtainStatus.tintColor
        }

    }

    private func shouldHighlightLightBulb() -> Bool {
        for device in devices {
            guard let state = deviceStateMap[device.uniqueId] else {
                return false  // No state → cannot confirm "ON"
            }

            let cNm = state.cNm
            let lightState = state.lightState

            guard cNm.count == lightState.count else { return false }

            for (cChar, lChar) in zip(cNm, lightState) {
                if cChar == "L" && lChar != "1" {
                    return false  // Light expected ON, but it's OFF
                }
            }
        }

        return true  
    }

    private func shouldHighlightCurtains() -> (imageName: String, tintColor: UIColor) {
        for device in devices {
            guard let state = deviceStateMap[device.uniqueId] else { continue }

            let cNm = state.cNm
            let lightState = state.lightState

            guard cNm.count == lightState.count else { continue }

            for (index, (cChar, lChar)) in zip(cNm, lightState).enumerated() {
                if (cChar == "O" || cChar == "Q") && lChar == "1" {
                    return ("curtrtains", .systemBlue)
                } else if (cChar == "C" || cChar == "Y") && lChar == "1" {
                    return ("curtain-filled", .systemBlue)
                }
            }
        }

       
        return ("curtain-filled", .white)
    }

   
    
}
