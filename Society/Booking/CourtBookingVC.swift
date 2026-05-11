//
//  CourtBookingVC.swift
//  SkromanIsra
//
//  Created by Admin on 17/02/26.
//

import UIKit
import SwiftKeychainWrapper
import Razorpay

class CourtBookingVC: UIViewController,
                     RazorpayPaymentCompletionProtocol,
                      RazorpayPaymentCompletionProtocolWithData {
    func onPaymentError(_ code: Int32, description str: String) {
        print("❌ Payment Failed:", str)

        let alert = UIAlertController(title: "Payment Failed",
                                      message: str,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    var amenity: Amenity?
    var selectedCourt: AmenitySection?
    var slotResponse: SlotAvailabilityResponse?
    var displayDays: [SlotDay] = []
    var displaySlots: [Slot] = []
    var allSlots: [Slot] = []
    var selectedSlots: [Slot] = []
    var razorpay: RazorpayCheckout?
    var razorpayOrderId: String?
    var razorpayKey: String?
    var transactionId: String?
    var totalAmount: Int = 0
    var processingView: UIView?


    var guestCount = 0
    var maxGuests = 0
    
    var lastPreview: PricePreviewResponse?

    
    @IBOutlet weak var guestCountLabel: UILabel!
    
    @IBOutlet weak var allSlotView: UIView!
    
    @IBOutlet weak var morningSlotView: UIView!
    
    @IBOutlet weak var afternoonSlotView: UIView!
    
    @IBOutlet weak var eveningSlotView: UIView!
    
    
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    
    
    @IBOutlet weak var Finalpricelabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(image: UIImage(named: "Screen Background"))
        backgroundImage.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImage, at: 0)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if let amenityId = amenity?.amenityId {
                fetchAvailability(amenityId: amenityId)
            }
        setupSlotViewTaps()
        registerXib()
       
        maxGuests = amenity?.guestRules?.maxGuests ?? 0

          guestCount = 0
          guestCountLabel.text = "\(guestCount)"
        
       
         
         
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
   
    @IBAction func addGuestBtn(_ sender: Any) {
        guard guestCount < maxGuests else { return }

            guestCount += 1
            guestCountLabel.text = "\(guestCount)"
        callPricePreview()
        
    }
    
    
    @IBAction func minusGuestBtn(_ sender: Any) {
        
        guard guestCount > 0 else { return }

           guestCount -= 1
           guestCountLabel.text = "\(guestCount)"
        callPricePreview()
        
    }
    
    
    
    func registerXib(){
        let uinib = UINib(nibName: "SlotViewCell", bundle: nil)
        scheduleCollectionView.register(uinib, forCellWithReuseIdentifier: "SlotViewCell")
        scheduleCollectionView.dataSource = self
        scheduleCollectionView.delegate = self
    }
    
    
    func setupSlotViewTaps() {

        let allTap = UITapGestureRecognizer(target: self, action: #selector(allSlotTapped))
        allSlotView.addGestureRecognizer(allTap)
        allSlotView.isUserInteractionEnabled = true

        let morningTap = UITapGestureRecognizer(target: self, action: #selector(morningTapped))
        morningSlotView.addGestureRecognizer(morningTap)
        morningSlotView.isUserInteractionEnabled = true

        let afternoonTap = UITapGestureRecognizer(target: self, action: #selector(afternoonTapped))
        afternoonSlotView.addGestureRecognizer(afternoonTap)
        afternoonSlotView.isUserInteractionEnabled = true

        let eveningTap = UITapGestureRecognizer(target: self, action: #selector(eveningTapped))
        eveningSlotView.addGestureRecognizer(eveningTap)
        eveningSlotView.isUserInteractionEnabled = true
    }
    @objc func allSlotTapped() {
        displaySlots = allSlots
        scheduleCollectionView.reloadData()
    }
    @objc func morningTapped() {

        displaySlots = allSlots.filter {
            let hour = hourFromSlot($0.from)
            return hour >= 0 && hour < 12
        }

        scheduleCollectionView.reloadData()
    }

    
    @objc func afternoonTapped() {

        displaySlots = allSlots.filter {
            let hour = hourFromSlot($0.from)
            return hour >= 12 && hour < 18
        }

        scheduleCollectionView.reloadData()
    }
    @objc func eveningTapped() {

        displaySlots = allSlots.filter {
            let hour = hourFromSlot($0.from)
            return hour >= 19 || hour == 0
        }

        scheduleCollectionView.reloadData()
    }
    func hourFromSlot(_ time: String) -> Int {

        let df = DateFormatter()
        df.dateFormat = "HH:mm"

        guard let date = df.date(from: time) else { return 0 }

        return Calendar.current.component(.hour, from: date)
    }


   
    func fetchAvailability(amenityId: String) {

        let urlString = MainApi.url("skroman/society/amenity/v1/api/amenities/\(amenityId)/availability")

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                print("Availability API Error:", error)
                return
            }

            guard let data = data else { return }

            do {
                let availability =
                    try JSONDecoder().decode(SlotAvailabilityResponse.self, from: data)

                print("Availability:", availability)

                DispatchQueue.main.async {
                    // store result
                    self.slotResponse = availability
                   
                 
                    self.filterForToday()
                    self.reloadSlots()

                }

            } catch {
                print("Availability Decode Error:", error)
            }

        }.resume()
    }
    func dateFromString(_ str: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: str)
    }
    func filterForToday() {

        guard let days = slotResponse?.days else { return }

        let today = Date()
        let calendar = Calendar.current

        displayDays = days.filter {
            guard let d = dateFromString($0.date) else { return false }
            return calendar.isDate(d, inSameDayAs: today)
        }
    }

    func filterForTomorrow() {

        guard let days = slotResponse?.days else { return }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        displayDays = days.filter {
            guard let d = dateFromString($0.date) else { return false }
            return Calendar.current.isDate(d, inSameDayAs: tomorrow)
        }
    }
    
    func reloadSlots() {

        guard let day = displayDays.first else { return }

        if let selected = selectedCourt,
           let section = day.sections.first(where: { $0.sectionId == selected.sectionId }) {

            allSlots = section.slots.map {
                var s = $0
                s.sectionId = section.sectionId
                return s
            }

        } else {
            allSlots = []
        }


        // Default show all
        displaySlots = allSlots
        scheduleCollectionView.reloadData()
    }


    
    @IBAction func backBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func todaysSheduleBtn(_ sender: Any) {
        filterForToday()
        reloadSlots()
    }

    
    
    @IBAction func tomorrowSchdeule(_ sender: Any) {
        
        filterForTomorrow()
        reloadSlots()
    }
    
    @IBAction func CustomDateSchedule(_ sender: Any) {

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        picker.maximumDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())

        let alert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n", preferredStyle: .alert)

        alert.view.addSubview(picker)

        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).isActive = true
        picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50).isActive = true

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.filterForCustom(date: picker.date)
            self.reloadSlots()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func filterForCustom(date: Date) {

        guard let days = slotResponse?.days else { return }

        displayDays = days.filter {
            guard let d = dateFromString($0.date) else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
    }
    
    @IBAction func amountInfo(_ sender: Any) {

        guard let preview = lastPreview else { return }

        let base = preview.appliedRules.baseRate.totalAmount
        let guest = preview.appliedRules.guestCharge?.totalAmount ?? 0
        let deposit = preview.appliedRules.deposit?.totalAmount ?? 0
        let total = preview.totalPayable

        let text =
        """
        Base Rate: ₹\(base)
        Guest Charge: ₹\(guest)
        Security Deposit: ₹\(deposit)

        Total Payable: ₹\(total)
        """

        let attributed = NSMutableAttributedString(string: text)

        let totalText = "Total Payable: ₹\(total)"

        if let range = text.range(of: totalText) {

            let nsRange = NSRange(range, in: text)

            attributed.addAttribute(.foregroundColor,
                                    value: UIColor.black,
                                    range: nsRange)

            attributed.addAttribute(.font,
                                    value: UIFont.boldSystemFont(ofSize: 18),
                                    range: nsRange)
        }

        let alert = UIAlertController(title: "Price Details",
                                      message: "",
                                      preferredStyle: .alert)

        // 🔥 Set attributed message
        alert.setValue(attributed, forKey: "attributedMessage")

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }


    
    
    @IBAction func proccedBtn(_ sender: Any) {
        callHoldAPI()
    }
    
    
    
    func callPricePreview() {

        guard
            !selectedSlots.isEmpty,
            let sectionId = selectedCourt?.sectionId,
            let day = displayDays.first,
            let amenityId = amenity?.amenityId
        else { return }

        let url = URL(string:
        MainApi.url("skroman/society/amenity/v1/api/amenities/\(amenityId)/booking/price-preview")
        )!


        let slots = selectedSlots.map {
            PreviewSlot(slotId: $0.slotId, from: $0.from, to: $0.to)
        }

        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""

        let body = PricePreviewRequest(
            userId: userId,
            date: day.date,
            sectionId: sectionId,
            guests: guestCount,
            slots: slots
        )

        print("PREVIEW BODY:", body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let http = response as? HTTPURLResponse {
                print("STATUS:", http.statusCode)
            }

            guard let data else { return }

            print(String(data: data, encoding: .utf8) ?? "")

            do {
                let result = try JSONDecoder().decode(PricePreviewResponse.self, from: data)

                DispatchQueue.main.async {

                    self.lastPreview = result

                    self.Finalpricelabel.text = "₹\(result.totalPayable)"
                    self.Finalpricelabel.textColor = .green
                    self.Finalpricelabel.font = UIFont.boldSystemFont(ofSize: 18)

                }


            } catch {
                print("Decode error:", error)
            }

        }.resume()
    }

    func callHoldAPI() {

        guard
            let preview = lastPreview,
            !selectedSlots.isEmpty,
            let sectionId = selectedCourt?.sectionId,
            let day = displayDays.first,
            let amenityId = amenity?.amenityId
        else { return }

        let url = URL(string:
            MainApi.url("skroman/society/amenity/v1/api/amenities/\(amenityId)/booking/hold")
        )!

        let slots = selectedSlots.map {
            PreviewSlot(slotId: $0.slotId, from: $0.from, to: $0.to)
        }

        let userId = KeychainWrapper.standard.string(forKey: "userId") ?? ""

        let pricePreview = PricePreviewHold(
            totalPayable: preview.totalPayable,
            appliedRules: AppliedRulesHold(
                baseRate: preview.appliedRules.baseRate,
                guestCharge: preview.appliedRules.guestCharge,
                deposit: preview.appliedRules.deposit
            )
        )

        let body = HoldBookingRequest(
            userId: userId,
            date: day.date,
            sectionId: sectionId,
            slots: slots,
            pricePreview: pricePreview
        )

        print("HOLD BODY:", body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in

            guard let data else { return }

            print(String(data: data, encoding: .utf8) ?? "")

            do {

                let holdResponse = try JSONDecoder().decode(HoldResponse.self, from: data)

                DispatchQueue.main.async {

                    if holdResponse.msg == "Slots held successfully",
                       let holdId = holdResponse.holdId {

                        self.callCreateOrderAPI(holdId: holdId)

                    } else {

                        self.showHoldError(msg: holdResponse.msg)
                    }

                }

            } catch {

                print("Hold decode error:", error)
            }

        }.resume()
    }

    
    func navigateToNextScreen(holdId: String, expiresAt: String) {

    }

    func showHoldError(msg: String) {

        let alert = UIAlertController(title: "Booking Failed",
                                      message: msg,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
    
    func callCreateOrderAPI(holdId: String) {

        let url = URL(string: MainApi.url("skroman/payment/create-order"))!

        let body = CreateOrderRequest(holdId: holdId)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data else { return }

            print("ORDER RAW:", String(data: data, encoding: .utf8) ?? "")

            do {

                let order = try JSONDecoder().decode(CreateOrderResponse.self, from: data)

                DispatchQueue.main.async {

                    if order.success == true {

                        print("✅ ORDER CREATED")
                        print("OrderId:", order.orderId ?? "")
                        print("Amount:", order.amount ?? 0)
                        print("Key:", order.key ?? "")
                        print("Transaction:", order.transactionId ?? "")
                       

                        
                        self.razorpayOrderId = order.orderId
                        self.razorpayKey = order.key
                        self.transactionId = order.transactionId
                        self.totalAmount = order.amount ?? 0
                        
                        print("RAW ORDER:", order)

                        print("orderId:", order.orderId ?? "nil")
                        print("key:", order.key ?? "nil")
                        print("amount:", order.amount ?? 0)

                        
                        self.startRazorpayPayment()

                    } else {

                        self.showHoldError(msg: order.msg ?? "Order failed")
                    }
                }

            } catch {

                print("Create order decode error:", error)
            }

        }.resume()
    }
    func startRazorpayPayment() {

        guard let orderId = razorpayOrderId,
              let key = razorpayKey else {
            print("❌ Razorpay params missing")
            return
        }


        razorpay = RazorpayCheckout.initWithKey(key, andDelegateWithData: self)

        let options: [String: Any] = [
            "order_id": orderId,
            "amount": totalAmount * 100,
            "currency": "INR",
            "name": "Skroman Amenity Booking",
            "description": "Court booking",
            "send_sms_hash": true,
            "retry": ["enabled": false],
            "prefill": [
                "contact": "9999999999",
                "email": "test@skroman.com"
            ]
        ]


        razorpay?.open(options, displayController: self)
    }
    
    
   


    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {

        print("✅ Payment ID:", payment_id)
        print("RAW Razorpay Response:", response ?? [:])

        let orderId = response?["razorpay_order_id"] as? String ?? razorpayOrderId
        let signature = response?["razorpay_signature"] as? String

        guard
            let finalOrderId = orderId,
            let finalSignature = signature
        else {
            print("❌ Missing orderId or signature")
            return
        }

        callVerifySignatureAPI(
            orderId: finalOrderId,
            paymentId: payment_id,
            signature: finalSignature
        )
    }


    func callVerifySignatureAPI(orderId: String,
                                paymentId: String,
                                signature: String) {

        let url = URL(string: MainApi.url("skroman/payment/verify-signature"))!

        let body = VerifySignatureRequest(
            razorpay_order_id: orderId,
            razorpay_payment_id: paymentId,
            razorpay_signature: signature
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data else { return }

            print("VERIFY RAW:", String(data: data, encoding: .utf8) ?? "")

            do {

                let verify = try JSONDecoder().decode(VerifySignatureResponse.self, from: data)

                DispatchQueue.main.async {

                    if verify.success == true {

                        print("🎉 Payment Verified Successfully")

                        self.callConfirmBookingAPI()
                        self.showProcessingPopup(message: "Verifying payment and confirming booking...")


                    } else {

                        self.hideProcessingPopup()
                        self.showHoldError(msg: verify.msg ?? "Verification failed")

                    }

                }

            } catch {
                print("Verify decode error:", error)
            }

        }.resume()
    }


    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        print("❌ Payment Failed:", str)

        let alert = UIAlertController(title: "Payment Failed",
                                      message: str,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
    }

    func onPaymentSuccess(_ payment_id: String) {
        print("Legacy success:", payment_id)
        
    }

    func callConfirmBookingAPI() {

        guard let amenityId = amenity?.amenityId,
              let transactionId = transactionId else {
            print("❌ Missing transactionId")
            return
        }

        let url = URL(string:
            MainApi.url("skroman/society/amenity/v1/api/amenities/\(amenityId)/booking/confirm")
        )!

        let body = [
            "transactionId": transactionId
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data else { return }

            print("CONFIRM RAW:", String(data: data, encoding: .utf8) ?? "")

            DispatchQueue.main.async {

                self.hideProcessingPopup()

                let alert = UIAlertController(
                    title: "Booking Confirmed ✅",
                    message: "Your court has been booked successfully.",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    
                   
                    if let vc = self.navigationController?.viewControllers.first(where: {
                        $0 is AmenityViewController
                    }) {
                        self.navigationController?.popToViewController(vc, animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                })

                self.present(alert, animated: true)
            }
        }.resume()
    }
    func showProcessingPopup(message: String = "Processing your payment...") {

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Please Wait"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        messageLabel.textColor = .darkGray

        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        overlay.addSubview(container)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.widthAnchor.constraint(equalToConstant: 260),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
        ])

        processingView = overlay
        view.isUserInteractionEnabled = false
    }
    func hideProcessingPopup() {
        processingView?.removeFromSuperview()
        processingView = nil
        view.isUserInteractionEnabled = true
    }

    
}

extension CourtBookingVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displaySlots.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SlotViewCell",
            for: indexPath
        ) as! SlotViewCell

        let slot = displaySlots[indexPath.item]

        let isSelected = selectedSlots.contains(where: {
            $0.from == slot.from && $0.to == slot.to
        })


        cell.configure(slot: slot, isSelected: isSelected)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: (collectionView.frame.width / 3) - 10, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let slot = displaySlots[indexPath.item]

        if let index = selectedSlots.firstIndex(where: {
            $0.from == slot.from && $0.to == slot.to
        }) {
            selectedSlots.remove(at: index)
        } else {
            selectedSlots.append(slot)
        }

        collectionView.reloadData()

        callPricePreview()
    }



}

extension Slot {
    var isAvailable: Bool {
        status == "AVAILABLE" && remainingCapacity > 0
    }
}
extension String {

    func to12HourFormat() -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"

        if let date = inputFormatter.date(from: self) {
            return outputFormatter.string(from: date)
        }

        return self
    }
}


struct SlotAvailabilityResponse: Decodable {
    let amenityId: String
    let amenityName: String
    let hasSections: Bool
    let days: [SlotDay]
}

struct SlotDay: Decodable {
    let date: String
    let weekday: String
    let sections: [SlotSection]
}
struct SlotSection: Decodable {
    let sectionId: String
    let sectionName: String
    let capacity: Int
    let slots: [Slot]
}

struct PricePreviewRequest: Encodable {
    let userId: String
    let date: String
    let sectionId: String
    let guests: Int
    let slots: [PreviewSlot]
}

struct PreviewSlot: Encodable {
    let slotId: String
    let from: String
    let to: String
}


struct Slot: Decodable {
    let slotId: String
    let from: String
    let to: String
    let totalCapacity: Int
    let bookedCount: Int
    let heldCount: Int
    let remainingCapacity: Int
    let status: String
    var sectionId: String?
}

struct PricePreviewResponse: Codable {
    let totalPayable: Int
    let approvalRequired: Bool
    let appliedRules: AppliedRules
}

struct AppliedRules: Codable {
    let baseRate: BaseRateRule
    let guestCharge: GuestChargeRule?
    let deposit: DepositRule?
}

struct BaseRateRule: Codable {
    let amountPerSlot: Int
    let totalAmount: Int
}

struct GuestChargeRule: Codable {
    let totalAmount: Int
}

struct DepositRule: Codable {
    let totalAmount: Int
}
struct HoldBookingRequest: Encodable {
    let userId: String
    let date: String
    let sectionId: String
    let slots: [PreviewSlot]
    let pricePreview: PricePreviewHold
}

struct PricePreviewHold: Encodable {
    let totalPayable: Int
    let appliedRules: AppliedRulesHold
}

struct AppliedRulesHold: Encodable {
    let baseRate: BaseRateRule
    let guestCharge: GuestChargeRule?
    let deposit: DepositRule?
}

struct HoldResponse: Codable {
    let msg: String
    let holdId: String?
    let expiresAt: String?
}

struct CreateOrderRequest: Encodable {
    let holdId: String
}

struct CreateOrderResponse: Decodable {
    let success: Bool
    let orderId: String?
    let amount: Int?
    let currency: String?
    let key: String?
    let transactionId: String?
    let msg: String?
}
struct VerifySignatureRequest: Encodable {
    let razorpay_order_id: String
    let razorpay_payment_id: String
    let razorpay_signature: String
}

struct VerifySignatureResponse: Decodable {
    let success: Bool
    let msg: String?
}
