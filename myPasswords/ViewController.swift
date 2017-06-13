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
    
    @IBAction func generatePassword(_ sender: Any) {
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
                }
            }
        }
        
    }
    
    func saveData( sitename: String, username: String, passwd: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
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
    
    
    func loadData() {
        
        let context = getContext()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SiteRecord")
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
        // -------------
    }
     override func viewDidLoad() {
        super.viewDidLoad()
        createKeyPadDoneKey()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        siteTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell( style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Jim"
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    

}

