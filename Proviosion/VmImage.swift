//
//  VmImage.swift
//  SkromanIsra
//
//  Created by Admin on 27/01/25.
//


//
//  VMultipartImage.swift
//  MultipartImageUpload
//
//  Created by Moweb on 06/06/18.
//  Copyright © 2018 Mohit Andhare. All rights reserved.
//

import UIKit

public enum Method : String { //--- add Mehtod depends on your requirement
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    
}

public enum MimeType:String { //--- add MimeType depends on your requirement
    case jpeg = "image/jpeg"
    case png = "image/png"
    case gif = "image/gif"
    
}

public typealias Image_Parameters = [String: String]

open class VMultipartImage: NSObject {
    
    public var request : URLRequest!
    public var putRequest : URLRequest!
    
    public init(_ postUrl:String,paramters:Image_Parameters, image:UIImage, imagekey:String, imageName:String, MimeType:MimeType? = .jpeg, Debug:Bool? = true) {
        
        super.init()
        
        guard let mediaImage = MediaData(image, key: imagekey, imageName: imageName, mimeType:MimeType!) else { return }
        
        guard let url = URL(string: postUrl) else { return }
        
        request = URLRequest(url: url)
        
        request.httpMethod = Method.POST.rawValue    //MARK: YAHA PE POST KIYA HAI ISNE
        
        let boundary = generateBoundary()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if Debug! {
            request.addValue("Client-ID f65203f7020dddc", forHTTPHeaderField: "Authorization") // ---- Testing code
        }
        
        let dataBody = createDataBody(withParameters: paramters, media: [mediaImage], boundary: boundary)
        
        request?.httpBody = dataBody
    }
    
    
    fileprivate func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    fileprivate func createDataBody(withParameters params: Image_Parameters?, media: [MediaData]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        
        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(photo.key ?? "DefaultValue")\"; filename=\"\(photo.filename ?? "DefaultValue.jpeg")\"\(lineBreak)")
                body.append("Content-Type: \(photo.mimeType! + lineBreak + lineBreak)")
                body.append(photo.data!)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
}

//MARK: == MY FUNCTIONS ==



open class VMultipartImageTwo: NSObject {
    
    
    public var putRequest : URLRequest!
    
    public init(_ PutUrl:String,paramters:Image_Parameters, image:UIImage, imagekey:String, imageName:String, MimeType:MimeType? = .jpeg, Debug:Bool? = true) {
        
        super.init()
        
        guard let mediaImage = MediaData(image, key: imagekey, imageName: imageName, mimeType:MimeType!) else { return }
        
        guard let url = URL(string: PutUrl) else { return }
        
        putRequest = URLRequest(url: url)
        
        putRequest.httpMethod = Method.PUT.rawValue    //MARK: YAHA PE POST KIYA HAI ISNE
        
        let boundary = generateBoundary()
        
        putRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if Debug! {
            putRequest.addValue("Client-ID f65203f7020dddc", forHTTPHeaderField: "Authorization") // ---- Testing code
        }
        
        let dataBody = createDataBody(withParameters: paramters, media: [mediaImage], boundary: boundary)
        
        putRequest?.httpBody = dataBody
    }
    
    
    fileprivate func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    fileprivate func createDataBody(withParameters params: Image_Parameters?, media: [MediaData]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        
        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(photo.key ?? "DefaultValue")\"; filename=\"\(photo.filename ?? "DefaultValue.jpeg")\"\(lineBreak)")
                body.append("Content-Type: \(photo.mimeType! + lineBreak + lineBreak)")
                body.append(photo.data!)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
}

fileprivate struct MediaData {
    let key: String?
    let filename: String?
    let data: Data?
    let mimeType: String?
    
    init?(_ image: UIImage, key: String, imageName: String, mimeType:MimeType) {
        self.key = key
        self.mimeType = mimeType.rawValue
        self.filename = imageName
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        self.data = data
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

