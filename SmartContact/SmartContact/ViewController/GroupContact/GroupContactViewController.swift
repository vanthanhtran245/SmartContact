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
    @IBOutlet weak var lbNoData: UILabel!
    var groupName: [String] = []
    var contacts: [String : [Contact]] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        registerContactCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGroups { result in
            switch result {
            case .Success(response: let groups):
                self.groupsSuccess(groups: groups)
            case .Error(error: let error):
                print("Error \(error)")
            }
        }
        
        let alert = UIAlertController(style: .alert)
        alert.addContactsPicker { contact in Log(contact) }
        alert.addAction(title: "Cancel", style: .cancel)
        alert.show()
    }
    
    func groupsSuccess(groups: [CNGroup]) {
        groups.forEach { group in
            groupName.append(group.name)
            fetchContactsInGorup2(Group: group) { (result) in
                if case .Success(let contactsResult) = result {
                    var temps:[Contact] = []
                    contactsResult.forEach {
                        temps.append(Contact(contact: $0))
                    }
                    self.contacts.updateValue(temps, forKey: group.name)
                }
            }
            print("Items \(self.contacts)")
        }
    }
    
   
    
    private func registerContactCell() {
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: GlobalConstants.Strings.bundleIdentifier, withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                let cellNib = UINib(nibName: GlobalConstants.Strings.cellNibIdentifier, bundle: bundle)
                tableView.register(cellNib, forCellReuseIdentifier: "Cell")
            }
            else {
                assertionFailure("Could not load bundle")
            }
        } else {
            let cellNib = UINib(nibName: GlobalConstants.Strings.cellNibIdentifier, bundle: podBundle)
            tableView.register(cellNib, forCellReuseIdentifier: "Cell")
        }
    }
}

//extension GroupContactViewController: UITableViewDelegate, UITableViewDataSource {
//    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ContactCell
//        //Convert CNContact to Contact
//        let contact: Contact
//        if let searchText = searchBar.text, !searchText.isEmpty {
//            contact = Contact(contact: filteredContacts[(indexPath as NSIndexPath).row])
//        } else {
//            guard let contactsForSection = orderedContacts[sortedContactKeys[(indexPath as NSIndexPath).section]] else {
//                assertionFailure()
//                return UITableViewCell()
//            }
//            contact = Contact(contact: contactsForSection[(indexPath as NSIndexPath).row])
//        }
//        cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: .phoneNumber)
//        return cell
//    }
//}
