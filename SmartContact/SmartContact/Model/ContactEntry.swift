//
//  ContactEntry.swift
//  SmartContact
//
//  Created by Sunflower on 8/31/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import UIKit
import AddressBook
import Contacts

class ContactEntry: NSObject {
    var name: String!
    var email: String?
    var phone: String?
    var image: UIImage?
    
    init(name: String, email: String?, phone: String?, image: UIImage?) {
        self.name = name
        self.email = email
        self.phone = phone
        self.image = image
    }
    
    init?(cnContact: CNContact) {
        // name
        if !cnContact.isKeyAvailable(CNContactGivenNameKey) && !cnContact.isKeyAvailable(CNContactFamilyNameKey) { return nil }
        self.name = (cnContact.givenName + " " + cnContact.familyName).trimmingCharacters(in: CharacterSet.whitespaces)
        // image
        self.image = (cnContact.isKeyAvailable(CNContactImageDataKey) && cnContact.imageDataAvailable) ? UIImage(data: cnContact.imageData!) : nil
        // email
        if cnContact.isKeyAvailable(CNContactEmailAddressesKey) {
            for possibleEmail in cnContact.emailAddresses {
                let properEmail = possibleEmail.value as String
                if properEmail.isEmail { self.email = properEmail; break }
            }
        }
        // phone
        if cnContact.isKeyAvailable(CNContactPhoneNumbersKey) {
            if cnContact.phoneNumbers.count > 0 {
                let phone = cnContact.phoneNumbers.first?.value
                self.phone = phone?.stringValue
            }
        }
    }
}
