

//import UIKit
//import DropDown
//
//class DimmingSettingViewController: UIViewController {
//
//    @IBOutlet weak var closedButton: UIButton!
//    @IBOutlet weak var dropDownView: UIView!
//    
//    @IBOutlet weak var dimmingView: UIView!
//    let dropDown = DropDown() // Create DropDown instance
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        closedButton.setTitle("", for: .normal)
//        dropDownView.layer.cornerRadius =  8
//        dropDownView.borderColor =  .gray
//        dropDownView.borderWidth =  1
//        dimmingView.borderWidth =  1
//        dimmingView.layer.cornerRadius =  8
//        setupDropDown()
//      
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showDropDown))
//        dropDownView.addGestureRecognizer(tapGesture)
//    }
//
//    func setupDropDown() {
//        dropDown.anchorView = dropDownView  // Set anchor view
//        dropDown.dataSource = ["Type 1", "Type 2", "Type 3", "Type 4", "Type 5"] // Dropdown items
//        dropDown.direction = .bottom  // Show dropdown below the view
//        
//        // Handle selection
//        dropDown.selectionAction = { (index: Int, item: String) in
//            print("Selected item: \(item)")
//        }
//    }
//
//    @objc func showDropDown() {
//        dropDown.show()  // Show dropdown when tapped
//    }
//    
//    @IBAction func closedButton(_ sender: Any) {
//        dismiss(animated: true, completion: nil)
//    }
//}
