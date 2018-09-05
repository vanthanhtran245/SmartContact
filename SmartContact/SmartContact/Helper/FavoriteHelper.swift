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
    private let context = ModelUtils.mainContext
    
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
        favoriteContacts = ModelUtils.fetchObjects(entity: Favorite.self, context: context)
    }

    func updateFavorite(contact: Contact) {
        guard let contactId = contact.contactId else { return }
        //Check exist in database
        let result = ModelUtils.fetchObject(entity: Favorite.self, predicate: conditionPredicate(contactId: contactId), sortDescriptors: sortDescriptors, context: context)
        if let contactResult = result {
            ModelUtils.delete([contactResult], in: context)
            fetchFavoriteContact()
        } else {
            //not exist -- create new
            let contactCreate = Favorite(context: context)
            contactCreate.birthday = contact.birthday
            contactCreate.contactId = contact.contactId
            contactCreate.company = contact.company
            contactCreate.firstName = contact.firstName
            contactCreate.lastName = contact.lastName
            ModelUtils.persist(synchronously: false)
            fetchFavoriteContact()
        }
    }
}
