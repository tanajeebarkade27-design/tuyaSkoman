//
//  RazorPayViewController.swift
//  SkromanIsra
//
//  Created by Admin on 20/05/25.
//

import UIKit
import Razorpay
 import Alamofire


class RazorPayViewController: UIViewController {
    
    @IBOutlet weak var confirmpayment: UIButton!
    
    
    let  razorPayKey = "rzp_test_3NBXqGqjXF1DCK"
    var razorpay : RazorpayCheckout? = nil
    var orderID: String?
    var orderAmount: Int?
    
    var mearchant : MearchentDetails =  MearchentDetails.getdefaultData()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func payment(_ sender: Any) {
        createOrder()
        
    }
    
    func createOrder() {
        let url = MainApi.url("skroman/payment/create-order")
        let parameters: [String: Any] = [
            "amount": 10000, // For example, INR 100 = 10000 paise
            "currency": "INR",
            "receipt": "Bill_1"
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: OrderResponse.self) { response in
                switch response.result {
                case .success(let orderResponse):
                    print("\(orderResponse)")
                    
                    // Store values
                    self.orderID = orderResponse.order.id
                    self.orderAmount = orderResponse.order.amount
                    
                    // Open Razorpay checkout
                    self.openRazarpaycheckout()
                    
                case .failure(let error):
                    print("❌ Error: \(error.localizedDescription)")
                }
            }
    }

    
    
    
    func openRazarpaycheckout() {
        guard let orderID = orderID, let amount = orderAmount else {
            print("❌ Missing order details")
            return
        }

        // Use the delegate with data to get full Razorpay response
        razorpay = RazorpayCheckout.initWithKey(razorPayKey, andDelegateWithData: self)

        let options: [String: Any] = [
            "key": razorPayKey,
            "amount": amount, // in paise
            "currency": "INR",
            "name": mearchant.name ?? "",
            "description": "Purchase description",
            "order_id": orderID,
            "image": mearchant.logo ?? "",
            "prefill": [
                "contact": "9797979797",
                "email": "foo@bar.com"
            ],
            "theme": [
                "color": "#F37254"
            ]
        ]

        if let razorpay = self.razorpay {
            razorpay.open(options)
        } else {
            print("❌ Razorpay not initialized")
        }
    }


    func  verifyPayment(){
        let verifyUrl = MainApi.url("skroman/payment/verify")
        
        
        
    }
  
    func verifyPayment(orderID: String, paymentID: String, signature: String) {
        let url = MainApi.url("skroman/payment/verify")
        
        let parameters: [String: Any] = [
            "razorpay_order_id": orderID,
            "razorpay_payment_id": paymentID,
            "razorpay_signature": signature
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let dict = value as? [String: Any],
                       let success = dict["success"] as? Bool, success {
                        self.presentAlert(withTitle: "Payment Verified", message: "Your payment was successful and verified.")
                    } else {
                        let message = (value as? [String: Any])?["message"] as? String ?? "Verification failed."
                        self.presentAlert(withTitle: "Verification Failed", message: message)
                    }
                case .failure(let error):
                    print("❌ Verification API error: \(error.localizedDescription)")
                    self.presentAlert(withTitle: "Error", message: "Verification request failed.")
                }
            }
    }

    
}
    
extension RazorPayViewController: RazorpayPaymentCompletionProtocolWithData {
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        print("❌ Razorpay Payment Error - Code: \(code), Description: \(str)")
        print("Error Data: \(String(describing: response))")
        presentAlert(withTitle: "Payment Failed", message: str)
    }
    
    func presentAlert(withTitle title :String?, message:String?){
        DispatchQueue.main.async {
            let alertControntrller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "ok", style: .default)
            alertControntrller.addAction(okAction)
            self.present(alertControntrller, animated: true, completion: nil)
        }
        
    }
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]?)
 {
        print("✅ Razorpay Payment Success")
        print("Response Data: \(response)")

     if let razorpay_order_id = response?["razorpay_order_id"] as? String,
        let razorpay_signature = response?["razorpay_signature"] as? String {

            // Call verify API
            verifyPayment(orderID: razorpay_order_id,
                          paymentID: payment_id,
                          signature: razorpay_signature)
        } else {
            presentAlert(withTitle: "Error", message: "Missing payment verification data")
        }
    }


}



struct MearchentDetails{
    let  name: String?
    let logo: String?
    
}


extension MearchentDetails{
static  func getdefaultData() -> MearchentDetails {
        
    let details = MearchentDetails.init(name: "Skroman Switches", logo: "AppIcon1"
    )
    return details
        
    }
    
}










struct OrderResponse: Codable {
    let success: Bool
    let order: Order
}

struct Order: Codable {
    let amount: Int
    let amount_due: Int
    let amount_paid: Int
    let attempts: Int
    let created_at: Int
    let currency: String
    let entity: String
    let id: String
    let notes: [String]?
    let offer_id: String?
    let receipt: String
    let status: String
}
