//
//  GroupContactViewController.swift
//  SmartContact
//
//  Created by Sunflower on 9/4/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import UIKit
import SwiftyContacts
import Contacts

class GroupContactViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var groupName: [String] = []
    var contacts: [String : [Contact]] = [:]
    var groups: [CNGroup] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        registerContactCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        groupName.removeAll()
        contacts.removeAll()
        let groups = ModelUtils.fetchObjects(entity: Group.self, context: ModelUtils.mainContext)
        groupName = groups.map({ $0.groupName! })
        groups.forEach { items in
            guard let contacts = items.cnContact as? [CNContact] else { return }
            let result = contacts.compactMap({
                return Contact(contact: $0)
            })
            self.contacts.updateValue(result, forKey: items.groupName!)
        }
        disPlayEmptyView(isShow: groupName.count == 0)
        tableView.reloadData()
    }
    
    private func registerContactCell() {
        let cellNib = UINib(nibName: GlobalConstants.Strings.cellNibIdentifier, bundle: .main)
        tableView.register(cellNib, forCellReuseIdentifier: "Cell")
        let noContactIdentifier = String(describing: NoContactCell.self)
        let noContactCell = UINib(nibName: noContactIdentifier, bundle: .main)
        tableView.register(noContactCell, forCellReuseIdentifier: noContactIdentifier)
        let identifier = String(describing: GroupHeaderView.self)
        tableView.register(UINib(nibName: identifier, bundle: .main), forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    @IBAction func addNewGroup(_ sender: Any) {
        let alert = UIAlertController(title: "OK", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let action = UIAlertAction(title: "OK", style: .default, handler: { action in
            guard let groupName = alert.textFields?.first?.text?.trimmed else { return }
            let isExist = GroupHelper.shared.isExistGroup(groupName: groupName)
            
        })
        alert.addAction(action)
        alert.addTextField { tf in
            tf.placeholder = "Group name"
        }
        present(alert, animated: true, completion: nil)
    }
}

extension GroupContactViewController: UITableViewDelegate, UITableViewDataSource {
    open func numberOfSections(in tableView: UITableView) -> Int {
        return groupName.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contactsForSection = contacts[groupName[section]] {
            return contactsForSection.count == 0 ? 1 : contactsForSection.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 58
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: GroupHeaderView.self)) as! GroupHeaderView
        let name = groupName[section]
        header.title = groupName[section]
        header.section = section
        header.buttonTappedAction = { index in
            let alert = UIAlertController(style: .alert)
            alert.addContactsPicker { contacts in
                let contactFromModel = Set(contacts.map({ $0.value }))
                guard let contactInSections = self.contacts[name] else {
                    return
                }
                let currentContact = contactInSections.map({ $0.contacts?.copy() as! CNContact })
                let receivedContacts = contactFromModel.symmetricDifference(currentContact)
                let allContacts = receivedContacts.compactMap({
                    return Contact(contact: $0)
                })
                let allValues = contactInSections + allContacts
                self.addContactToGroups(group: self.groups[section], contacts: allContacts, {
                    self.contacts.updateValue(allValues, forKey: name)
                    let indexSet = IndexSet.init(integer: section)
                    self.tableView.reloadSections(indexSet, with: .fade)
                    self.disPlayEmptyView(isShow: self.contacts.keys.count == 0)
                })
            }
            alert.addAction(title: "Cancel", style: .cancel)
            alert.show()
            Log(index)
        }
        let view = UIView(frame: header.frame)
        view.backgroundColor = UIColor(hexString: "0xE5E5E5", alpha: 1)
        header.backgroundView = view
        return header
    }
   
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let contactInSection = contacts[groupName[indexPath.section]], contactInSection.count > 0 {
            let contact = contactInSection[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ContactCell
            cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: .phoneNumber)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NoContactCell.self), for: indexPath) as! NoContactCell
            cell.selectionStyle = .none
            return cell
        }
    }
}

extension GroupContactViewController {
    func addContactToGroups(group: CNGroup, contacts: [Contact], _ completed: @escaping(() -> ())) {
        contacts.enumerated().forEach { index, item in
            addContactToGroup(Group: group, Contact: item.contacts!, completionHandler: { result in
                Log(result)
                guard index == contacts.count - 1 else { return }
                completed()
            })
        }
    }
}
