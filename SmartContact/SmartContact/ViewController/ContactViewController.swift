//
//  ContactViewController.swift
//  SmartContact
//
//  Created by Sunflower on 8/31/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import UIKit
import Contacts

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


class ContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noContactsLabel: UILabel!
    // data
    var contactStore = CNContactStore()
    var contacts = [ContactEntry]()
    var rasterSize: CGFloat = 11.0
    var searchBar: SHSearchBar!
    var navigationSearchBar: SHSearchBar!
    var viewConstraints: [NSLayoutConstraint]?
    
    let addressFormatter: CNPostalAddressFormatter = {
        let formatter = CNPostalAddressFormatter()
        return formatter
    }()
}

extension ContactViewController: SHSearchBarDelegate {
    func prepareSearchBar() {
        let searchGlassIconTemplate = UIImage(named: "icon-search")!.withRenderingMode(.alwaysTemplate)
        
        view.backgroundColor = UIColor.white
        
        let leftView = imageViewWithIcon(searchGlassIconTemplate, rasterSize: rasterSize)
        searchBar = defaultSearchBar(withRasterSize: rasterSize, leftView: leftView, rightView: nil, delegate: self)
        view.addSubview(searchBar)
        
        
        setupLayoutConstraints()
        
        let allSearchBars: [SHSearchBar] = [searchBar]
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            let raster: CGFloat = 22.0
            self?.rasterSize = raster
            
            for bar in allSearchBars {
                var config = bar.config
                config.cancelButtonTextAttributes = [.foregroundColor : UIColor.red]
                config.rasterSize = raster
                bar.config = config
            }
            self?.setupLayoutConstraints()
        }
    }
    func setupLayoutConstraints() {
        let searchbarHeight: CGFloat = 46.0
        
        // Deactivate old constraints
        viewConstraints?.forEach { $0.isActive = false }
        
        let constraints = [
            searchBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 0),
            searchBar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -0),
            searchBar.heightAnchor.constraint(equalToConstant: searchbarHeight),
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        if viewConstraints != nil {
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        
        viewConstraints = constraints
    }
}

extension ContactViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareSearchBar()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.isHidden = true
       // searchBar.isHidden = true
        noContactsLabel.isHidden = false
        noContactsLabel.text = "Retrieving contacts..."
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestAccessToContacts { (success) in
            if success {
                self.retrieveContacts({ (success, contacts) in
                    DispatchQueue.main.async {
                      self.reloadContacts(isSuccess: success, contacts: contacts)
                    }
                })
            }
        }
    }
    
    func reloadContacts(isSuccess: Bool, contacts: [ContactEntry]?) {
        self.tableView.isHidden = !isSuccess
        self.noContactsLabel.isHidden = isSuccess
        if isSuccess && contacts?.count > 0 {
            self.contacts = contacts!
            self.tableView.reloadData()
        } else {
            self.noContactsLabel.text = "Unable to get contacts..."
        }
    }
}

extension ContactViewController {
    func requestAccessToContacts(_ completion: @escaping (_ success: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized: completion(true) // authorized previously
        case .denied, .notDetermined: // needs to ask for authorization
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (accessGranted, error) -> Void in
                completion(accessGranted)
            })
        default: // not authorized.
            completion(false)
        }
    }
    
    func retrieveContacts(_ completion: (_ success: Bool, _ contacts: [ContactEntry]?) -> Void) {
        var contacts = [ContactEntry]()
        do {
            let contactsFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactImageDataAvailableKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor])
            try contactStore.enumerateContacts(with: contactsFetchRequest, usingBlock: { (cnContact, error) in
                if let contact = ContactEntry(cnContact: cnContact) { contacts.append(contact) }
            })
            completion(true, contacts)
        } catch {
            completion(false, nil)
        }
    }
}

extension ContactViewController {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // UITableViewDataSource && Delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        cell.contact = contacts[indexPath.row]
        return cell
    }
}

// MARK: - Helper Functions

func defaultSearchBar(withRasterSize rasterSize: CGFloat, leftView: UIView?, rightView: UIView?, delegate: SHSearchBarDelegate, useCancelButton: Bool = true) -> SHSearchBar {
    var config = defaultSearchBarConfig(rasterSize)
    config.leftView = leftView
    config.rightView = rightView
    config.useCancelButton = useCancelButton
    
    if leftView != nil {
        config.leftViewMode = .always
    }
    
    if rightView != nil {
        config.rightViewMode = .unlessEditing
    }
    
    let bar = SHSearchBar(config: config)
    bar.delegate = delegate
    bar.placeholder = NSLocalizedString("sbe.textfieldPlaceholder.default", comment: "")
    bar.updateBackgroundImage(withRadius: 6, corners: [.allCorners], color: UIColor.white)
    bar.layer.shadowColor = UIColor.black.cgColor
    bar.layer.shadowOffset = CGSize(width: 0, height: 3)
    bar.layer.shadowRadius = 5
    bar.layer.shadowOpacity = 0.25
    return bar
}

func defaultSearchBarConfig(_ rasterSize: CGFloat) -> SHSearchBarConfig {
    var config: SHSearchBarConfig = SHSearchBarConfig()
    config.rasterSize = rasterSize
    //    config.cancelButtonTitle = NSLocalizedString("sbe.general.cancel", comment: "")
    config.cancelButtonTextAttributes = [.foregroundColor : UIColor.darkGray]
    config.textContentType = UITextContentType.fullStreetAddress.rawValue
    config.textAttributes = [.foregroundColor : UIColor.gray]
    return config
}

func imageViewWithIcon(_ icon: UIImage, rasterSize: CGFloat) -> UIImageView {
    let imgView = UIImageView(image: icon)
    imgView.frame = CGRect(x: 0, y: 0, width: icon.size.width + rasterSize * 2.0, height: icon.size.height)
    imgView.contentMode = .center
    imgView.tintColor = UIColor(red: 0.75, green: 0, blue: 0, alpha: 1)
    return imgView
}
