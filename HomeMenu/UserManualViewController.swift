//
//  UserManualViewController.swift
//  SkromanIsra
//
//  Created by Admin on 01/08/25.
//

import UIKit
import WebKit

class UserManualViewController: UIViewController {

    @IBOutlet weak var userManualView: UIView!

    private var webView: WKWebView!
    private var activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebView()
        openUserManual()
    }

    func setupWebView() {

        webView = WKWebView(frame: userManualView.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        userManualView.addSubview(webView)

        activityIndicator.center = userManualView.center
        activityIndicator.hidesWhenStopped = true
        userManualView.addSubview(activityIndicator)
    }

    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    private func openUserManual() {

        let urlString = "https://drive.google.com/file/d/1fVGtkH5nuaEatq1ATj--gRWtiqdJdWRI/view?usp=sharing"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }

        activityIndicator.startAnimating()

        let request = URLRequest(url: url)
        webView.load(request)
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
