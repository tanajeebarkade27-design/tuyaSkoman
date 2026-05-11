import UIKit
import SwiftKeychainWrapper
import Alamofire

class EditprofileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var editEmailButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var contactNumberText: UITextField!
    @IBOutlet weak var addressText1: UITextField!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var addressText2: UITextField!
    @IBOutlet weak var stateText: UITextField!
    @IBOutlet weak var pinCodeText: UITextField!
    @IBOutlet weak var distText: UITextField!
    
    @IBOutlet weak var dataView: UIView!
    
    @IBOutlet weak var imagBackgroundView: UIView!
    
    @IBOutlet weak var emailIdLabel: UILabel!
    
    @IBOutlet weak var viewBackground: UIView!
    
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var backgroungdImage: UIImageView!
    
    
    @IBOutlet weak var deleteAccountView: UIView!
    
    // When user is redirected here because profile is incomplete,
    // show a one-time prompt to complete profile.
    var shouldShowCompleteProfilePopup: Bool = false
    private var didShowCompleteProfilePopup: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserData()
        setPlaceholderColor()
        backgroungdImage.contentMode = .scaleAspectFill
        backgroungdImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroungdImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroungdImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroungdImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroungdImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        deleteAccountView.backgroundColor =  UIColor.white.withAlphaComponent(0.07)
        deleteAccountView.clipsToBounds =  true
        deleteAccountView.cornerRadius =  10
        
        imagBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
//        dataView.backgroundColor =  UIColor.white.withAlphaComponent(0.05)
        dataView.clipsToBounds =  true
        dataView.cornerRadius =  10
        viewBackground.cornerRadius =  10
        viewBackground.clipsToBounds =  true
        
        imagBackgroundView.cornerRadius = 15
        imagBackgroundView.clipsToBounds =  true
        
        addGradientappBorder(to: imagBackgroundView, cornerRadius: 10 ,lineWidth: 0.5)
        userImageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        editEmailButton.setTitle("", for: .normal)
        backButton.setTitle("", for: .normal)
        editImageButton.setTitle("", for: .normal)
        contactNumberText.keyboardType = .numberPad
            pinCodeText.keyboardType = .numberPad
        imagePicker.delegate = self
        
        // Capsule text fields (modern UI)
        [nameTextField, contactNumberText, addressText1, addressText2, stateText, pinCodeText, distText].forEach {
            $0?.applyCapsuleStyle(textColor: UIColor.white)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(deleteAccountTapped))
            deleteAccountView.isUserInteractionEnabled = true
            deleteAccountView.addGestureRecognizer(tap)

    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height / 2 // Adjust based on layout
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

    
    
    func setPlaceholderColor() {
        
        let color = UIColor.lightGray   
        
        nameTextField.attributedPlaceholder = NSAttributedString(
            string: "Name",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
        
        contactNumberText.attributedPlaceholder = NSAttributedString(
            string: "Contact Number",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
        
        addressText1.attributedPlaceholder = NSAttributedString(
            string: "Address Line 1",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
        
        addressText2.attributedPlaceholder = NSAttributedString(
            string: "Address Line 2",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
        
        stateText.attributedPlaceholder = NSAttributedString(
            string: "State",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
        
        pinCodeText.attributedPlaceholder = NSAttributedString(
            string: "Pin Code",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
        
        distText.attributedPlaceholder = NSAttributedString(
            string: "District",
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
    }
    func addGradientappBorder(to view: UIView, cornerRadius: CGFloat, lineWidth: CGFloat) {
        
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

    // MARK: - Fetch User Data
    func fetchUserData() {
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        
        guard !userId.isEmpty else {
            print("User ID is missing")
            return
        }
        
        let users = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
        
        if let user = users.first {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.nameTextField.text = user.userName
                self.contactNumberText.text = user.mobileNumber
                self.addressText1.text = user.address1
                self.addressText2.text = user.address2
                self.stateText.text = user.state
                self.pinCodeText.text = user.pinCode
                self.distText.text = user.city
                self.emailIdLabel.text =  user.emailId
                
                // Load user image asynchronously
                if let imageUrl = user.imageUser, !imageUrl.isEmpty {
                    self.loadUserImage(from: imageUrl)
                }
                
                print("✅ User data loaded successfully")
            }
        } else {
            print("⚠️ No user found for userId: \(userId)")
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldShowCompleteProfilePopup && !didShowCompleteProfilePopup {
            didShowCompleteProfilePopup = true
            let alert = UIAlertController(title: "Complete Profile", message: "Complete your profile", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
   
    // MARK: - Load User Image Asynchronously
    func loadUserImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            self.userImageView.image = UIImage(named: "user-4")
            return
        }

        DispatchQueue.global(qos: .background).async {
            if let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {

                DispatchQueue.main.async {
                    self.userImageView.image = image
                }

            } else {
                DispatchQueue.main.async {
                    print("⚠️ Failed to load user image from URL: \(urlString)")
                    self.userImageView.image = UIImage(named: "user-4")
                }
            }
        }
    }


    @IBAction func editImageButtonTapped(_ sender: UIButton) {
           let alert = UIAlertController(title: "Choose Image", message: "Select an option", preferredStyle: .actionSheet)

           alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
               self.openCamera()
           }))

           alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
               self.openGallery()
           }))

           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

           present(alert, animated: true)
       }

       
       func openCamera() {
           if UIImagePickerController.isSourceTypeAvailable(.camera) {
               imagePicker.sourceType = .camera
               present(imagePicker, animated: true)
           } else {
               print("⚠️ Camera is not available on this device")
           }
       }

       
       func openGallery() {
           if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
               imagePicker.sourceType = .photoLibrary
               present(imagePicker, animated: true)
           } else {
               print("⚠️ Photo library is not available")
           }
       }

       func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
           if let selectedImage = info[.originalImage] as? UIImage {
               userImageView.image = selectedImage // Set selected image to UIImageView
           }
           dismiss(animated: true)
       }

       func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
           dismiss(animated: true)
       }

       @IBAction func BackButton(_ sender: Any) { 
           navigationController?.popViewController(animated: true)
       }

       @IBAction func saveButton(_ sender: Any) {
           // Prevent users from getting stuck on incomplete profile.
           guard validateFields() else { return }
           editProfileApi()
       }

       @IBAction func editEmailButton(_ sender: Any) {
         
           print("chnage email")
           let vc = storyboard?.instantiateViewController(withIdentifier: "ChangeEmailViewController")  as! ChangeEmailViewController
           
           navigationController?.pushViewController(vc, animated: true)
       }
    
    func loadImageName() -> String? {
        return UserDefaults.standard.string(forKey: "savedProfileImage")
    }

    func editProfileApi() {
        guard let userId = KeychainWrapper.standard.string(forKey: "userId") else {
            print("User ID not found")
            return
        }

        let users = SkromanIsraDatabaseHelper.shared.fetchUserById(userId: userId)
        
        guard let user = users.first else {
            print("Failed to fetch user data for userId: \(userId)")
            return
        }

        let parameters: [String: String] = [
            "userId": userId,
            "emailId": user.emailId ?? "",
            "userName": nameTextField.text ?? "",
            "mobileNumber": contactNumberText.text ?? "",
            "address1": addressText1.text ?? "",
            "address2": addressText2.text ?? "",
            "city": distText.text ?? "",
            "state": stateText.text ?? "",
            "pinCode": pinCodeText.text ?? ""
        ]

        let boundary = UUID().uuidString
        var body = Data()

        // Append parameters
        print("📤 Parameters being sent:")
        for (key, value) in parameters {
            print("\(key): \(value)")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Load image from UserDefaults or UIImageView
        if let imageName = loadImageName() {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imagePath = documentsURL.appendingPathComponent(imageName)
            
            print("📷 Image file path: \(imagePath.path)")
            
            if let imageData = try? Data(contentsOf: imagePath) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"userImage\"; filename=\"\(imageName)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            } else {
                print("⚠️ Failed to load image from path: \(imagePath.path)")
            }
        } else if let image = userImageView.image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let imageName = "profile.jpg"
            print("📷 Using image from UIImageView")

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"imageUser\"; filename=\"\(imageName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        } else {
            print("⚠️ No image found to upload")
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Prepare request
        let url = URL(string: MainApi.url("skroman/profileapi/profileuserupdate"))!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📩 Response Status Code: \(httpResponse.statusCode)")
            }

            guard let data = data, !data.isEmpty else {
                print("⚠️ Received empty response from server")
                return
            }

            // Print raw response (before parsing)
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("📜 Raw Response: \(rawResponse)")
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("✅ Parsed JSON Response: \(jsonResponse ?? [:])")

                DispatchQueue.main.async {
                    
                    let message = jsonResponse?["msg"] as? String ?? "Something went wrong"
                    
                    print("📩 API Message: \(message)")
                    
                    // ✅ STRICT SUCCESS CHECK
                    if message == "Success Update the User Profile" {
                        self.showSuccessAndNavigate(message: message)
                    } else {
                        // ❌ ANY OTHER CASE → ERROR
                        self.showAlert(message: message)
                    }
                }
                
            }  catch {
                print("❌ JSON Parsing Error: \(error.localizedDescription)")
            }
        }

        task.resume()
    }
    
    func showSuccessAndNavigate(message: String) {
        
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController,
               let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = windowScene.delegate as? UIWindowSceneDelegate,
               let window = delegate.window {
                
                window?.rootViewController = tabBarController
                window?.makeKeyAndVisible()
            }
        })
        
        self.present(alert, animated: true)
    }
    func validateFields() -> Bool {
        // Generic message requested by UX
        func showFillAllInfo() {
            showAlert(message: "Please fill all info")
        }
        
        if (nameTextField.text ?? "").isEmpty {
            showFillAllInfo()
            return false
        }
        
        if (contactNumberText.text ?? "").isEmpty {
            showFillAllInfo()
            return false
        }
        
        if contactNumberText.text!.count != 10 {
            showAlert(message: "Enter valid 10 digit mobile number")
            return false
        }
        
        if (addressText1.text ?? "").isEmpty {
            showFillAllInfo()
            return false
        }
        
        if (stateText.text ?? "").isEmpty {
            showFillAllInfo()
            return false
        }
        
        if (pinCodeText.text ?? "").isEmpty {
            showFillAllInfo()
            return false
        }
        
        if pinCodeText.text!.count != 6 {
            showAlert(message: "Enter valid pincode")
            return false
        }
        
        return true
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func deleteAccountTapped() {
        showDeleteAccConfirmation()
    }

    func showDeleteAccConfirmation() {

        // Step 1: Are you sure popup
        let confirmAlert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account?",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        confirmAlert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
            self.showDeleteInputPopup()
        })

        present(confirmAlert, animated: true)
    }


    
    func showDeleteInputPopup() {

        let inputAlert = UIAlertController(
            title: "Confirm Delete",
            message: "Type DELETE to confirm",
            preferredStyle: .alert
        )

        inputAlert.addTextField { textField in
            textField.placeholder = "DELETE"
            textField.autocapitalizationType = .allCharacters
        }

        inputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        inputAlert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in

            let userInput = inputAlert.textFields?.first?.text ?? ""

            if userInput.uppercased() == "DELETE" {
                self.delete_user()
            } else {
                self.showWrongDeleteText()
            }
        })

        present(inputAlert, animated: true)
    }


    // MARK: Wrong DELETE entered

    func showWrongDeleteText() {

        let alert = UIAlertController(
            title: "Error",
            message: "Please type DELETE exactly to continue.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func navigateToLogin(){
        let loginVc = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(loginVc, animated: true)


    }
    
    func delete_user() {
        let email = KeychainWrapper.standard.string(forKey: "emailId")
        guard let email = email else { return }
        
        let delete_user_params : Parameters = [
            
            "emailId": email
            
        ]
        
        
        AF.request(MainApi.url("skroman/userapi/deleteuser"), method: .post, parameters: delete_user_params, encoding: JSONEncoding.default, headers: nil).response { response in
            debugPrint(response)
            
            switch response.result
            {
            case .success(let data) :
                do {
                    
                    
                    let jsonOne = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    
                    if let parseJson = jsonOne,
                       
                        let msg = parseJson["msg"] as? String {
                        
                        
                        if msg == "Successfully delete user" {
                            
                            let when = DispatchTime.now() + 2
                            
                            DispatchQueue.main.asyncAfter(deadline: when)  {
                                
                                
                                self.navigateToLogin()
                            }
                        }
                        
                        else {
                            
                           // self.allAlert(alertTitle: "Error", alertMessage: "User not deleted")
                            
                        }
                        
                    }
                    
                }
                catch {
                
                }
                
                
            case .failure(let err):
                print(err.localizedDescription)
                
            }
            
        }.resume()
        
    }
    



}
