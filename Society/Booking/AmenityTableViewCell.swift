//
//  AmenityTableViewCell.swift
//  SkromanIsra
//
//  Created by Admin on 07/02/26.
//
import UIKit
class AmenityTableViewCell: UITableViewCell {

    @IBOutlet weak var ImageCollectionView: UICollectionView!
    @IBOutlet weak var amenityName: UILabel!
    @IBOutlet weak var amenityType: UILabel!
    @IBOutlet weak var aminetyPrice: UILabel!
    
    @IBOutlet weak var cellBackground: UIView!
    
    var onAmenityTapped: (() -> Void)?

    private var images: [String] = []
    var amenityData: Amenity?
    override func awakeFromNib() {
        super.awakeFromNib()

        ImageCollectionView.isUserInteractionEnabled = true
        ImageCollectionView.isPagingEnabled = true
        ImageCollectionView.showsVerticalScrollIndicator = false

        if let layout = ImageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            
        }

        let uinib = UINib(nibName: "amenityImgCollectionViewCell", bundle: nil)
        ImageCollectionView.register(uinib, forCellWithReuseIdentifier: "amenityImgCollectionViewCell")

        ImageCollectionView.dataSource = self
        ImageCollectionView.delegate = self
    }

    func configure(with amenity: Amenity) {

        amenityData = amenity   // store for tap

        amenityName.text = amenity.name.trimmingCharacters(in: .whitespaces)
        amenityType.text = amenity.description.trimmingCharacters(in: .whitespaces)
        aminetyPrice.text = amenity.isBookable ? "Bookable" : "Not Bookable"

        images = amenity.images
        ImageCollectionView.reloadData()
    }
}




extension AmenityTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count == 0 ? 1 : images.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "amenityImgCollectionViewCell",
            for: indexPath
        ) as! amenityImgCollectionViewCell

        cell.amenityImageView.image = UIImage(named: "picture")

        if images.count == 0 {
            return cell
        }
        
        let urlString = images[indexPath.item]

        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.amenityImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
        return cell
    }


    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(
            width: collectionView.frame.width,
            height: collectionView.frame.height
        )
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onAmenityTapped?()
    }
    
    
}
