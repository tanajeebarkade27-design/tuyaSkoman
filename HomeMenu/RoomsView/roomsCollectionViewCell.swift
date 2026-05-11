import UIKit

class RoomsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var roomBackgroundView: UIView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var numberOfDevices: UILabel!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var roomImageView: UIImageView!
    
    var parentVC: RoomViewController?
    var homeServerID: String? // Store Home Server ID
    var roomID: String?
    var selectedRoomId: String?
    var selectedHomeId: String?
    var selectedRoomName: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        roomBackgroundView.layer.cornerRadius = 8
        roomBackgroundView.layer.masksToBounds = true
        settingButton.setTitle("", for: .normal)
        
        // Set default image
        if let originalImage = UIImage(named: "gear") {
            let targetSize = settingButton.bounds.size
            settingButton.setImage(resizeImage(image: originalImage, targetSize: targetSize), for: .normal)
            settingButton.imageView?.contentMode = .scaleAspectFit
        }
    }

    @IBAction func settingButtonTapped(_ sender: UIButton) {
        guard let roomId = selectedRoomId, let homeId = selectedHomeId, let roomName = selectedRoomName else {
            print("Room ID or Home ID is nil")
            return
        }
        parentVC?.showBottomSheet(roomId: roomId, homeId: homeId, roomName: roomName)
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize = widthRatio > heightRatio
            ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
