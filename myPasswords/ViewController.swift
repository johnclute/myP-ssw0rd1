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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
{
    
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unexpectedItemData
        case unhandledError(status: OSStatus)
    }
    let utils = PassWordUtils()
  
    let key = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_"
    
    let fudgeFactor = 100
    var secQuest = ""
    let secMask = "**********************************************************************************"
    
    
    @IBOutlet weak var showPassword: UISlider!

    @IBOutlet weak var btnSave: UIBarButtonItem!
    
    @IBOutlet weak var passwordSize: UITextField!
    
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginQuestions: UITextView!
    
    @IBOutlet weak var searchTerm: UISearchBar!
    
    @IBOutlet weak var siteTable: UITableView!
    
    @IBOutlet weak var siteName: UITextField!
    
    var siteEntry = [String:Any]()
    var siteEntryArray = Array <[String:Any]>()
    var searchActive: Bool = false
    
    @IBAction func actShowPassword(_ sender: Any) {
        let status = showPassword.value
        if status == 1 {
            password.isSecureTextEntry = false
            loginQuestions.text = secQuest
        } else if status == 0 {
            password.isSecureTextEntry = true
            if !secQuest.isEmpty {
             loginQuestions.text = secMask
            }
        }
    }
    
    func makeRandom(sz:Int) -> String {
        
        let rv = generateRandomBytes(arraySize: sz)
        let cnt = sz
        let cryptkey = Array(key.characters)
        print ("Size of data \( cnt ) ")
        var i = 0
        var idx = 0
        var pwd=""
        let sz = cryptkey.count
        print ("\(sz)")
        
        for byte in rv {
            i = i+1
            idx = Int(byte)
            print ("\(i): \(byte) \(cryptkey[idx])")
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
        btnSave.isEnabled = false
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
        print ("End Editing")
//        loadData()
//        siteTable.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancl Editing")
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
        if btnSave.isEnabled == true {
            btnSave.isEnabled = false
        }
    }
    func clearFields() {
        passwordSize.text = "9"
        userName.text = ""
        password.text = ""
        loginQuestions.text = ""
        searchTerm.text = ""
        siteName.text = ""
        secQuest = ""
        loadData()
        siteTable.reloadData()
  
    }
    
    func isNumeric(input: String) -> Int {
        var rc = 0
        rc = 1
        let numberCharacters = NSCharacterSet.decimalDigits
        if !input.isEmpty && input.rangeOfCharacter(from: numberCharacters) == nil {
            rc = Int(input)!
        } else {
            rc = 0
        }
        return rc
    }
    
    @IBAction func btnGeneratePassword(_ sender: Any) {
        var pwdLen = 9
        
        if let tmplen = passwordSize.text {
            
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
    }
    
    
    @IBAction func saveUserInformation(_ sender: Any) {
        if let sitename = siteName.text {
            if let username = userName.text {
                if let sz = password.text?.characters.count {
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
        if btnSave.isEnabled == true {
            btnSave.isEnabled = false
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
    
    func findSiteKeyName(siteName: String) -> String {
        // get cipher from table
        var cipher = ""
        let context = getContext()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteKeys")
        request.predicate = NSPredicate(format: "entryname = %@", siteName)
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    cipher = result.value(forKey: "key") as! String
                }
            }
        } catch  {
            print ("Could not get results from database\n")
            
        }
        
        return cipher
        
    }
    @IBAction func clearAll(_ sender: Any) {
        
        let refreshAlert = UIAlertController(title: "Refresh", message: "All Passwords will be deleted.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.deleteAll()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Nothing deleted")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    func deleteAll () {
        var idx = 0
        while idx < siteEntryArray.count {
            siteEntry = siteEntryArray[idx]
            let sitename = siteEntry["entryName"] as! String
            var deleted = deleteEntry(sitename: sitename)
            if deleted {
                print ("Entry Deleted!")
            } else {
                print ("Entry not deleted")
            }
            deleted = deleteKeyEntry(sitename: sitename)
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
                        print ("Deleted record")
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
    
    func deleteKeyEntry(sitename: String) -> Bool {
        
        let context = getContext()
        var deleted = false
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteKeys")
        request.predicate = NSPredicate(format: "((entryname == %@))", sitename)
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    context.delete(result)
                    do {
                        try context.save()
                        print ("Deleted record")
                        deleted = true
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

    func saveKeyData(sitename: String, key: String) {
        
        let cipher = findSiteKeyName(siteName: sitename)
        if cipher.characters.count == 0 {
            let context = getContext()
            let keyStorage = NSEntityDescription.insertNewObject(forEntityName: "SiteKeys", into: context)

            keyStorage.setValue(sitename, forKey: "entryname")
            keyStorage.setValue(key, forKey: "key")
            do {
                try context.save()
                print ("Saved! \(sitename)\n")
                
            } catch {
                print ("Could not save users entry")
            }
        } else {
            print("Did not create \(sitename)\n")
        }
        
    }
    
    func createCipher(sz: Int) -> String {
        let cipher = makeRandom(sz: sz)
        return cipher
    }
    
    
    func saveData( sitename: String, username: String, passwd: String)
    {
        var cipher = findSiteKeyName(siteName: sitename)
        if cipher.characters.count == 0 {
            var sz = loginQuestions.text.characters.count + fudgeFactor
            if sz == 0 {
                sz = passwd.characters.count + fudgeFactor
            }
            cipher = makeRandom(sz: sz)
            saveKeyData(sitename: sitename, key: cipher)
        }
        let context = getContext()
        var deleted: Bool = true
        let found = findSiteName(siteName: sitename)
        if found {
            deleted = deleteEntry(sitename: sitename)
        }
        if deleted {
 
            let utfCipher = [UInt8](cipher.utf8)
            let newUserName = utils.encryptValue(text: [UInt8](username.utf8), cipher: utfCipher)
            let newPasswd = utils.encryptValue(text: [UInt8](passwd.utf8), cipher: utfCipher)
            let newQuestions = utils.encryptValue(text: [UInt8](loginQuestions.text.utf8), cipher: utfCipher)
            let taskStorage = NSEntityDescription.insertNewObject(forEntityName: "SiteRecord", into: context)
            taskStorage.setValue(sitename, forKey: "entryname")
            taskStorage.setValue(newPasswd, forKey: "password")
            taskStorage.setValue(newUserName, forKey: "username")
            taskStorage.setValue("", forKey: "site")
            taskStorage.setValue(newQuestions, forKey: "questions")
            do {
                try context.save()
                savePasswordKeyChain()
                print ("Saved! \(sitename)\n")
        
            } catch {
                print ("Could not save users entry")
            }
        } else {
            print("Did not create \(sitename)\n")
        }
        
    }
    
    func savePassword(inPassword: String, inSiteName: String) {
        
        do {
            // This is a new account, create a new keychain item with the account name.
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: inSiteName, accessGroup: KeychainConfiguration.accessGroup)
            
            // Save the password for the new item.
            try passwordItem.savePassword(inPassword)
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
    
    func loadSearchData() {
        siteEntryArray.removeAll()
        var cipher = ""
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
                    cipher = findSiteKeyName(siteName: siteEntry["entryName"] as! String)
                    let utfCipher = [UInt8](cipher.utf8)
                    let tmpUser = result.value(forKey: "username") as! String
                    siteEntry["userName"] = utils.decryptValue(encrypted: [UInt8](tmpUser.utf8), cipher: utfCipher)
                    let tmpPwd = result.value(forKey: "password") as! String
                    siteEntry["password"] = utils.decryptValue(encrypted: [UInt8](tmpPwd.utf8), cipher: utfCipher)
                    siteEntry["site"] = result.value(forKey: "site")
                    let tmpQuest = result.value(forKey: "questions") as! String
                    siteEntry["loginQuestion"] = utils.decryptValue(encrypted: [UInt8](tmpQuest.utf8), cipher: utfCipher)
                    siteEntry["password"] = getpass(siteName: result.value(forKey: "entryName") as! String)
                    siteEntryArray.append(siteEntry)
                }
            }
        } catch  {
            print ("Could not get results from database\n")
        }

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

        return rc
    }
    
    func getpass(siteName: String) -> String {
        var rc = ""
        do {
            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: siteName, accessGroup: KeychainConfiguration.accessGroup)
            
            let accnt = passwordItem.account
            print(accnt)
            rc = try passwordItem.readPassword()
            print (rc)
        }
        catch KeychainError.noPassword {
            rc = ""
        } catch {
            rc=""
        }
        return rc
    }
    
    func loadData() {
        
        siteEntryArray.removeAll()
        // setting up cipher,
        var cipher = ""
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
                    cipher = findSiteKeyName(siteName: siteEntry["entryName"] as! String)
                    print("Cipher - \(cipher)\n")
                    let utfCipher = [UInt8](cipher.utf8)
                    let tmpUser = result.value(forKey: "username") as! String
                    
                    siteEntry["userName"] = utils.decryptValue(encrypted: [UInt8](tmpUser.utf8), cipher: utfCipher)
                    let tmpPwd = result.value(forKey: "password") as! String
                    siteEntry["password"] = utils.decryptValue(encrypted: [UInt8](tmpPwd.utf8), cipher: utfCipher)
                    siteEntry["site"] = result.value(forKey: "site")
                    let tmpsite = siteEntry["entryName"] as! String
                    let tmpQuest = result.value(forKey: "questions") as! String
                    siteEntry["loginQuestion"] = utils.decryptValue(encrypted: [UInt8](tmpQuest.utf8), cipher: utfCipher)
                    
                    print("encrypted data - \(tmpUser) \(tmpPwd) \(tmpQuest)\n")
                    siteEntry["password"] = getpass(siteName: tmpsite)
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
        if btnSave.isEnabled == false {
            btnSave.isEnabled = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        // want to save password now
        if btnSave.isEnabled == false {
            btnSave.isEnabled = true
        }
        return true
    }
    
    func doneClicked() {
        view.endEditing(true)
        // want to save password now
        if btnSave.isEnabled == false {
            btnSave.isEnabled = true
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
        passwordSize.inputAccessoryView = toolBar
        password.inputAccessoryView = toolBar
        searchTerm.inputAccessoryView = toolBar
        siteName.inputAccessoryView = toolBar
        
        // -------------
    }
     override func viewDidLoad() {
        super.viewDidLoad()
        createKeyPadDoneKey()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        clearFields()
        loadData()
        siteTable.reloadData()
        
        if btnSave.isEnabled == true {
            btnSave.isEnabled = false
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
            var deleted = deleteEntry(sitename: sitename)
            if deleted {
                print ("Site entry \(sitename) deleted!\n")
            } else {
                print ("Site entry \(sitename) not deleted\n")
            }
            deleted = deleteKeyEntry(sitename: sitename)
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
        let questions = siteEntry["loginQuestion"] as! String
        
        userName.text = usern
        showPassword.value = 0
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
        if btnSave.isEnabled == true {
            btnSave.isEnabled = false
        }
        
    }
    
    

}

