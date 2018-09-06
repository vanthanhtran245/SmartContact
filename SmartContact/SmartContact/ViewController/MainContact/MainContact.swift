//
//  MainContact.swift
//  JFMainContact
//

import UIKit
import Contacts
import SwipeCellKit
import SwiftyContacts
import Messages
import MessageUI

typealias ContactsHandler = (_ contacts : [CNContact] , _ error : NSError?) -> Void
typealias SelectPhoneNumberCallBack = (_ phonenumber : String?, _ selectIndex: Int?) -> Void

public enum SubtitleCellValue{
    case phoneNumber
    case email
    case birthday
    case organization
}

class MainContact: BaseViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    // MARK: - Properties
    @IBOutlet weak var syncContactButton: UIBarButtonItem!
    @IBOutlet weak var addNewContact: UIBarButtonItem!
    public private(set) lazy var contactsStore: CNContactStore = { return CNContactStore() }()
    
    /// Contacts ordered in dictionary alphabetically using `sortOrder`.
    private var orderedContacts = [String: [CNContact]]()
    private var sortedContactKeys = [String]()
    
    public private(set) var selectedContacts = [Contact]()
    private var filteredContacts = [CNContact]()
    
    /// If `true`, the picker will allow multiple contacts to be selected.
    /// Defaults to `false` for single contact selection.
    public let multiSelectEnabled: Bool
    
    /// Indicates if the index bar should be shown. Defaults to `true`.
    public var shouldShowIndexBar: Bool
    
    /// The contact value type to display in the cells' subtitle labels.
    public var subtitleCellValue: SubtitleCellValue = .phoneNumber
    
    /// The order that the contacts should be sorted.
    public var sortOrder: CNContactSortOrder = CNContactSortOrder.userDefault {
        didSet {
            if viewIfLoaded != nil {
                self.reloadContacts()
            }
        }
    }
    
    //Enables custom filtering of contacts.
    public var shouldIncludeContact: ((CNContact) -> Bool)? {
        didSet {
            if viewIfLoaded != nil {
                self.reloadContacts()
            }
        }
    }
    
    public lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: CGRect.zero)
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        return searchBar
    }()
    
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    
    @IBAction func syncContact(_ sender: Any) {
        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.navigationItem.leftBarButtonItem?.customView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 2))
        }, completion: nil)
    }
    
    @IBAction func addNewContact(_ sender: Any) {
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.multiSelectEnabled = false
        self.shouldShowIndexBar = true
        super.init(coder: aDecoder)
    }
    
    // MARK: - Lifecycle Methods
    
    open override func loadView() {
        self.view = tableView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = GlobalConstants.Strings.contactsTitle
        registerContactCell()
        setUpSearchBar()
        reloadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subtitleCellValue = UserDefaults.subtitleWithEmail ? .email : .phoneNumber
        tableView.reloadData()
    }
    
    func setUpSearchBar() {
        searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchBar
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
    
    // MARK: - Contact Operations
    
    open func reloadContacts() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.getContacts { [weak self] (contacts, error) in
                if (error == nil) {
                    DispatchQueue.main.async { [weak self] in
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }

    
    private func getContacts(_ completion:  @escaping ContactsHandler) {
        // TODO: Set up error domain
        let error = NSError(domain: "JFContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Contacts Access"])
        
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            //User has denied the current app to access the contacts.
            
            let productName = Bundle.main.infoDictionary!["CFBundleName"]!
            
            let alert = UIAlertController(title: "Unable to access contacts", message: "\(productName) does not have access to contacts. Kindly enable it in privacy settings ", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {  action in
                completion([], error)
                self.dismiss(animated: true, completion: nil)
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
        case CNAuthorizationStatus.notDetermined:
            //This case means the user is prompted for the first time for allowing contacts
            contactsStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (granted, error) -> Void in
                //At this point an alert is provided to the user to provide access to contacts. This will get invoked if a user responds to the alert
                if  (!granted ){
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion([], error! as NSError?)
                    })
                }
                else{
                    self.getContacts(completion)
                }
            })
            
        case  CNAuthorizationStatus.authorized:
            //Authorization granted by user for this app.
            var contactsArray = [CNContact]()
            
            var orderedContacts = [String : [CNContact]]()
            
            let contactFetchRequest = CNContactFetchRequest(keysToFetch: allowedContactKeys())
            
            do {
                try contactsStore.enumerateContacts(with: contactFetchRequest, usingBlock: { [weak self] (contact, stop) -> Void in
                    
                    //Adds the `contact` to the `contactsArray` if the closure returns true.
                    //If the closure doesn't exist, then the contact is added.
                    if let shouldIncludeContactClosure = self?.shouldIncludeContact, !shouldIncludeContactClosure(contact) {
                        return
                    }
                    
                    contactsArray.append(contact)
                    
                    //Ordering contacts based on alphabets in firstname
                    var key: String = "#"
                    
                    //If ordering has to be happening via family name change it here.
                    if let firstLetter = self?.firstLetter(for: contact) {
                        key = firstLetter.uppercased()
                    }
                    
                    var contactsForKey = orderedContacts[key] ?? [CNContact]()
                    contactsForKey.append(contact)
                    orderedContacts[key] = contactsForKey
                    
                })
                
                self.orderedContacts = orderedContacts
                self.sortedContactKeys = Array(self.orderedContacts.keys).sorted(by: <)
                if self.sortedContactKeys.first == "#" {
                    self.sortedContactKeys.removeFirst()
                    self.sortedContactKeys.append("#")
                }
                completion(contactsArray, nil)
                
            } catch let error as NSError {
                /// Catching exception as enumerateContactsWithFetchRequest can throw errors
                print(error.localizedDescription)
            }
            
        }
    }
    
    private func firstLetter(for contact: CNContact) -> String? {
        var firstCharacter: Character? = nil
        switch sortOrder {
        case .userDefault where CNContactsUserDefaults.shared().sortOrder == .familyName:
            fallthrough
        case .familyName:
            firstCharacter = contact.familyName.first
        case .userDefault where CNContactsUserDefaults.shared().sortOrder == .givenName:
            fallthrough
        case .givenName:
            fallthrough
        default:
            firstCharacter = contact.givenName.first
        }
        guard let letter = firstCharacter else { return nil }
        let firstLetter = String(letter)
        return firstLetter.containsAlphabets() ? firstLetter : nil    
    }
    
    // MARK: - Table View DataSource
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        if let searchText = searchBar.text, !searchText.isEmpty { return 1 }
        return sortedContactKeys.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let searchText = searchBar.text, !searchText.isEmpty { return filteredContacts.count }
        if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
            return contactsForSection.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    // MARK: - Table View Delegates
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ContactCell
        //Convert CNContact to Contact
        let contact: Contact
        if let searchText = searchBar.text, !searchText.isEmpty {
            contact = Contact(contact: filteredContacts[(indexPath as NSIndexPath).row])
        } else {
            guard let contactsForSection = orderedContacts[sortedContactKeys[(indexPath as NSIndexPath).section]] else {
                assertionFailure()
                return UITableViewCell()
            }
            contact = Contact(contact: contactsForSection[(indexPath as NSIndexPath).row])
        }
        cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: subtitleCellValue)
        cell.delegate = self
        return cell
    }
    
    public func visibleRect(for tableView: UITableView) -> CGRect? {
        if usesTallCells == false { return nil }
        if #available(iOS 11.0, *) {
            return tableView.safeAreaLayoutGuide.layoutFrame
        } else {
            let topInset = navigationController?.navigationBar.frame.height ?? 0
            let bottomInset = navigationController?.toolbar?.frame.height ?? 0
            let bounds = tableView.bounds
            return CGRect(x: bounds.origin.x, y: bounds.origin.y + topInset, width: bounds.width, height: bounds.height - bottomInset)
        }
    }
    
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let searchText = searchBar.text, !searchText.isEmpty { return 0 }
        return sortedContactKeys.index(of: title)!
    }
    
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if shouldShowIndexBar {
            if let searchText = searchBar.text, !searchText.isEmpty { return nil }
            return sortedContactKeys
        } else {
            return nil
        }
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let searchText = searchBar.text, !searchText.isEmpty { return nil }
        return sortedContactKeys[section]
    }
    
    // MARK: - UISearchBarDelegate
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults(for: searchBar)
    }
    
    open func updateSearchResults(for searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: searchText)
            updateContacts(with: predicate)
        
        } else {
            self.tableView.reloadData()
        }
    }
    
    private func updateContacts(with predicate: NSPredicate) {
        do {
            filteredContacts = try contactsStore.unifiedContacts(matching: predicate,
                                                                 keysToFetch: allowedContactKeys())
            if let shouldIncludeContact = shouldIncludeContact {
                filteredContacts = filteredContacts.filter(shouldIncludeContact)
            }
            self.tableView.reloadData()
        }
        catch {
        }
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)

        searchBar.text = nil
        
        DispatchQueue.main.async(execute: {
            searchBar.resignFirstResponder()
        })
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async(execute: {
            searchBar.setShowsCancelButton(false, animated: true)
            self.updateSearchResults(for: searchBar)
        })
    }
    
    func removeContact(with indexPath: IndexPath, contact: Contact) {
        guard let selectedContact = contact.contacts else { return }
        deleteContact(Contact: selectedContact, completionHandler: { result in
            if case .Success =  result {
                if let searchText = self.searchBar.text, !searchText.isEmpty {
                    self.filteredContacts.remove(at: indexPath.row)
                } else {
                    guard var contactsForSection = self.orderedContacts[self.sortedContactKeys[indexPath.section]] else { return }
                    contactsForSection.remove(at: indexPath.row)
                    self.orderedContacts.updateValue(contactsForSection, forKey: self.sortedContactKeys[indexPath.section])
                }
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                let contactsInSection = self.orderedContacts[self.sortedContactKeys[indexPath.section]]
                guard let contacts = contactsInSection, contacts.count == 0 else { return }
                self.sortedContactKeys.remove(at: indexPath.section)
                let indexSet = IndexSet.init(integer: indexPath.section)
                self.tableView.deleteSections(indexSet, with: .automatic)
            }
        })
    }
}

extension MainContact: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let cell = tableView.cellForRow(at: indexPath) as! ContactCell
        let selectedContact =  cell.contact!
        if orientation == .left {
            guard isSwipeRightEnabled else { return nil }
            let call = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.makeCallWithContact(selectedContact: selectedContact)
            }
            configure(action: call, with: .call)
            let message = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.selectPhoneNumberWithActionSheet(selectedContact: selectedContact, completion: { (phoneNumber, index) in
                    guard let number = phoneNumber, MFMessageComposeViewController.canSendText() else { return }
                    let composeVC = MFMessageComposeViewController()
                    composeVC.messageComposeDelegate = self
                    composeVC.recipients = [number]
                    composeVC.body = ""
                    self.present(composeVC, animated: true, completion: nil)
                })
            }
            configure(action: message, with: .message)
            let actions = [call, message]
            actions.forEach({ $0.hidesWhenSelected = true })
            return actions
        } else {
            let isFavoriteContact = FavoriteHelper.shared.isFavorite(contactId: selectedContact.contactId)
            let favorite = SwipeAction(style: .default, title: nil) { action, indexPath in
                FavoriteHelper.shared.updateFavorite(contact: selectedContact)
                cell.refreshFavorite(contact: selectedContact)
            }
            configure(action: favorite, with: isFavoriteContact ? .favorite : .notfavorite)
            let delete = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.showAlert(title: "Message", message: "Do you want to delete contact?", buttonTitles: ["OK", "Cancel"], highlightedButtonIndex: 1, completion: { index in
                    if index == 0 {
                        self.removeContact(with: indexPath, contact: selectedContact)
                    } else {
                        cell.hideSwipe(animated: true)
                    }
                })
            }
            configure(action: delete, with: .trash)
            let actions = [delete, favorite]
            actions.forEach({ $0.hidesWhenSelected = true })
            return actions
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        switch buttonStyle {
        case .backgroundColor:
            options.buttonSpacing = 5
        case .circular:
            options.buttonSpacing = 4
            options.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
        }
        return options
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
}

extension MainContact: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
