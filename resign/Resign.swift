//
//  Resign.swift
//  resign
//
//  Created by Aaron Yaeger on 10/4/15.
//  Copyright © 2015 Aaron Yaeger. All rights reserved.
//

import Foundation

extension NSData {
    
    var hexString : String {
        let buf = UnsafePointer<UInt8>(bytes)
        let charA = UInt8(UnicodeScalar("a").value)
        let char0 = UInt8(UnicodeScalar("0").value)
        
        func itoh(i: UInt8) -> UInt8 {
            return (i > 9) ? (charA + i - 10) : (char0 + i)
        }
        
        var p = UnsafeMutablePointer<UInt8>.alloc(length * 2)
        
        for i in 0..<length {
            p[i*2] = itoh((buf[i] >> 4) & 0xF)
            p[i*2+1] = itoh(buf[i] & 0xF)
        }
        
        return NSString(bytesNoCopy: p, length: length*2, encoding: NSUTF8StringEncoding, freeWhenDone: true)! as String
    }
}




enum YesNo {
    case No , Yes, Undecided
}


func executeCommand(command: String, args: [String]) -> NSString? {
    
    let task = NSTask()
    
    task.launchPath = command
    task.arguments = args
    
    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: NSString? = String(data: data, encoding: NSUTF8StringEncoding)
    
    return output
}

func input() -> String {
    let keyboard = NSFileHandle.fileHandleWithStandardInput()
    let inputData = keyboard.availableData
    return NSString(data: inputData, encoding:NSUTF8StringEncoding) as! String
}

func getCFBundleIdentifier(infoFilePath: String) -> NSString {
    if (NSFileManager.defaultManager().fileExistsAtPath(infoFilePath)) {
        commandOutput = executeCommand("/usr/local/bin/plistbuddy", args: ["-c", "Print CFBundleIdentifier", infoFilePath])
        if let cmdOutput = commandOutput {
            startingBundleID = cmdOutput
            print("- BundleID is currently set to: \(cmdOutput)")
            return cmdOutput
        } else {
            print("ERROR MSG: Could not extract CFBundleIdentifier from \(infoFilePath)")
            exit(1)
        }
    } else {
        print("ERROR MSG: Could not find file: \(payloadDirectoryPath)")
        exit(1)
    }
}
