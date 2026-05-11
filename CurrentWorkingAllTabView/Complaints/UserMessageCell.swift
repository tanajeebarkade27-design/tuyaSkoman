

import UIKit

class UserMessageCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        bubbleView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
        bubbleView.layer.cornerRadius = 18
        
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 10
        
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        imageHeightConstraint.constant = 0
        profileImageView.isHidden = true
    }
    
    func configure(message: String?, imageURL: URL?) {
        messageLabel.text = message
        
        if let imageURL {
            profileImageView.isHidden = false
            imageHeightConstraint.constant = 50
            profileImageView.load(url: imageURL)
        } else {
            profileImageView.isHidden = true
            imageHeightConstraint.constant = 0
            profileImageView.image = nil
        }
    }
}
