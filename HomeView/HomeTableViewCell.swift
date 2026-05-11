//import UIKit
//
//class HomeTableViewCell: UITableViewCell {
//
//    @IBOutlet weak var homeNameLabel: UILabel!
//    @IBOutlet weak var homeSettingButton: UIButton!
//    @IBOutlet weak var cellbackgroundView: UIView!
//    @IBOutlet weak var defaultHomeImage: UIImageView!
//    
//    @IBOutlet weak var homeImageView: UIImageView!
//    
//    var parentVC: HomeScreenViewController?
//
//       
//    @IBOutlet weak var mainbackrogundView: UIView!
//    
//    func configure(with home: Home) {
//           homeNameLabel.text = home.homeName ?? "Unknown"
//           
//           if let urlString = home.homeUrl, let url = URL(string: urlString) {
//               loadImage(from: url)
//               defaultHomeImage.isHidden =  true
//           } else {
//               homeImageView.image = UIImage(named: "defaultHomeImage")  // Set a placeholder
//           }
//       }
//       
//       private func loadImage(from url: URL) {
//           DispatchQueue.global().async {
//               if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
//                   DispatchQueue.main.async {
//                       self.homeImageView.image = image
//                   }
//               }
//           }
//       }
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        
//       
//       
//        cellbackgroundView.layer.cornerRadius = 8
//        cellbackgroundView.layer.masksToBounds = true
//     
//        cellbackgroundView.layer.borderWidth = 2 // Adjust thickness
//        cellbackgroundView.layer.borderColor = UIColor.black.cgColor 
//       
//        homeSettingButton.setTitle("", for: .normal)
//       
//    }
//    
//    func applyGradientBackground() {
////         Gradient for cellbackgroundView
//        let cellGradientLayer = CAGradientLayer()
//        cellGradientLayer.frame = cellbackgroundView.bounds
//        cellGradientLayer.colors = [UIColor.black.cgColor, UIColor.gray.cgColor] // Better transition than white
//        cellGradientLayer.startPoint = CGPoint(x: 0, y: 0)  // Top-left
//        cellGradientLayer.endPoint = CGPoint(x: 1, y: 1)    // Bottom-right
//        cellGradientLayer.cornerRadius = 8
//        cellbackgroundView.layer.insertSublayer(cellGradientLayer, at: 0)
//
//
//       
//        cellbackgroundView.layer.cornerRadius = 8
//        cellbackgroundView.layer.masksToBounds = true
//    }
//
//
//    @IBAction func homeSettingButtonTapped(_ sender: UIButton) {
//        parentVC?.showBottomSheet()
//    }
//  
//
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//    }
//}
