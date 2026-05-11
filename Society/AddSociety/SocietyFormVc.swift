//
//  SocietyFormVc.swift
//  SkromanIsra
//
//  Created by Admin on 02/02/26.
//

import UIKit
import DropDown
import SwiftKeychainWrapper
class SocietyFormVc: UIViewController {
    var society: Society?
    @IBOutlet weak var mobileText: UITextField!
    
    @IBOutlet weak var flatNumberText: UITextField!
    
    @IBOutlet weak var wingtext: UITextField!
    
    @IBOutlet weak var floorNumber: UITextField!
    
    @IBOutlet weak var areaSqft: UITextField!
    
    @IBOutlet weak var parkingSlot: UITextField!
    
    @IBOutlet weak var flatTypeView: UIView!
    
    @IBOutlet weak var residentTypeView: UIView!
    
    @IBOutlet weak var idProofImageView: UIImageView!
    
    @IBOutlet weak var residentTypeImageview: UIImageView!
    
    @IBOutlet weak var flatType: UILabel!
    
    @IBOutlet weak var residentType: UILabel!
    
    
    @IBOutlet weak var submitButton: UIButton!
    var selectedImageView: UIImageView?
    
    let flatTypeDropDown = DropDown()
    let flatTypes = ["1 BHK", "2 BHK", "3 BHK", "4 BHK"]
    let residentTypeDropDown = DropDown()
    let flatresidentType = ["Owner", "Tenant"]
    
    var isDropdownVisible = false
    var selectedFlatType: String?
    var selectedResidentType: String?
    
    var idProofImage: UIImage?
    var residentImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let society = society {
            print("Received society:", society.id)
        }
        
        
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        
        let placeholderColor = UIColor.white.withAlphaComponent(0.6)
        
        setPlaceholderColor(mobileText, color: placeholderColor)
        setPlaceholderColor(flatNumberText, color: placeholderColor)
        setPlaceholderColor(wingtext, color: placeholderColor)
        setPlaceholderColor(floorNumber, color: placeholderColor)
        setPlaceholderColor(areaSqft, color: placeholderColor)
        setPlaceholderColor(parkingSlot, color: placeholderColor)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(flatTypeTapped))
        flatTypeView.isUserInteractionEnabled = true
        flatTypeView.addGestureRecognizer(tapGesture)
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(residentTypeTapped))
        residentTypeView.isUserInteractionEnabled = true
        residentTypeView.addGestureRecognizer(tapGesture1)
        
        idProofImageView.isUserInteractionEnabled = true
        residentTypeImageview.isUserInteractionEnabled = true
        
        let idTap = UITapGestureRecognizer(target: self, action: #selector(idProofTapped))
        idProofImageView.addGestureRecognizer(idTap)
        
        let residentTap = UITapGestureRecognizer(target: self, action: #selector(residentproofTypeTapped))
        residentTypeImageview.addGestureRecognizer(residentTap)
        setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    
    @IBAction func backbtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func setPlaceholderColor(_ textField: UITextField, color: UIColor) {
        guard let placeholder = textField.placeholder else { return }
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color]
        )
    }
    
    
    func setupUI() {

        let radius: CGFloat = 10

        // TextFields
        [mobileText,
         flatNumberText,
         wingtext,
         floorNumber,
         areaSqft,
         parkingSlot].forEach {
            $0?.layer.cornerRadius = radius
            $0?.layer.masksToBounds = true
            $0?.layer.borderWidth = 0.5
            $0?.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        }

       
        flatTypeView.layer.cornerRadius = radius
        residentTypeView.layer.cornerRadius = radius

        flatTypeView.layer.borderWidth = 0.5
        residentTypeView.layer.borderWidth = 0.5

        flatTypeView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        residentTypeView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor

      
        idProofImageView.layer.cornerRadius = radius
        residentTypeImageview.layer.cornerRadius = radius

        idProofImageView.clipsToBounds = true
        residentTypeImageview.clipsToBounds = true

        // Submit Button
        submitButton.layer.cornerRadius = 12
        submitButton.clipsToBounds = true
        submitButton.tintColor =  .white
    }

    
    
    @IBAction func submit(_ sender: Any) {
        submitJoinSociety()
    }
    
    @objc func flatTypeTapped() {
        flatTypeDropDown.anchorView = flatTypeView
        flatTypeDropDown.dataSource = flatTypes
        flatTypeDropDown.bottomOffset = CGPoint(x: 0, y: flatTypeView.bounds.height)
        
        flatTypeDropDown.selectionAction = { [weak self] index, item in
            print("Selected Flat Type:", item)
            self?.flatType.text = item
            self?.selectedFlatType = item
            
        }
        
        flatTypeDropDown.show()
    }
    
    @objc func residentTypeTapped() {
        residentTypeDropDown.anchorView = residentTypeView
        residentTypeDropDown.dataSource = flatresidentType
        residentTypeDropDown.bottomOffset = CGPoint(x: 0, y: residentTypeView.bounds.height)
        
        residentTypeDropDown.selectionAction = { [weak self] index, item in
            print("Selected Flat Type:", item)
            self?.residentType.text = item
            self?.selectedResidentType = item
            
            
        }
        residentTypeDropDown.show()
    }
    
    @objc func idProofTapped() {
        selectedImageView = idProofImageView
        showImagePickerOptions()
    }
    
    @objc func residentproofTypeTapped() {
        selectedImageView = residentTypeImageview
        showImagePickerOptions()
    }
    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
        
    }
    
    func showImagePickerOptions() {
        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.openImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default) { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    
    func submitJoinSociety() {
        
        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""
        
        guard
            let url = URL(string: MainApi.url("skroman/society-management/resident/join-society")),
            let idProofImage = idProofImage,
            let residentImage = residentImage
        else {
            print("❌ Missing required data")
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // MARK: - Helpers
        func appendText(_ key: String, _ value: String) {
            data.append("--\(boundary)\r\n")
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            data.append("\(value)\r\n")
        }
        
        func appendImage(_ key: String, _ image: UIImage) {
            let imageData = image.jpegData(compressionQuality: 0.7) ?? Data()
            data.append("--\(boundary)\r\n")
            data.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key).jpg\"\r\n")
            data.append("Content-Type: image/jpeg\r\n\r\n")
            data.append(imageData)
            data.append("\r\n")
        }
        
        // MARK: - TEXT PARAMETERS
        appendText("residentType", selectedResidentType ?? "")
        appendText("flatNo", flatNumberText.text ?? "")
        appendText("floor", floorNumber.text ?? "")
        appendText("wingId", wingtext.text ?? "")
        appendText("societyId", society?.societyId ?? "")
        appendText("userId", userId)
        appendText("parkingSlot", parkingSlot.text ?? "")
        appendText("areaSquareFeet", areaSqft.text ?? "")
        appendText("flatType", selectedFlatType ?? "")
        appendText("mobile", mobileText.text ?? "")
        
        // MARK: - IMAGE PARAMETERS
        appendImage("idProofPhoto", idProofImage)
        appendImage("residentPhoto", residentImage)
        
        // MARK: - DEBUG PRINTS
        print("📤 Submit Join Society Parameters")
        print("residentType:", selectedResidentType ?? "")
        print("flatNo:", flatNumberText.text ?? "")
        print("floor:", floorNumber.text ?? "")
        print("wingId:", wingtext.text ?? "")
        print("societyId:", society?.societyId ?? "")
        print("userId:", userId)
        print("parkingSlot:", parkingSlot.text ?? "")
        print("areaSquareFeet:", areaSqft.text ?? "")
        print("flatType:", selectedFlatType ?? "")
        print("mobile:", mobileText.text ?? "")
        
        print("idProofPhoto size:",
              (idProofImage.jpegData(compressionQuality: 1.0)?.count ?? 0) / 1024, "KB")
        
        print("residentPhoto size:",
              (residentImage.jpegData(compressionQuality: 1.0)?.count ?? 0) / 1024, "KB")
        
        // MARK: - FINALIZE BODY
        data.append("--\(boundary)--\r\n")
        request.httpBody = data
        
        // MARK: - API CALL
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "No response from server")
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    let message = json["message"] as? String ?? "Something went wrong"
                    
                    DispatchQueue.main.async {
                        if message == "Join request submitted successfully" {
                            self.showAlert(title: "Success", message: message)
                        } else {
                            self.showAlert(title: "Error", message: message)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Invalid server response")
                }
            }
            
        }.resume()
        
    }
    func showAlert(title: String, message: String) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in

           
            if title == "Success" {

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as! MainHomeViewController

              
                self.navigationController?.setViewControllers([vc], animated: true)

               
            }
        }

        alert.addAction(okAction)
        present(alert, animated: true)
    }


    
}


extension SocietyFormVc: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {

        let image: UIImage?

        if let edited = info[.editedImage] as? UIImage {
            image = edited
        } else {
            image = info[.originalImage] as? UIImage
        }

        guard let finalImage = image else {
            dismiss(animated: true)
            return
        }

       
        selectedImageView?.image = finalImage

        
        if selectedImageView === idProofImageView {
            idProofImage = finalImage
        } else if selectedImageView === residentTypeImageview {
            residentImage = finalImage
        }

        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
