import UIKit
import ContactsUI

extension UIAlertController {
    
    /// Add Contacts Picker
    ///
    /// - Parameters:
    ///   - selection: action for selection of contact
    
    func addContactsPicker(selection: @escaping ContactsPickerViewController.Selection) {
        let selection: ContactsPickerViewController.Selection = selection
        var contact: [ContactModel]?
        let addContact = UIAlertAction(title: "Add Contact", style: .default) { action in
            selection(contact!)
        }
        addContact.isEnabled = false
        
        let vc = ContactsPickerViewController { new in
            addContact.isEnabled = new.count > 0
            contact = new
        }
        set(vc: vc)
        addAction(addContact)
    }
    
    func addContactsPicker(contacts: [Contact], selection: @escaping ContactsPickerViewController.Selection) {
        let selection: ContactsPickerViewController.Selection = selection
        var contact: [ContactModel]?
        let addContact = UIAlertAction(title: "Add Contact", style: .default) { action in
            selection(contact!)
        }
        addContact.isEnabled = false
        let pickerVC = ContactsPickerViewController(selection: selection, selectedContacts: contacts, isDisableDeSelect: true)
        pickerVC.selection = { new in
            addContact.isEnabled = new.count > 0
            contact = new
        }
        set(vc: pickerVC)
        addAction(addContact)
    }
}

final class ContactsPickerViewController: UIViewController {
    
    // MARK: UI Metrics
    
    struct UI {
        static let rowHeight: CGFloat = 58
        static let separatorColor: UIColor = UIColor.lightGray.withAlphaComponent(0.4)
    }
    
    // MARK: Properties
    
    public typealias Selection = ([ContactModel]) -> ()
    public typealias SelectionWithAvailableContact = ([ContactModel]) -> ()
    fileprivate var selection: Selection?
    
    //Contacts ordered in dicitonary alphabetically
    fileprivate var orderedContacts = [String: [CNContact]]()
    fileprivate var sortedContactKeys = [String]()
    fileprivate var filteredContacts: [CNContact] = []
    fileprivate var isDisableDeSelectedRow: Bool = false
    fileprivate var selectedContact = [ContactModel]()
    
    fileprivate lazy var searchView: UIView = UIView()
    
    fileprivate lazy var searchController: UISearchController = {
        $0.searchResultsUpdater = self
        $0.searchBar.delegate = self
        $0.dimsBackgroundDuringPresentation = false
        /// true if search bar in tableView header
        $0.hidesNavigationBarDuringPresentation = true
        $0.searchBar.searchBarStyle = .minimal
        $0.searchBar.textField?.textColor = .black
        $0.searchBar.textField?.clearButtonMode = .whileEditing
        return $0
    }(UISearchController(searchResultsController: nil))
    
    fileprivate lazy var tableView: UITableView = { [unowned self] in
        $0.dataSource = self
        $0.delegate = self
        $0.allowsMultipleSelection = true
        $0.rowHeight = UI.rowHeight
        $0.separatorColor = UI.separatorColor
        $0.bounces = true
        $0.backgroundColor = nil
        $0.tableFooterView = UIView()
        $0.sectionIndexBackgroundColor = .clear
        $0.sectionIndexTrackingBackgroundColor = .clear
        $0.register(ContactTableViewCell.self,
                    forCellReuseIdentifier: ContactTableViewCell.identifier)
        return $0
        }(UITableView(frame: .zero, style: .plain))
    
    // MARK: Initialize
    
    required init(selection: Selection?) {
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(selection: Selection?, selectedContacts:[Contact], isDisableDeSelect: Bool) {
        self.isDisableDeSelectedRow = isDisableDeSelect
        self.selection = selection
        self.selectedContact = selectedContacts.compactMap({ item in
            guard let contact = item.contacts?.copy() as? CNContact else { return nil }
            return ContactModel(contact: contact)
        })
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // http://stackoverflow.com/questions/32675001/uisearchcontroller-warning-attempting-to-load-the-view-of-a-view-controller/
        let _ = searchController.view
    }
    
    override func loadView() {
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateContacts()
        if UIDevice.current.userInterfaceIdiom == .pad {
            preferredContentSize.width = UIScreen.main.bounds.width / 2
        }
       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchView.addSubview(searchController.searchBar)
        tableView.tableHeaderView = searchView
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .bottom
        definesPresentationContext = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.tableHeaderView?.height = 57
        searchController.searchBar.sizeToFit()
        searchController.searchBar.frame.size.width = searchView.frame.size.width
        searchController.searchBar.frame.size.height = searchView.frame.size.height
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize.height = tableView.contentSize.height
    }
    
    func updateContacts() {
        checkStatus { [unowned self] orderedContacts in
            
            self.orderedContacts = orderedContacts
            self.sortedContactKeys = Array(self.orderedContacts.keys).sorted(by: <)
            
            if self.sortedContactKeys.first == "#" {
                self.sortedContactKeys.removeFirst()
                self.sortedContactKeys.append("#")
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.view.setNeedsLayout()
            }
        }
    }
    
    func checkStatus(completionHandler: @escaping ([String: [CNContact]]) -> ()) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
            
        case .notDetermined:
            /// This case means the user is prompted for the first time for allowing contacts
            Contacts.requestAccess { [unowned self] bool, error in
                self.checkStatus(completionHandler: completionHandler)
            }
            
        case .authorized:
            /// Authorization granted by user for this app.
            DispatchQueue.main.async {
                self.fetchContacts(completionHandler: completionHandler)
            }

        case .denied, .restricted:
            /// User has denied the current app to access the contacts.
            let productName = Bundle.main.infoDictionary!["CFBundleName"]!
            let alert = UIAlertController(style: .alert, title: "Permission denied", message: "\(productName) does not have access to contacts. Please, allow the application to access to your contacts.")
            alert.addAction(title: "Settings", style: .destructive) { action in
                if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            alert.addAction(title: "OK", style: .cancel) { [unowned self] action in
                self.alertController?.dismiss(animated: true)
            }
            alert.show()
        }
    }
    
    func fetchContacts(completionHandler: @escaping ([String: [CNContact]]) -> ()) {
        Contacts.fetchContactsGroupedByAlphabets { [unowned self] result in
            switch result {
                
            case .success(let orderedContacts):
                completionHandler(orderedContacts)
                
            case .error(let error):
                Log("------ error")
                let alert = UIAlertController(style: .alert, title: "Error", message: error.localizedDescription)
                alert.addAction(title: "OK") { [unowned self] action in
                    self.alertController?.dismiss(animated: true)
                }
                alert.show()
            }
        }
    }
    
    func contact(at indexPath: IndexPath) -> ContactModel? {
        if searchController.isActive {
            return ContactModel(contact: filteredContacts[indexPath.row])
        }
        let key: String = sortedContactKeys[indexPath.section]
        if let contact = orderedContacts[key]?[indexPath.row] {
            return ContactModel(contact: contact)
        }
        return nil
    }
    
    func indexPathOfSelectedContact() -> [IndexPath]? {
        var indexOfSelectedContact:[IndexPath] = []
        selectedContact.forEach {
            if searchController.isActive {
                for row in 0 ..< filteredContacts.count {
                    if filteredContacts[row] == $0.value {
                        indexOfSelectedContact.append(IndexPath(row: row, section: 0))
                    }
                }
            }
            for section in 0 ..< sortedContactKeys.count {
                if let orderedContacts = orderedContacts[sortedContactKeys[section]] {
                    for row in 0 ..< orderedContacts.count {
                        if orderedContacts[row] == $0.value {
                            indexOfSelectedContact.append(IndexPath(row: row, section: section))
                        }
                    }
                }
            }
        }
        
        return indexOfSelectedContact
    }
}

// MARK: - UISearchResultsUpdating

extension ContactsPickerViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, searchController.isActive {
            Contacts.searchContact(searchString: searchText) { [unowned self] result in
                switch result {
                case .success(let contacts):
                    self.filteredContacts = contacts
                    self.tableView.reloadData()
                case .error(let error):
                    Log(error.localizedDescription)
                    self.tableView.reloadData()
                }
            }
        } else {
            tableView.reloadData()
        }
        
        guard let selectedIndexPath = indexPathOfSelectedContact() else { return }
        Log("selectedIndexPath = \(selectedIndexPath)")
        selectedIndexPath.forEach {
            tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
        }
        
    }
}

// MARK: - UISearchBarDelegate

extension ContactsPickerViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}

// MARK: - TableViewDelegate

extension ContactsPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let contact = contact(at: indexPath) else { return }
        let index = selectedContact.index(where: {$0.value.identifier == contact.value.identifier })
        if let indexOfItem = index {
            if !isDisableDeSelectedRow {
                selectedContact.remove(at: indexOfItem)
            } else {
                return
            }
        } else {
            selectedContact.append(contact)
        }
        tableView.reloadRows(at: [indexPath], with: .fade)
        selection?(selectedContact)
    }
}

// MARK: - TableViewDataSource

extension ContactsPickerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive { return 1 }
        return sortedContactKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive { return filteredContacts.count }
        if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
            return contactsForSection.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if searchController.isActive { return 0 }
        tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top , animated: false)
        return sortedContactKeys.index(of: title)!
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive { return nil }
        return sortedContactKeys
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive { return nil }
        return sortedContactKeys[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.identifier) as! ContactTableViewCell
        guard let contact = contact(at: indexPath) else { return UITableViewCell() }
        let isContans = selectedContact.contains(where: { $0.value.identifier == contact.value.identifier })
        cell.accessoryType = isContans ? .checkmark : .none
        cell.configure(with: contact)
        return cell
    }
}
