//
//  UtilityFile.swift
//  myPasswords
//
//  Created by John Clute on 6/20/17.
//  Copyright © 2017 creativeApps. All rights reserved.
//

import Foundation

class PassWordUtils: NSObject {
    
    func setCipher( cipher: [UInt8]) -> [UInt8] {
        var tmpCipher = cipher
        let first = tmpCipher[4]
        let last = tmpCipher[5]
        tmpCipher[4] = last
        tmpCipher[5] = first
        return tmpCipher
    }
    
    
    func encryptValue(text: [UInt8], cipher: [UInt8]) -> String {
        
        let newCipher = setCipher(cipher: cipher)
        var encrypted = [UInt8]()
        
        for t in text.enumerated() {
            encrypted.append(t.element ^ newCipher[t.offset])
        }
        if let rc = String(bytes: encrypted, encoding: .utf8) {
            return rc
        } else{
            return ""
        }

    }
    
    func decryptValue(encrypted: [UInt8], cipher: [UInt8]) -> String {
        var decrypted = [UInt8]()
        let newCipher = setCipher(cipher: cipher)
        
        // encrypt bytes
        for t in encrypted.enumerated() {
            decrypted.append(t.element ^ newCipher[t.offset])
        }
        if let rc = String(bytes: decrypted, encoding: .utf8) {
            return rc
        } else{
            return ""
        }
    }
}
