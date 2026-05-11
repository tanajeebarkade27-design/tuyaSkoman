//
//  AboutUsViewController.swift
//  SkromanIsra
//
//  Created by Admin on 31/10/25.
//

import UIKit

class AboutUsViewController: UIViewController {
    
    
    @IBOutlet weak var aboutusView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        aboutusView.cornerRadius =  10
        aboutusView.clipsToBounds =  true
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
   

    @IBAction func backbutton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    

}
