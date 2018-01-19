//
//  ViewController.swift
//  myPasswords
//
//  Created by John Clute on 6/10/17.
//  Copyright © 2017 creativeApps. All rights reserved.
//

import UIKit
import CoreData
import Security


extension UIViewController {
    func setupViewResizerOnKeyboardShown() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(UIViewController.keyboardWillShowForResizing),
                                               name: Notification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(UIViewController.keyboardWillHideForResizing),
                                               name: Notification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    @objc func keyboardWillShowForResizing(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let window = self.view.window?.frame {
            // We're not just minusing the kb height from the view height because
            // the view could already have been resized for the keyboard before
            self.view.frame = CGRect(x: self.view.frame.origin.x,
                                     y: self.view.frame.origin.y,
                                     width: self.view.frame.width,
                                     height: window.origin.y + window.height - keyboardSize.height)
        } else {
            debugPrint("We're showing the keyboard and either the keyboard size or window is nil: panic widely.")
        }
    }
    @objc func keyboardWillHideForResizing(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let viewHeight = self.view.frame.height
            self.view.frame = CGRect(x: self.view.frame.origin.x,
                                     y: self.view.frame.origin.y,
                                     width: self.view.frame.width,
                                     height: viewHeight + keyboardSize.height)
        } else {
            debugPrint("We're about to hide the keyboard and the keyboard size is nil. Now is the rapture.")
        }
    }
    
    
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
{
    
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unexpectedItemData
        case unhandledError(status: OSStatus)
    }
    let utils = PassWordUtils()
  
    let key : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_"
    
    let fudgeFactor = 100
    let usrNameSize = 12
    let usrQuestionSize = 40
    var secQuest = ""
    let secMask = "*************************"
    var siteEntry = [String:Any]()
    var siteEntryArray = Array <[String:Any]>()
    var searchActive: Bool = false
    var passwordItems = [KeychainPasswordItem]()

    let mkPassword = PasswordUtility()
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var passwordStatus: UISwitch!
        
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginQuestions: UITextView!
    
    @IBOutlet weak var searchTerm: UISearchBar!
    
    @IBOutlet weak var siteTable: UITableView!
    
    @IBOutlet weak var siteName: UITextField!

    @IBOutlet weak var btnClearAll: UILabel!
    
    @IBOutlet weak var btnSaveEntry: UIButton!
    
    @IBAction func clearAllEntries(_ sender: Any) {
        
        let refreshAlert = UIAlertController(title: "Refresh", message: "All Passwords will be deleted.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.deleteAll()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Nothing deleted")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func saveEntry(_ sender: Any) {
        savePassWordInfo()
    }
    
    
    @IBAction func swtchShowPassword(_ sender: Any) {
        let status = passwordStatus.isOn
        if status == true {
            password.isSecureTextEntry = false
            loginQuestions.text = secQuest
        } else if status == false {
            password.isSecureTextEntry = true
            if !secQuest.isEmpty {
                loginQuestions.text = secMask
            }
        }
  
    }
    
    func makeRandom(sz:Int) -> String {
        
        let rv = generateRandomBytes(arraySize: sz)
        //let cnt = sz
        let cryptkey = Array(key)
        //print ("Size of data \( cnt ) ")
        var i = 0
        var idx = 0
        var pwd=""
      //  let sz = cryptkey.count
       // print ("\(sz)")
        
        for byte in rv {
            i = i+1
            idx = Int(byte)
            //print ("\(i): \(byte) \(cryptkey[idx])")
            pwd.append(cryptkey[idx])
        }
        return pwd
    }
    
    func generateRandomBytes(arraySize: Int) -> Data {
        let pwdLen = arraySize
        
        var keyData = Data(count: pwdLen)
        let result = keyData.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, keyData.count, mutableBytes)
        }
        //  for byte in keyData { print(byte) }
        
        if result == errSecSuccess {
            return keyData
        } else {
            print("Problem generating random bytes")
            return Data()
        }
    }
    
    
    func getContext() -> NSManagedObjectContext {
        /*
         function: getContext
         Purpose: Return context so that we can work with the CoreData
         returns: Context - NSManagedObjectContext
         */
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        print("Begin Editing")
        btnSaveEntry.isEnabled = false
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
//        print ("End Editing")
//        loadSearchData()
         searchBar.text = ""
         loadData()
         siteTable.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
      //  print("Cancl Editing")
        searchActive = false
        searchBar.text = ""
        loadData()
        siteTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search clicked")
        searchActive = false
        loadSearchData()
        siteTable.reloadData()
        
    }
    
    @IBAction func clearTextFields(_ sender: Any) {
        clearFields()
    }
    
    func clearFields() {
        userName.text = ""
        password.text = ""
        loginQuestions.text = ""
        searchTerm.text = ""
        siteName.text = ""
        secQuest = ""
        loadData()
        passwordStatus.isOn = false
        password.isSecureTextEntry = true
        siteTable.reloadData()
        if btnSaveEntry.isEnabled == true {
            btnSaveEntry.isEnabled = false
        }
    }
    
    func isNumeric(input: String) -> Int {
        var rc = 0
        rc = 1
        let numberCharacters = NSCharacterSet.decimalDigits.inverted
        if !input.isEmpty && input.rangeOfCharacter(from: numberCharacters) == nil {
            rc = Int(input)!
        } else {
            rc = 0
        }
        return rc
    }
    
    @IBAction func btnGeneratePassword(_ sender: Any) {
        //var pwdLen = 9
        password.text = mkPassword.createPassword()
/*        if let tmplen = passwordSize.text {
            
            pwdLen = isNumeric(input: tmplen)
            if pwdLen == 0 {return}
        }
        
        let genPassword = makeRandom(sz: pwdLen)
        password.text = genPassword
        if btnSave.isEnabled == false {
            btnSave.isEnabled = true
        }
        // want to save password now
        if btnSave.isEnabled == false {
            btnSave.isEnabled = true
        }
 */
    }
    
    func savePassWordInfo() {
        if let sitename = siteName.text {
            if let username = userName.text {
                if let sz = password.text?.utf8CString.count {
                    if sz == 0 {return}
                    let passwd = makeRandom(sz: sz)
                    saveData(sitename: sitename, username: username, passwd: passwd)
                    siteName.text = ""
                    userName.text = ""
                    password.text = ""
                    loginQuestions.text = ""
                }
            }
        }
        // want to save password now
        if btnSaveEntry.isEnabled == true {
            btnSaveEntry.isEnabled = false
        }
        loadData()
        siteTable.reloadData()
        
    }
    
    
    func findSiteName(siteName: String) -> Bool {
    
        var found = false
        let context = getContext()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteRecord")
        request.predicate = NSPredicate(format: "entryname = %@", siteName)
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                found = true
            }
        } catch  {
            print ("Could not get results from database\n")
            
        }
        
        return found
        
    }
    
    
    func deleteAll () {
        var idx = 0
        while idx < siteEntryArray.count {
            siteEntry = siteEntryArray[idx]
            let sitename = siteEntry["entryName"] as! String
            let deleted = deleteEntry(sitename: sitename)
            if deleted {
                print ("Entry Deleted!")
            } else {
                print ("Entry not deleted")
            }
            idx += 1
        }
        loadData()
        siteTable.reloadData()
        clearFields()

    }
    
    
    func deleteEntry(sitename: String) -> Bool {
 
        let context = getContext()
        var deleted = false
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteRecord")
        request.predicate = NSPredicate(format: "((entryname == %@))", sitename)
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    context.delete(result)
                    do {
                        try context.save()
                       // print ("Deleted record")
                        let del = deletePass(siteName: sitename)
                        if del {
                            deleted = true
                        } else {
                            print("Delete did not work in keychain")
                        }
                    } catch {
                        print("Delete did not work")
                    }
                }
            }
        } catch {
            print("Fetch did not work properly")
        }
        
        return deleted
    }
    
    
    func saveData( sitename: String, username: String, passwd: String)
    {
        let context = getContext()
        var deleted: Bool = true
        let found = findSiteName(siteName: sitename)
        if found {
            deleted = deleteEntry(sitename: sitename)
        }
        if deleted {
            let taskStorage = NSEntityDescription.insertNewObject(forEntityName: "SiteRecord", into: context)
            taskStorage.setValue(sitename, forKey: "entryname")
            do {
                try context.save()
                savePasswordKeyChain()
              //  print ("Saved! \(sitename)\n")
        
            } catch {
                print ("Could not save users entry")
            }
        } else {
            print("Did not create \(sitename)\n")
        }
        
    }
    
    func savePassword(inPassword: String, inSiteName: String) {
     
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: inSiteName, accessGroup: KeychainConfiguration.accessGroup)
            // This is a new account, create a new keychain item with the account name.
            
            // Save the password for the new item.
//            try passwordItem.saveAll(inPassword, userN: userN!, quest: quest!)
            try passwordItem.savePassword(inPassword)
        }
        catch {
            fatalError("Error updating keychain - \(error)")
        }
        
        do {
            let newAccount = inSiteName + "_userN"
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: newAccount, accessGroup: KeychainConfiguration.accessGroup)
           // This is a new account, create a new keychain item with the account name.
            if let userN = userName.text {
            // Save the password for the new item.
                try passwordItem.savePassword(userN)
            }
        }
        catch {
            fatalError("Error updating keychain - \(error)")
        }
        do {
            let newAccount = inSiteName + "_quest"
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: newAccount, accessGroup: KeychainConfiguration.accessGroup)
            // This is a new account, create a new keychain item with the account name.
            if var questions : String = loginQuestions.text {
                if questions.isEmpty {
                    questions = "Blank"
                }
                // Save the password for the new item.
                 try passwordItem.savePassword(questions)
            }
        }
        catch {
            fatalError("Error updating keychain - \(error)")
        }

    }
    
    
    func savePasswordKeyChain() {
        // Check that text has been entered into both the account and password fields.
        guard let newAccountName = siteName.text, let newPassword = password.text, !newAccountName.isEmpty && !newPassword.isEmpty else { return }
        
        savePassword(inPassword: newPassword, inSiteName: newAccountName)
    }
    
    
    func deletePass( siteName: String) -> Bool {
        var rc = true
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: siteName, accessGroup: KeychainConfiguration.accessGroup)
            
            try passwordItem.deleteItem()
        
        }
        catch {
            rc = false
            fatalError("Error reading password from keychain - \(error)")
        }
        do {
            let newSite = siteName + "_userN"
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: newSite, accessGroup: KeychainConfiguration.accessGroup)
            
            try passwordItem.deleteItem()
            
        }
        catch {
            rc = false
            fatalError("Error reading password from keychain - \(error)")
        }
        do {
            let newSite = siteName + "_quest"
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: newSite, accessGroup: KeychainConfiguration.accessGroup)
            
            try passwordItem.deleteItem()
            
        }
        catch {
            rc = false
            fatalError("Error reading password from keychain - \(error)")
        }
        return rc
    }
    
    func getpass(siteName: String) -> String {
        var rc = ""
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: siteName, accessGroup: KeychainConfiguration.accessGroup)
            
           // let accnt = passwordItem.account
           // print(accnt)
            rc = try passwordItem.readPassword()
           // print (rc)
        }
        catch KeychainError.noPassword {
            rc = ""
        } catch {
            rc=""
        }
        return rc
    }
    
    
    func loadSearchData() {
        siteEntryArray.removeAll()
        let searchText = searchTerm.text!
        let context = getContext()
        let sortDescriptor = NSSortDescriptor(key: "entryname", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteRecord")
        request.sortDescriptors = sortDescriptors
        request.predicate = NSPredicate(format: "entryname BEGINSWITH %@", searchText)
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    siteEntry["entryName"] = result.value(forKey: "entryname")
                    let tmpsite = siteEntry["entryName"] as! String
                    siteEntry["password"] = getpass(siteName: tmpsite)
                    siteEntry["userName"] = getpass(siteName: tmpsite+"_userN")
                    siteEntry["loginQuestions"] = getpass(siteName: tmpsite+"_quest")
                    
                    siteEntryArray.append(siteEntry)
                }
            }
        } catch  {
            print ("Could not get results from database\n")
        }
        
    }
    
    func loadData() {
        
        siteEntryArray.removeAll()
        // setting up cipher,
        let context = getContext()
        let sortDescriptor = NSSortDescriptor(key: "entryname", ascending: true)
        let sortDescriptors = [sortDescriptor]

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteRecord")
        request.sortDescriptors = sortDescriptors
//        request.predicate = NSPredicate(format: "entryname = %@","*")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    siteEntry["entryName"] = result.value(forKey: "entryname")
                    // get key
                     let tmpsite = siteEntry["entryName"] as! String
 //                   let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: tmpsite, accessGroup: KeychainConfiguration.accessGroup)
                    
//                    let accnt = passwordItem.account
//                    print ("HI this is the password info account: \(accnt)")

                    siteEntry["password"] = getpass(siteName: tmpsite)
                    siteEntry["userName"] = getpass(siteName: tmpsite+"_userN")
                    siteEntry["loginQuestions"] = getpass(siteName: tmpsite+"_quest")
                    
                    siteEntryArray.append(siteEntry)
                    
                }
            }
        } catch  {
            print ("Could not get results from database\n")
        }
    }
    
    /// Close textfield keyboard when finishing editing.
    ///
    /// - Parameter textField: <#textField description#>
    /// - Returns: <#return value description#>
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if btnSaveEntry.isEnabled == false {
            btnSaveEntry.isEnabled = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        // want to save password now
        if btnSaveEntry.isEnabled == false {
            btnSaveEntry.isEnabled = true
        }
        return true
    }
    
    @objc func doneClicked() {
        view.endEditing(true)
        if ((self.password.text == "") && (self.userName.text == "") && (self.siteName.text == "")) {
            // User did not edit anything so we are not enabling save key
            return
        }
        // want to save password now
        if btnSaveEntry.isEnabled == false {
            btnSaveEntry.isEnabled = true
        }
    }
    
   
    func createKeyPadDoneKey() {
        //create a toolbar above keyboard on iphone
        // need to set size to fit so that it will go all the way across the view
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        // Do any additional setup after loading the view, typically from a nib.
        // create donebutton, this is will close the keyboard  Also created an action doneClicked function
        // that performs endsEditing and closes the keyboard
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(doneClicked))
        // flexible space is used to push the done button to the right, I like the look of it.
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        // add buttons to toolbar
        toolBar.setItems([flexibleSpace,doneButton], animated: false)
        loginQuestions.inputAccessoryView = toolBar
        userName.inputAccessoryView = toolBar
        password.inputAccessoryView = toolBar
        searchTerm.inputAccessoryView = toolBar
        siteName.inputAccessoryView = toolBar
        
        // -------------
    }
     override func viewDidLoad() {
        super.viewDidLoad()
        createKeyPadDoneKey()
        setupViewResizerOnKeyboardShown()
        navBar.alpha = 0
        
    }
    override func viewDidAppear(_ animated: Bool) {
        
        
        clearFields()
        loadData()
        siteTable.reloadData()
        
        if btnSaveEntry.isEnabled == true {
            btnSaveEntry.isEnabled = false
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sz = siteEntryArray.count
        return sz
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell( style: UITableViewCellStyle.value2, reuseIdentifier: "cell")
        let siteEntry = siteEntryArray[indexPath.row]
        let tableText = siteEntry["entryName"] as! String
        // was using detail and label to do display info, now just using textlabel

        cell.detailTextLabel?.text = tableText
       // let usern = siteEntry["userName"] as! String
       // cell.textLabel?.text = usern
       // cell.detailTextLabel?.text = tableText
        
       
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete {
            let idx = indexPath.row
            let siteEntry = siteEntryArray[idx]
            let sitename = siteEntry["entryName"] as! String
            let deleted = deleteEntry(sitename: sitename)
            if deleted {
                print ("Site entry \(sitename) deleted!\n")
            } else {
                print ("Site entry \(sitename) not deleted\n")
            }
            if searchActive {
                loadSearchData()
            } else {
                loadData()
            }
            siteTable.reloadData()
            clearFields()
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let idx = indexPath.row
        let siteEntry = siteEntryArray[idx]
        let usern = siteEntry["userName"] as! String
        let passwd = siteEntry["password"] as! String
        let entryn = siteEntry["entryName"] as! String
        let questions = siteEntry["loginQuestions"] as! String
        
        userName.text = usern
        passwordStatus.isOn = false
        password.isSecureTextEntry = true
        password.text = passwd
        siteName.text = entryn
        if !questions.isEmpty {
            loginQuestions.text = secMask
        } else {
            loginQuestions.text = ""
        }
        secQuest = questions

        
        //want to make sure save is not turned on and save data by accident.
        if btnSaveEntry.isEnabled == true {
            btnSaveEntry.isEnabled = false
        }
        
    }
    
    

}

