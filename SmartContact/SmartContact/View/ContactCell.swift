//
//  ContactCell.swift
//  SmartContact
//
//  Created by Sunflower on 8/31/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import AddressBook
import Contacts
import UIKit

class ContactCell: UITableViewCell {
    // outlets
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactEmailLabel: UILabel!
    @IBOutlet weak var contactPhoneLabel: UILabel!
    
    var contact: ContactEntry? {
        didSet {
            guard let contact = contact else { return  }
            configureWithContactEntry(contact)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setCircularAvatar() {
        contactImageView.layer.cornerRadius = contactImageView.bounds.size.width / 2.0
        contactImageView.layer.masksToBounds = true
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        setCircularAvatar()
    }
    
    func configureWithContactEntry(_ contact: ContactEntry) {
        contactNameLabel.text = contact.name
        contactEmailLabel.text = contact.email ?? ""
        contactPhoneLabel.text = contact.phone ?? ""
        contactImageView.image = contact.image ?? UIImage(named: "defaultUser")
        setCircularAvatar()
        layoutIfNeeded()
    }
}
