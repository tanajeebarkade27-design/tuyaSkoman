import UIKit
import Alamofire
import SwiftKeychainWrapper

class ForgetPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var backButton: UIButton!
   
    @IBOutlet weak var verifyButton: UIButton!
    
    
    @IBOutlet weak var appImageView: UIView!
    
    @IBOutlet weak var backgroundScreen: UIImageView!
    
    @IBOutlet weak var forgetPasswordView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        backgroundScreen.contentMode = .scaleAspectFill
        backgroundScreen.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundScreen.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundScreen.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundScreen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundScreen.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    
        
        verifyButton.backgroundColor = .white
        verifyButton.setTitleColor(.black, for: .normal)
        verifyButton.layer.cornerRadius = 10
        verifyButton.layer.masksToBounds = true
        let gray6 = UIColor(named: "systemGray6") ?? UIColor.systemGray
        emailText.attributedPlaceholder = NSAttributedString(
            string: " Enter E-mail Address",
            attributes: [NSAttributedString.Key.foregroundColor: gray6]
        )
        backButton.setTitle("", for: .normal)
      
       
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        appImageView.borderWidth =  0.5
        appImageView.borderColor =  .green
        appImageView.cornerRadius =  15
        appImageView.clipsToBounds =  true
        forgetPasswordView
        forgetPasswordView.borderWidth =  0.5
        forgetPasswordView.borderColor =  .green
        forgetPasswordView.cornerRadius =  15
        forgetPasswordView.clipsToBounds =  true
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func addGradientappBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {
        // Remove old gradient layer if present
        view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorder" })

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBorder"

        // Set gradient colors (green → blue) with some transparency
        gradientLayer.colors = [
            UIColor.green.withAlphaComponent(0.5).cgColor,
            UIColor.blue.withAlphaComponent(0.5).cgColor
        ]

        // Set gradient direction: top-left to bottom-right
        gradientLayer.startPoint = CGPoint(x: 0, y: 0) // top-left
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)   // bottom-right

        gradientLayer.frame = view.bounds

        // Mask with shape path (rounded border only)
        let shapeLayer = CAShapeLayer()
        let insetRect = view.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        shapeLayer.path = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        gradientLayer.mask = shapeLayer

        view.layer.addSublayer(gradientLayer)
    }

    
    func addGradientBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {
        // Remove existing gradient layer (if any)
        view.layer.sublayers?.removeAll(where: { $0.name == "GradientBorder" })

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBorder"
        gradientLayer.colors = [
            UIColor.green.withAlphaComponent(0.5).cgColor,
            UIColor.blue.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1) // bottom-left
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)   // top-right
        gradientLayer.frame = view.bounds

        // Create border shape path
        let shapeLayer = CAShapeLayer()
        let insetRect = view.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        shapeLayer.path = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        // Apply the mask to only stroke edges
        gradientLayer.mask = shapeLayer

        view.layer.addSublayer(gradientLayer)
    }

    deinit {
        // Remove observers when the view is deallocated
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func verifyButton(_ sender: Any) {
        SendOTPFunction()
    }

    func SendOTPFunction() {
        guard let emailId = emailText.text, !emailId.isEmpty else {
            showAlert(title: "Error", message: "Please enter an email address.")
            return
        }

        let send_otp_Params: [String: String] = ["emailId": emailId]

        AF.request("http://3.7.18.55:3000/skroman/userapi/forgotpassOTP",
                   method: .post,
                   parameters: send_otp_Params,
                   encoding: JSONEncoding.default,
                   headers: ["Content-Type": "application/json"])
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let jsonResponse = value as? [String: Any],
                       let message = jsonResponse["msg"] as? String {
                        if message == "user not exists" {
                            self.showAlert(title: "Error", message: "Enter a registered email ID.")
                        } else if message == "success send otp" {
                            self.showAlert(title: "Success", message: "OTP sent successfully.") {
                                self.navigateToReset()
                            }
                        }
                    }
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
    }

    // Show Alert
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        self.present(alert, animated: true, completion: nil)
    }

    // Navigate to Login
    func navigateToReset() {
        if let resetVC = storyboard?.instantiateViewController(withIdentifier: "ResetPasswordViewController") as? ResetPasswordViewController {
            resetVC.emailId = emailText.text
            navigationController?.pushViewController(resetVC, animated: true)
        }
    }

    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            self.view.frame.origin.y = -keyboardHeight / 2 // Move the view up
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0 // Reset the view position
    }

    // Hide keyboard when return key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
