//
//  ViewController.swift
//  myPasswords
//
//  Created by John Clute on 6/10/17.
//  Copyright © 2017 creativeApps. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{

  
    
    @IBOutlet weak var passwordSize: UITextField!
    
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginQuestions: UITextView!
    
    @IBOutlet weak var searchTerm: UISearchBar!
    
    @IBOutlet weak var siteTable: UITableView!
    
    @IBOutlet weak var siteName: UITextField!
    
    var siteEntry = [String:Any]()
    var siteEntryArray = Array <[String:Any]>()
    
    func getContext() -> NSManagedObjectContext {
        /*
         function: getContext
         Purpose: Return context so that we can work with the CoreData
         returns: Context - NSManagedObjectContext
         */
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
        
    }
    
    
    @IBAction func clearTextFields(_ sender: Any) {
        passwordSize.text = "9"
        userName.text = ""
        password.text = ""
        loginQuestions.text = ""
        searchTerm.text = ""
        siteName.text = ""
        
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
            taskStorage.setValue(passwd, forKey: "password")
            taskStorage.setValue(username, forKey: "username")
            taskStorage.setValue("", forKey: "site")
            taskStorage.setValue(loginQuestions.text, forKey: "questions")
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
    
    
    
    func loadData() {
        
        siteEntryArray.removeAll()
        
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
                    siteEntry["userName"] = result.value(forKey: "username")
                    siteEntry["password"] = result.value(forKey: "password")
                    siteEntry["site"] = result.value(forKey: "site")
                    siteEntry["loginQuestion"] = result.value(forKey: "questions")
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
        let usern = siteEntry["userName"] as! String
        cell.textLabel?.text = usern
        cell.detailTextLabel?.text = tableText
        
       
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
            loadData()
            siteTable.reloadData()
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

