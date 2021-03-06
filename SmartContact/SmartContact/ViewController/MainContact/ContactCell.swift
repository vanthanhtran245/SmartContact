//
//  ContactCell.swift
//  JFContactsPicker
//

import UIKit
import SwipeCellKit

class ContactCell: SwipeTableViewCell {

    @IBOutlet weak var contactTextLabel: UILabel!
    @IBOutlet weak var contactDetailTextLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitialLabel: UILabel!
    @IBOutlet weak var contactContainerView: UIView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    var contact: Contact?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contactContainerView.layer.masksToBounds = true
        contactContainerView.layer.cornerRadius = contactContainerView.frame.size.width/2
    }
    
    func updateInitialsColorForIndexPath(_ indexpath: IndexPath) {
        //Applies color to Initial Label
        let colorArray = GlobalConstants.Colors.all
        let randomValue = (indexpath.row + indexpath.section) % colorArray.count
        contactInitialLabel.backgroundColor = colorArray[randomValue]
    }
 
    func updateContactsinUI(_ contact: Contact, indexPath: IndexPath, subtitleType: SubtitleCellValue) {
        self.contact = contact
        //Update all UI in the cell here
        self.contactTextLabel?.text = UserDefaults.showFirstNameBeforeLast ? contact.displayNameWithLastNameFirst : contact.displayName
        updateSubtitleBasedonType(subtitleType, contact: contact)
        if contact.thumbnailProfileImage != nil {
            self.contactImageView?.image = contact.thumbnailProfileImage
            self.contactImageView.isHidden = false
            self.contactInitialLabel.isHidden = true
        } else {
            self.contactInitialLabel.text = contact.initials
            updateInitialsColorForIndexPath(indexPath)
            self.contactImageView.isHidden = true
            self.contactInitialLabel.isHidden = false
        }
        refreshFavorite(contact: contact)
    }
    
    func refreshFavorite(contact: Contact) {
        let isFavorite = FavoriteHelper.shared.isFavorite(contactId: contact.contactId)
        let image = isFavorite ? UIImage(named: "star") : UIImage(named: "unstar")
        favoriteButton.setImage(image, for: .normal)
    }
    
    @IBAction func doUpdateFavorite(_ sender: Any) {
    }
    
    func updateSubtitleBasedonType(_ subtitleType: SubtitleCellValue , contact: Contact) {
        switch subtitleType {
        case .phoneNumber:
            let phoneNumberCount = contact.phoneNumbers.count
            if phoneNumberCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneNumber)"
            }
            else if phoneNumberCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.phoneNumbers[0].phoneNumber) and \(contact.phoneNumbers.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = GlobalConstants.Strings.phoneNumberNotAvaialable
            }
        case .email:
            let emailCount = contact.emails.count
            if emailCount == 1  {
                self.contactDetailTextLabel.text = "\(contact.emails[0].email)"
            }
            else if emailCount > 1 {
                self.contactDetailTextLabel.text = "\(contact.emails[0].email) and \(contact.emails.count-1) more"
            }
            else {
                self.contactDetailTextLabel.text = GlobalConstants.Strings.emailNotAvaialable
            }
        case .birthday:
            self.contactDetailTextLabel.text = contact.birthdayString
        case .organization:
            self.contactDetailTextLabel.text = contact.company
        }
    }
}
