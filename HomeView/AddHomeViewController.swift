//
//  AddHomeViewController.swift
//  SkromanIsra
//
//  Created by Admin on 17/02/25.
//

import UIKit
import SwiftKeychainWrapper
import Alamofire


class AddHomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var homeItemcollectionView: UICollectionView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var homePhotoView: UIView!
    @IBOutlet weak var homeImage: UIImageView!
    @IBOutlet weak var homeNameTextfield: UITextField!
    var userID : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

       
        
        // Add gesture recognizer to homePhotoView to detect taps
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openPhotoPicker))
        homePhotoView.addGestureRecognizer(tapGesture)
        homePhotoView.isUserInteractionEnabled = true
        homePhotoView.cornerRadius =  8
        homePhotoView.clipsToBounds = true
        
        let savedUserID = KeychainWrapper.standard.string(forKey: "userId")
        print("Saved User ID : =====", savedUserID!)
        
        if savedUserID != nil {
            
            userID = savedUserID
        }
        
    }
    
    @IBAction func saveHome(_ sender: Any) {
        Add_Home_Function()
    }
    
    @IBAction func backbutton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }


    @objc func openPhotoPicker() {
        let alertController = UIAlertController(title: "Choose Photo", message: "Select a photo from gallery or take a photo", preferredStyle: .actionSheet)
        
        // Check if camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
                self.openCamera()
            }))
        }
        
        // Option to select from gallery
        alertController.addAction(UIAlertAction(title: "Choose from Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        
        // Cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present the action sheet
        present(alertController, animated: true, completion: nil)
    }

    func openCamera() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        present(imagePickerController, animated: true, completion: nil)
    }

    func openGallery() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            homeImage.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate method to handle cancellation
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func Add_Home_Function() {
        // Ensure home name and user ID are not nil
        guard let home_name = homeNameTextfield.text, !home_name.isEmpty else {
            print("Home name is empty")
            return
        }
        guard let user_id = userID else {
            print("User ID is nil")
            return
        }
        
        if let selectedImage = homeImage.image {
            // If an image is selected, use the first API (multipart request)
            uploadHomeWithImage(userId: user_id, homeName: home_name, image: selectedImage)
        } else {
            // If no image is selected, use the second API (JSON request)
            uploadHomeWithoutImage(userId: user_id, homeName: home_name)
        }
    }

    func uploadHomeWithImage(userId: String, homeName: String, image: UIImage) {
        let url = "http://3.7.18.55:3000/skroman/homeapi/home"
        
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data.")
            return
        }
        
        let parameters: [String: Any] = [
            "userId": userId,
            "homeName": homeName
        ]
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Append text parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // Append image
        let imageName = "home_image.jpg"
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"homeImage\"; filename=\"\(imageName)\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        
        // End boundary
        body.append("--\(boundary)--\r\n")
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let session = URLSession.shared
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        print("Response with image: \(jsonResponse)")
                        
                        if let msg = jsonResponse["msg"] as? String, msg == "Home inserted success",
                           let homeServerId = jsonResponse["homeId"] as? String {
                            
                            let homeName = jsonResponse["homeName"] as? String ?? "Unnamed Home"
                            let homeUrl = jsonResponse["homeImage"] as? String ?? nil  // Ensure correct URL handling
                            
                            DispatchQueue.main.async {
                                self.showPopup()
                            }
                            
                            // ✅ Insert into SQLite database
                            SkromanIsraDatabaseHelper.shared.insertHome(homeServerId: homeServerId, homeName: homeName, homeUrl: homeUrl, tuyaHomeId: -1, isFamilyHome: 0)
                            
                            print("Inserted Home - ID: \(homeServerId), Name: \(homeName), Image URL: \(homeUrl ?? "nil")")
                        } else {
                            print(" Home not inserted, response message: \(jsonResponse["msg"] ?? "Unknown error")")
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func uploadHomeWithoutImage(userId: String, homeName: String) {
        let url = "http://3.7.18.55:3000/skroman/homeapi/v2/home"
        
        let parameters: [String: Any] = [
            "userId": userId,
            "homeName": homeName
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("Failed to encode JSON")
            return
        }
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let session = URLSession.shared
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        print("Response without image: \(jsonResponse)")
                        
                        if let msg = jsonResponse["msg"] as? String, msg == "Home inserted success" {
                            if let homeServerId = jsonResponse["homeId"] as? String {
                                let homeName = jsonResponse["homeName"] as? String // This can be nil
                                let homeUrl: String? = nil // Assuming no image URL
                                DispatchQueue.main.async {
                                    self.showPopup()
                                }
                                
                                SkromanIsraDatabaseHelper.shared.insertHome(homeServerId: homeServerId, homeName: homeName, homeUrl: homeUrl, tuyaHomeId: -1, isFamilyHome: 0)
                            }

                        } else {
                            print("Home not inserted:")
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }.resume()
    }


    @objc func showPopup() {
        
        showPopupPresenter.showPopup1(on: self.view,
                                     animationName: "success",
                                     title: "Success!",
                                     subtitle: "Home Added successfully")
        
       
    }

    
}
