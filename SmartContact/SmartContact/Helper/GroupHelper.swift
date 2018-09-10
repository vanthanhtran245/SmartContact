//
//  GroupHelper.swift
//  SmartContact
//
//  Created by Sunflower on 9/8/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import CoreData
import Contacts

class GroupHelper {
    static let shared = GroupHelper()
    private init() {}
    public private(set) var groupsContact = [Group]()
    
    private func conditionPredicate(groupName: String) -> NSPredicate {
        return NSPredicate(format: "groupName == %@", groupName)
    }
    
    private var sortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: #keyPath(Group.groupName), ascending: true)]
    }
    
    func isExistGroup(groupName: String) -> Bool {
        return (groupsContact.filter({groupName == $0.groupName}).first != nil) ? true : false
    }
    
    func isContanstContactInGroup(groupName: String, contact: CNContact) -> Bool {
        guard let groupContact = groupsContact.filter({groupName == $0.groupName}).first,
            let cnContacts = groupContact.cnContact as? [CNContact] else { return false }
        return cnContacts.contains(where: {$0.identifier == contact.identifier })
    }
    
    func fetchedGroupsContact() {
        groupsContact = ModelUtils.fetchObjects(entity: Group.self, context: ModelUtils.mainContext)
    }
    
    func addOrRemoveContactInGroup(contacts: [CNContact], group: Group) {
        contacts.forEach {
            if isContanstContactInGroup(groupName: group.groupName!, contact: $0) {
                //Remove
            } else {
                group.cnContact?.adding($0)
                createOrUpdateGroup(group: group)
            }
        }
    }
    
    func createOrUpdateGroup(group: Group) {
        let result = ModelUtils.fetchObject(entity: Group.self, predicate: conditionPredicate(groupName: group.groupName!), sortDescriptors: sortDescriptors, context: ModelUtils.mainContext)
        if let groupInDB = result {
            groupInDB.cnContact = group.cnContact
        } else {
            let newGroup = Group(context: ModelUtils.mainContext)
            newGroup.groupName = group.groupName
            newGroup.cnContact = group.cnContact
        }
        ModelUtils.persist(synchronously: true)
        fetchedGroupsContact()
    }
}
