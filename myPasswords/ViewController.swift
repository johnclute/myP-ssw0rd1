//
//  ViewController.swift
//  myPasswords
//
//  Created by John Clute on 6/10/17.
//  Copyright © 2017 creativeApps. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
{
    let utils = PassWordUtils()
    let oldCipher = "eiyohY7waoteeYiqu4faezaem7Gii6No5saxi1ochungaethaeliecieToo7jaexekeeCoh8quaor6aetheilaeyeemeethong8kohXei4ohtib4ietaeda2iepeu1ohg7eiFo3aw9yeenoh3Theoy7ahgik1Vimailet2ixeichiesune1eezow2kighohph8eeng4aiP4haekai3Iexaewuizeekee5rohwooqu2xahzoo7phaingung1GaCoongi5miqu4AhDohGaish2nu7xie6ohsee7waighuaSeij6li5eekai0EiSaen7ingei6ha7oovee7apoh1ohLiequ4uoK5axahGhahng6oop1zishahdu0die8ohBaevo6fohGh6die9aithiele8rieyeiB1oodeth9phaequ2ZaexaisheiM1aengii0thieWoh6tieGh0aeziechahcagh4daR7ath4gaeM5wieghul3sah0quahrei1eHie9yaishuo4Gi6ua4aiShoiGh4pheibialae6VaemeeT3za4oomigie4eucieveinoeGah2aeHool1Aiquae6OoZivieDo0eeMai4xah2lahGh2heichaod0ohnoKeefe9Aet1IeThewooLeicei2ziolai6ahsio4Aechiv6cheeghuoviN8Keighi5aish8ic0shoh3ooh6aefaeghaijei8IeMiechiengutheinge5uo5Dath5ra8Umae3eghaoheikaesh7ichoh6Zoveel1nish0ta6Pohv4saiwiqu1Aing7zae1ohsaS0ii5wooRe4tae2queepea0tei1ohquaij6eec2hoo2eeDu3aiWeiRiecugh5phaerooc5googai4xeup9sheiliaTei8de2quee5eer8enuS0gu1peanohthei6ohDoothaedo2dooy8aquaecha8ohguquaihao0Aepei3ukug7aiTaqu0iwiLoc8vie8iehah9choh"
    
    let fudgeFactor = 100
    
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
    }
    func clearFields() {
        passwordSize.text = "9"
        userName.text = ""
        password.text = ""
        loginQuestions.text = ""
        searchTerm.text = ""
        siteName.text = ""
        loadData()
        siteTable.reloadData()
  
    }
    
    @IBAction func btnGeneratePassword(_ sender: Any) {
        var pwdLen = 9
        if let tmp = passwordSize.text {
            if tmp.characters.count > 0 {
                pwdLen = Int(tmp)!
            }
        }
        
        let genPassword = randomString(pwdLen)
        password.text = genPassword
   
    }
    
    
    @IBAction func saveUserInformation(_ sender: Any) {
        if let sitename = siteName.text {
            if let username = userName.text {
                if let passwd = password.text {
                    saveData(sitename: sitename, username: username, passwd: passwd)
                    
                    siteName.text = ""
                    userName.text = ""
                    password.text = ""
                    loginQuestions.text = ""
                    
                }
            }
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
        let cipher = randomString(sz)
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
            cipher = randomString(sz)
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
                print ("Saved! \(sitename)\n")
        
            } catch {
                print ("Could not save users entry")
            }
        } else {
            print("Did not create \(sitename)\n")
        }
        
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
                    if cipher.characters.count == 0 {
                        cipher = oldCipher
                    }
                    let utfCipher = [UInt8](cipher.utf8)
                    let tmpUser = result.value(forKey: "username") as! String
                    
                    siteEntry["userName"] = utils.decryptValue(encrypted: [UInt8](tmpUser.utf8), cipher: utfCipher)
                    let tmpPwd = result.value(forKey: "password") as! String
                    siteEntry["password"] = utils.decryptValue(encrypted: [UInt8](tmpPwd.utf8), cipher: utfCipher)
                    siteEntry["site"] = result.value(forKey: "site")
                    let tmpQuest = result.value(forKey: "questions") as! String
                    siteEntry["loginQuestion"] = utils.decryptValue(encrypted: [UInt8](tmpQuest.utf8), cipher: utfCipher)
                    
                    print("encrypted data - \(tmpUser) \(tmpPwd) \(tmpQuest)\n")
                    
                    siteEntryArray.append(siteEntry)
                }
            }
        } catch  {
            print ("Could not get results from database\n")
        }
    }
    
    func randomString(_ length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    /// Close textfield keyboard when finishing editing.
    ///
    /// - Parameter textField: <#textField description#>
    /// - Returns: <#return value description#>
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func doneClicked() {
        view.endEditing(true)
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
        cell.textLabel?.text = tableText
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
        password.text = passwd
        siteName.text = entryn
        loginQuestions.text = questions
        
    }
    
    

}

