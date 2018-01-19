//
//  PassWordUtility.swift
//  myPasswords
//
//  Created by John Clute on 9/1/17.
//  Copyright © 2017 creativeApps. All rights reserved.
//

import Foundation
class PasswordUtility {
    
    private var dontPrint = true
    private var myString = [String]()
    init() {
        if let path = Bundle.main.path(forResource: "DictionaryList", ofType: "txt"){
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                myString = data.components(separatedBy: .newlines)
                let cnt = myString.count
                var i = 0
                while i < cnt {
                    if !dontPrint {
                        print(myString[i])
                    } else {
                        if myString[i] == "---" {
                            dontPrint = false
                        }
                    }
                    i = i + 1
                }
            } catch {
                print(error)
            }
        }
    }
    
    public func createPassword() -> String {
        
        let cnt = myString.count
        var idx = getRandome(cnt: cnt)
        let passwdPart1 = myString[idx]
        idx = getRandome(cnt: cnt)
        let passwdPart2 = myString[idx]
        let num = getNumbers()
        
        let charsInPassowrd = passwdPart1.capitalized + passwdPart2.capitalized
        
        return charsInPassowrd+num

    }
    
    private func getRandome(cnt: Int) -> Int {
        let randome = arc4random_uniform(UInt32(cnt))
        return Int(randome)
    }
    
    private func getNumbers() -> String {
        let count = 4
        let digit = 10
        let sz = getRandome(cnt: count)
        
        var number = ""
        for _ in 0 ... sz {
            let digitValue = getRandome(cnt: digit)
            number = number + String(digitValue)
        }
        
        return number
    }
}
