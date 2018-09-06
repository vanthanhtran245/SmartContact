//
//  FavoriteHelper.swift
//  SmartContact
//
//  Created by Sunflower on 9/4/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation

class FavoriteHelper {
    static let shared = FavoriteHelper()
    private init() {}
    public private(set) var favoriteContacts = [Favorite]()
    
    private func conditionPredicate(contactId: String) -> NSPredicate {
        return NSPredicate(format: "contactId == %@", contactId)
    }
    
    private var sortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(Favorite.contactId), ascending: true)]
    }
    func isFavorite(contactId: String?) -> Bool {
        guard let id = contactId else { return false }
        return (favoriteContacts.filter({$0.contactId == id}).first != nil) ? true : false
    }
    
    func fetchFavoriteContact() {
        favoriteContacts = ModelUtils.fetchObjects(entity: Favorite.self, context: ModelUtils.mainContext)
    }

    func updateFavorite(contact: Contact) {
        guard let contactId = contact.contactId else { return }
        //Check exist in database
        let result = ModelUtils.fetchObject(entity: Favorite.self, predicate: conditionPredicate(contactId: contactId), sortDescriptors: sortDescriptors, context: ModelUtils.mainContext)
        if let contactResult = result {
            ModelUtils.delete([contactResult], in: ModelUtils.mainContext)
        } else {
            //not exist -- create new
            let contactCreate = Favorite(context: ModelUtils.mainContext)
            contactCreate.birthday = contact.birthday
            contactCreate.contactId = contact.contactId
            contactCreate.company = contact.company
            contactCreate.firstName = contact.firstName
            contactCreate.lastName = contact.lastName
            contactCreate.cnContact = contact.contacts
        }
        ModelUtils.persist(synchronously: true)
        fetchFavoriteContact()
    }
}
