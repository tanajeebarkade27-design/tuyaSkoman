//
//  SevicesViewController.swift
//  SkromanIsra
//
//  Created by Admin on 13/11/25.
//

import UIKit

class SevicesViewController: UIViewController {
    
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    
    
      
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
       
    }
    
    
    
}
