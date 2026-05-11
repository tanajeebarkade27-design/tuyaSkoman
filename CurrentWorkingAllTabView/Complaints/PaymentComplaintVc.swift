//
//  PaymentComplaintVc.swift
//  SkromanIsra
//
//  Created by Admin on 27/04/26.
//

import UIKit
import SwiftKeychainWrapper
import Razorpay

class PaymentComplaintVc: UIViewController, RazorpayPaymentCompletionProtocolWithData {
    
    var ticket: ComplaintTicket?
    
    private var isCouponApplied = false
    private var selectedCoupon: AvailableCoupon?
    
    private weak var bigPayableLabel: UILabel?
    private weak var amountLineLabel: UILabel?
    private weak var gstLineLabel: UILabel?
    private weak var bottomAmountLabel: UILabel?
    private weak var billingCouponValueLabel: UILabel?
    private weak var billingGstValueLabel: UILabel?
    private weak var billingTotalPayableValueLabel: UILabel?
    private weak var applyButtonRef: UIButton?
    
    private var validatedPricing: CouponPricing?
    
    private let razorPayKey = "rzp_test_3NBXqGqjXF1DCK"
    private var razorpay: RazorpayCheckout?
    private var razorpayOrderId: String?
    private var razorpayAmountPaise: Int?
    
    private lazy var inrFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()
    
    private func formatINR(_ value: Double) -> String {
        let number = NSNumber(value: value)
        let formatted = inrFormatter.string(from: number) ?? "\(value)"
        return "₹\(formatted)"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
  
}

private extension PaymentComplaintVc {
    func buildUI() {
        view.backgroundColor = .black
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        back.tintColor = .white
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        container.addSubview(back)
        
        let header = UILabel()
        header.text = "Payment"
        header.textColor = .white
        header.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        header.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(header)
        
        let payAmountTitle = UILabel()
        payAmountTitle.text = "Pay Amount"
        payAmountTitle.textColor = .systemYellow
        payAmountTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        payAmountTitle.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(payAmountTitle)
        
        let payable = ticket?.totalPayableAmount ?? ticket?.paybleAmount ?? 0
        let amount = ticket?.amount ?? 0
        let gstRate = ticket?.gstRate ?? 18
        selectedCoupon = ticket?.availableCoupons?.first
        
        let bigPayable = UILabel()
        bigPayable.text = formatINR(payable)
        bigPayable.textColor = .white
        bigPayable.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        bigPayable.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bigPayable)
        bigPayableLabel = bigPayable
        
        let amountLine = UILabel()
        amountLine.text = "Amount: \(formatINR(amount))"
        amountLine.textColor = .white
        amountLine.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        amountLine.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(amountLine)
        amountLineLabel = amountLine
        
        let gstLine = UILabel()
        gstLine.text = "GST: \(formatINR(ticket?.gstAmount ?? ((gstRate / 100.0) * amount))) (\(String(format: "%.0f", gstRate))%)"
        gstLine.textColor = .white
        gstLine.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        gstLine.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(gstLine)
        gstLineLabel = gstLine
        
        var couponCard: UIView?
        if let coupon = selectedCoupon {
            let card = buildCouponCard(coupon: coupon)
            couponCard = card
            container.addSubview(card)
        }
        
        let billingTitle = UILabel()
        billingTitle.text = "Billing Details"
        billingTitle.textColor = .white
        billingTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        billingTitle.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(billingTitle)
        
        let detailsBox = UIView()
        detailsBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(detailsBox)
        
        let totalRow = billingRow(title: "Total Amount", value: formatINR(amount))
        let couponRow = billingRow(title: "Coupon amount", value: "- \(formatINR(0))")
        let gstRow = billingRow(title: "GST(\(String(format: "%.0f", gstRate))%)", value: "+ \(formatINR(ticket?.gstAmount ?? ((gstRate / 100.0) * amount)))")
        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        let totalPayableRow = billingRow(title: "Total Payable", value: formatINR(payable), bold: true)
        
        billingCouponValueLabel = couponRow.valueLabel
        billingGstValueLabel = gstRow.valueLabel
        billingTotalPayableValueLabel = totalPayableRow.valueLabel
        
        let detailsStack = UIStackView(arrangedSubviews: [totalRow, couponRow, gstRow, divider, totalPayableRow])
        detailsStack.axis = .vertical
        detailsStack.spacing = 10
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        detailsBox.addSubview(detailsStack)
        
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bottomBar)
        
        let bottomAmount = UILabel()
        bottomAmount.text = formatINR(payable)
        bottomAmount.textColor = .white
        bottomAmount.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        bottomAmount.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(bottomAmount)
        bottomAmountLabel = bottomAmount
        
        let completeButton = UIButton(type: .system)
        completeButton.setTitle("Complete Payment", for: .normal)
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.backgroundColor = .systemGreen
        completeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        completeButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        completeButton.layer.cornerRadius = 23
        completeButton.clipsToBounds = true
        completeButton.addTarget(self, action: #selector(completePaymentTapped), for: .touchUpInside)
        bottomBar.addSubview(completeButton)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            back.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            back.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            back.widthAnchor.constraint(equalToConstant: 34),
            back.heightAnchor.constraint(equalToConstant: 34),
            
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            header.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 10),
            
            payAmountTitle.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 18),
            payAmountTitle.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            bigPayable.topAnchor.constraint(equalTo: payAmountTitle.bottomAnchor, constant: 8),
            bigPayable.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            amountLine.topAnchor.constraint(equalTo: bigPayable.bottomAnchor, constant: 10),
            amountLine.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            gstLine.topAnchor.constraint(equalTo: amountLine.bottomAnchor, constant: 6),
            gstLine.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        ])
        
        if let couponCard {
            NSLayoutConstraint.activate([
                couponCard.topAnchor.constraint(equalTo: gstLine.bottomAnchor, constant: 22),
                couponCard.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                couponCard.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
            
            NSLayoutConstraint.activate([
                billingTitle.topAnchor.constraint(equalTo: couponCard.bottomAnchor, constant: 26),
            ])
        } else {
            NSLayoutConstraint.activate([
                billingTitle.topAnchor.constraint(equalTo: gstLine.bottomAnchor, constant: 26),
            ])
        }
        
        NSLayoutConstraint.activate([
            billingTitle.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            detailsBox.topAnchor.constraint(equalTo: billingTitle.bottomAnchor, constant: 14),
            detailsBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            detailsBox.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            detailsStack.topAnchor.constraint(equalTo: detailsBox.topAnchor),
            detailsStack.leadingAnchor.constraint(equalTo: detailsBox.leadingAnchor),
            detailsStack.trailingAnchor.constraint(equalTo: detailsBox.trailingAnchor),
            detailsStack.bottomAnchor.constraint(equalTo: detailsBox.bottomAnchor),
            
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 64),
            bottomBar.topAnchor.constraint(greaterThanOrEqualTo: detailsBox.bottomAnchor, constant: 18),
            
            bottomAmount.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            bottomAmount.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            
            completeButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            completeButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 180),
        ])
        
        // Initial render (no coupon applied)
        renderAmounts()
    }
    
    func buildCouponCard(coupon: AvailableCoupon) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1.5
        card.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.8).cgColor
        card.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        
        let badge = UILabel()
        badge.text = "₹\(Int(coupon.discountValue ?? 0))\nOff"
        badge.textColor = .white
        badge.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        badge.numberOfLines = 2
        badge.textAlignment = .center
        badge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(badge)
        
        let title = UILabel()
        let code = coupon.code ?? ""
        let t = coupon.title ?? ""
        title.text = code.isEmpty ? t : "\(code)  \(t)"
        title.textColor = .white
        title.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)
        
        let valid = UILabel()
        let validTill = coupon.validTill?.prefix(10) ?? ""
        valid.text = validTill.isEmpty ? "" : "Valid till: \(validTill)"
        valid.textColor = UIColor.white.withAlphaComponent(0.7)
        valid.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        valid.translatesAutoresizingMaskIntoConstraints = false
        
        let textStack = UIStackView(arrangedSubviews: [title, valid])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.distribution = .fill
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textStack)
        
        let apply = UIButton(type: .system)
        apply.setTitle("Apply", for: .normal)
        apply.setTitleColor(.systemGreen, for: .normal)
        apply.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        apply.translatesAutoresizingMaskIntoConstraints = false
        apply.addTarget(self, action: #selector(applyCouponTapped), for: .touchUpInside)
        card.addSubview(apply)
        applyButtonRef = apply
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            
            badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            badge.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 56),
            badge.heightAnchor.constraint(equalToConstant: 56),
            
            textStack.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: apply.leadingAnchor, constant: -10),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -10),
            
            apply.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            apply.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        
        return card
    }
    
    final class BillingRowView: UIView {
        let valueLabel = UILabel()
    }
    
    func billingRow(title: String, value: String, bold: Bool = false) -> BillingRowView {
        let row = BillingRowView()
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let left = UILabel()
        left.text = title
        left.textColor = UIColor.white.withAlphaComponent(0.85)
        left.font = UIFont.systemFont(ofSize: 14, weight: bold ? .semibold : .regular)
        left.translatesAutoresizingMaskIntoConstraints = false
        
        let right = row.valueLabel
        right.text = value
        right.textColor = .white
        right.font = UIFont.systemFont(ofSize: 14, weight: bold ? .semibold : .regular)
        right.translatesAutoresizingMaskIntoConstraints = false
        right.textAlignment = .right
        
        row.addSubview(left)
        row.addSubview(right)
        
        NSLayoutConstraint.activate([
            left.topAnchor.constraint(equalTo: row.topAnchor),
            left.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            left.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            
            right.topAnchor.constraint(equalTo: row.topAnchor),
            right.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            right.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            right.leadingAnchor.constraint(greaterThanOrEqualTo: left.trailingAnchor, constant: 10)
        ])
        
        return row
    }
    
    func computeDiscount(amount: Double, coupon: AvailableCoupon) -> Double {
        let type = (coupon.discountType ?? "").uppercased()
        let value = coupon.discountValue ?? 0
        if type == "PERCENT" || type == "PERCENTAGE" {
            let raw = amount * (value / 100.0)
            if let maxCap = coupon.maxDiscountAmount {
                return max(0, min(raw, maxCap))
            }
            return max(0, raw)
        }
        // Default FLAT
        return max(0, min(value, amount))
    }
    
    func renderAmounts() {
        guard let ticket else { return }
        let amount = ticket.amount ?? 0
        let gstRate = ticket.gstRate ?? 18
        
        // If we have validated pricing from server, prefer it.
        if isCouponApplied, let pricing = validatedPricing {
            let discount = pricing.discountAmount
            let gst = pricing.gstAmount
            let total = pricing.finalAmount
            
            bigPayableLabel?.text = formatINR(total)
            amountLineLabel?.text = "Amount: \(formatINR(pricing.baseAmount))"
            gstLineLabel?.text = "GST: \(formatINR(gst)) (\(String(format: "%.0f", pricing.gstRate))%)"
            bottomAmountLabel?.text = formatINR(total)
            
            billingCouponValueLabel?.text = "- \(formatINR(discount))"
            billingGstValueLabel?.text = "+ \(formatINR(gst))"
            billingTotalPayableValueLabel?.text = formatINR(total)
        } else {
            let coupon = selectedCoupon
            let discount = (isCouponApplied && coupon != nil) ? computeDiscount(amount: amount, coupon: coupon!) : 0
            let discountedAmount = max(0, amount - discount)
            
            let gst: Double
            let total: Double
            if isCouponApplied {
                gst = (gstRate / 100.0) * discountedAmount
                total = discountedAmount + gst
            } else {
                gst = ticket.gstAmount ?? ((gstRate / 100.0) * amount)
                total = ticket.totalPayableAmount ?? ticket.paybleAmount ?? (amount + gst)
            }
            
            bigPayableLabel?.text = formatINR(total)
            amountLineLabel?.text = "Amount: \(formatINR(amount))"
            gstLineLabel?.text = "GST: \(formatINR(gst)) (\(String(format: "%.0f", gstRate))%)"
            bottomAmountLabel?.text = formatINR(total)
            
            billingCouponValueLabel?.text = "- \(formatINR(discount))"
            billingGstValueLabel?.text = "+ \(formatINR(gst))"
            billingTotalPayableValueLabel?.text = formatINR(total)
        }
        
        if isCouponApplied {
            applyButtonRef?.setTitle("Applied", for: .normal)
            applyButtonRef?.setTitleColor(.gray, for: .normal)
            applyButtonRef?.isEnabled = false
        }
    }
    
    @objc func applyCouponTapped() {
        guard let ticket else { return }
        guard let couponCode = selectedCoupon?.code, !couponCode.isEmpty else { return }
        
        let userId = ticket.userId ?? (KeychainWrapper.standard.string(forKey: "userId") ?? "")
        let ticketId = ticket.ticketId ?? ""
        let amount = ticket.amount ?? 0
        
        validateCoupon(
            couponCode: couponCode,
            ticketId: ticketId,
            userId: userId,
            amount: amount
        )
    }
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

private extension PaymentComplaintVc {
    func validateCoupon(couponCode: String, ticketId: String, userId: String, amount: Double) {
        guard let url = URL(string: MainApi.url("skroman/payment/complaint-ticket/coupons/validate")) else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "couponCode": couponCode,
            "ticketId": ticketId,
            "userId": userId,
            "amount": Int((amount).rounded())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("❌ JSON encode error:", error)
            return
        }
        
        print("📡 Validate coupon request:", body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                print("❌ Validate coupon API error:", error.localizedDescription)
                return
            }
            
            if let http = response as? HTTPURLResponse {
                print("✅ Validate coupon status:", http.statusCode)
            }
            
            guard let data else {
                print("❌ No response data")
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("🧾 Validate coupon response:\n\(raw)")
            } else {
                print("🧾 Validate coupon response (non-utf8, \(data.count) bytes)")
            }
            guard let self else { return }
            
            // Decode response to compare & render server pricing
            if let decoded = try? JSONDecoder().decode(CouponValidateResponse.self, from: data),
               decoded.success == true,
               let pricing = decoded.pricing {
                
                // Compare with local expectations (tolerance 0.01)
                let tolerance = 0.011
                let localDiscount = (self.selectedCoupon != nil) ? self.computeDiscount(amount: amount, coupon: self.selectedCoupon!) : 0
                let localBaseAfter = max(0, amount - localDiscount)
                let localGst = (pricing.gstRate / 100.0) * localBaseAfter
                let localFinal = localBaseAfter + localGst
                
                let ok =
                    abs(pricing.discountAmount - localDiscount) <= tolerance &&
                    abs(pricing.gstAmount - localGst) <= tolerance &&
                    abs(pricing.finalAmount - localFinal) <= tolerance
                
                print("🔎 Coupon pricing compare ok:", ok)
                if !ok {
                    print("🔎 Local expected:",
                          ["discount": localDiscount, "gst": localGst, "final": localFinal])
                    print("🔎 Server pricing:",
                          ["discount": pricing.discountAmount, "gst": pricing.gstAmount, "final": pricing.finalAmount])
                }
                
                DispatchQueue.main.async {
                    self.validatedPricing = pricing
                    self.isCouponApplied = true
                    self.renderAmounts()
                }
                
            } else {
                print("❌ Could not decode validate coupon response")
            }
            
        }.resume()
    }
}

private struct CouponValidateResponse: Decodable {
    let success: Bool?
    let pricing: CouponPricing?
}

private struct CouponPricing: Decodable {
    let baseAmount: Double
    let discountAmount: Double
    let gstRate: Double
    let gstAmount: Double
    let amountAfterDiscount: Double
    let finalAmount: Double
}

// MARK: - Razorpay callbacks
extension PaymentComplaintVc {
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        print("✅ Razorpay Payment Success: \(payment_id)")
        print("✅ Razorpay Response Data: \(String(describing: response))")
        
        guard let ticket else {
            print("❌ Missing ticket for verify call")
            return
        }
        
        let userId = ticket.userId ?? (KeychainWrapper.standard.string(forKey: "userId") ?? "")
        let ticketId = ticket.ticketId ?? ""
        
        let razorpayOrderId =
            (response?["razorpay_order_id"] as? String) ??
            razorpayOrderId ??
            ""
        
        let razorpaySignature = (response?["razorpay_signature"] as? String) ?? ""
        
        if razorpayOrderId.isEmpty || razorpaySignature.isEmpty {
            print("❌ Missing razorpay_order_id / razorpay_signature in success response")
            return
        }
        
        verifyPayment(
            ticketId: ticketId,
            userId: userId,
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: payment_id,
            razorpaySignature: razorpaySignature
        )
    }
    
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        print("❌ Razorpay Payment Error - Code: \(code), Description: \(str)")
        print("❌ Razorpay Error Data: \(String(describing: response))")
        
        let messageFromSDK =
            (response?["error"] as? [AnyHashable: Any])?["description"] as? String
        
        let msg = messageFromSDK ?? str
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Payment Failed", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Create order + open Razorpay
private extension PaymentComplaintVc {
    struct CreateOrderResponse: Decodable {
        let success: Bool?
        let transactionId: String?
        let orderId: String?
        let amount: Double?
        let currency: String?
        let key: String?
    }
    
    @objc func completePaymentTapped() {
        guard let ticket else { return }
        
        let userId = ticket.userId ?? (KeychainWrapper.standard.string(forKey: "userId") ?? "")
        let ticketId = ticket.ticketId ?? ""
        
        // Use server validated final amount if available
        let amountToPay: Double = {
            if isCouponApplied, let pricing = validatedPricing {
                return pricing.finalAmount
            }
            let amount = ticket.amount ?? 0
            let gstRate = ticket.gstRate ?? 18
            let gst = ticket.gstAmount ?? ((gstRate / 100.0) * amount)
            return ticket.totalPayableAmount ?? ticket.paybleAmount ?? (amount + gst)
        }()
        
        let idempotencyKey = UUID().uuidString
        let couponCode = isCouponApplied ? (selectedCoupon?.code ?? "") : ""
        
        createOrder(
            ticketId: ticketId,
            userId: userId,
            amount: amountToPay,
            idempotencyKey: idempotencyKey,
            couponCode: couponCode.isEmpty ? nil : couponCode
        )
    }
    
    func createOrder(ticketId: String, userId: String, amount: Double, idempotencyKey: String, couponCode: String?) {
        guard let url = URL(string: MainApi.url("skroman/payment/complaint-ticket/create-order")) else {
            print("❌ Invalid create-order URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "ticketId": ticketId,
            "userId": userId,
            "amount": amount,
            "idempotencyKey": idempotencyKey
        ]
        if let couponCode, !couponCode.isEmpty {
            body["couponCode"] = couponCode
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("❌ create-order JSON encode error:", error)
            return
        }
        
        print("📡 create-order request:", body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                print("❌ create-order API error:", error.localizedDescription)
                return
            }
            
            if let http = response as? HTTPURLResponse {
                print("✅ create-order status:", http.statusCode)
            }
            
            guard let data else {
                print("❌ create-order no response data")
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("🧾 create-order response:\n\(raw)")
            }
            
            guard let self else { return }
            
            if let decoded = try? JSONDecoder().decode(CreateOrderResponse.self, from: data),
               decoded.success == true,
               let orderId = decoded.orderId {
                
                self.razorpayOrderId = orderId
                // Razorpay amount must be in paise
                let respAmount = decoded.amount ?? amount
                self.razorpayAmountPaise = Int((respAmount * 100).rounded())
                
                DispatchQueue.main.async {
                    self.openRazorpayCheckout(
                        key: decoded.key ?? self.razorPayKey,
                        orderId: orderId,
                        amountPaise: self.razorpayAmountPaise ?? Int((amount * 100).rounded()),
                        currency: decoded.currency ?? "INR"
                    )
                }
            } else {
                print("❌ Could not decode create-order response (or success=false)")
            }
        }.resume()
    }
    
    func openRazorpayCheckout(key: String, orderId: String, amountPaise: Int, currency: String) {
        print("🚀 Opening Razorpay checkout:", ["orderId": orderId, "amountPaise": amountPaise, "currency": currency, "key": key])
        razorpay = RazorpayCheckout.initWithKey(key, andDelegateWithData: self)
        
        let options: [String: Any] = [
            "key": key,
            "amount": amountPaise,
            "currency": currency,
            "name": "Skroman Switches Private Limited",
            "description": "Complaint Payment",
            "order_id": orderId,
            "prefill": [
                "contact": "",
                "email": ""
            ],
            "theme": [
                "color": "#35C759"
            ]
        ]
        
        guard let razorpay else {
            print("❌ Razorpay not initialized")
            let alert = UIAlertController(title: "Payment Error", message: "Razorpay is not initialized.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        razorpay.open(options)
    }
    
    func verifyPayment(
        ticketId: String,
        userId: String,
        razorpayOrderId: String,
        razorpayPaymentId: String,
        razorpaySignature: String
    ) {
        guard let url = URL(string: MainApi.url("skroman/payment/complaint-ticket/verify")) else {
            print("❌ Invalid verify URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "ticketId": ticketId,
            "userId": userId,
            "razorpay_order_id": razorpayOrderId,
            "razorpay_payment_id": razorpayPaymentId,
            "razorpay_signature": razorpaySignature
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("❌ verify JSON encode error:", error)
            return
        }
        
        print("📡 verify request:", body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("❌ verify API error:", error.localizedDescription)
                return
            }
            
            if let http = response as? HTTPURLResponse {
                print("✅ verify status:", http.statusCode)
            }
            
            guard let data else {
                print("❌ verify no response data")
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("🧾 verify response:\n\(raw)")
            } else {
                print("🧾 verify response (non-utf8, \(data.count) bytes)")
            }
            
            // Show success popup and navigate to complaint list
            if
                let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let success = decoded["success"] as? Bool,
                success == true
            {
                let msg = (decoded["msg"] as? String) ?? "Payment completed successfully."
                DispatchQueue.main.async {
                    self.showPaymentSuccessPopup(message: msg)
                }
            }
        }.resume()
    }
    
    func showPaymentSuccessPopup(message: String) {
        let alert = UIAlertController(title: "Payment Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigateToMainHome()
        })
        present(alert, animated: true)
    }
    
    private func navigateToMainHome() {
        if let navController = self.navigationController {
            // Prefer returning to an existing Home screen in stack.
            if let homeVC = navController.viewControllers.first(where: { $0 is MainHomeViewController }) {
                navController.popToViewController(homeVC, animated: true)
                return
            }
            
            // If Home is not in stack, create and push it.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let homeVC = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController {
                navController.pushViewController(homeVC, animated: true)
                return
            }
            
            navController.popToRootViewController(animated: true)
            return
        }
        
        // Modal fallback
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let homeVC = storyboard.instantiateViewController(withIdentifier: "MainHomeViewController") as? MainHomeViewController {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
}
