//
//  main.swift
//  resign
//
//  Created by Aaron Yaeger on 10/4/15.
//  Copyright © 2015 Aaron Yaeger. All rights reserved.
//

import Foundation

var commandOutput: NSString?
var certificates: [NSString]

print("Debug MSG:\(Process.arguments[0])")

// Welcome splash message
print("Hello, Welcome to the NetSPI iOS resigner!")
print("")

// DEPENDANCIES:

// Check for embedded.mobileprovision in current working directory
print("######### Checking for dependancies #########")
print("")
print("Looking for file: embedded.mobileprovision")

let embeddedmobileprovisionPath = "embedded.mobileprovision"
if (!NSFileManager.defaultManager().fileExistsAtPath(embeddedmobileprovisionPath)){
    print("ERROR MSG: Could not find file: embedded.mobileprovision. Place a copy in the current working directory.")
    exit(1)
} else { print("- Found file: embedded.mobileprovision") }

// Create temp.plist from embedded.mobileprovision
// cmd: security cms -D -i embedded.mobileprovision -o temp.plist

let tempPlistFile = "./temp.plist"
print("- Generating \(tempPlistFile) from embedded.mobileprovision")
commandOutput = executeCommand("/usr/bin/security", args: ["cms", "-D", "-iembedded.mobileprovision", "-otemp.plist"])

if (!NSFileManager.defaultManager().fileExistsAtPath(tempPlistFile)){
    print("ERROR MSG: Creation of \(tempPlistFile) file failed")
    if let errorMSG = commandOutput {
        print("tempPlistFile")
    }
    exit(1)
} else { print("-- Created file: \(tempPlistFile)") }

// Use plistbuddy to extract Entitlements:application-identifier from temp.plist.
// cmd: plistbuddy -c "Print Entitlements:application-identifier" ./tmp.plist

let applicationIdentifier = executeCommand("/usr/libexec/PlistBuddy", args: ["-c", "Print Entitlements:application-identifier", tempPlistFile])
print("-- Extracting Entitlements:application-identifier from \(tempPlistFile)")
if let appID = applicationIdentifier{
    print("-- Entitlements:application-identifier is \"\(appID)\" ")
} else {
    print("ERROR MSG: Could not extract Entitlements:application-identifier from \(tempPlistFile)")
    exit(1)
}


// Check for IPA file
// Was a IPA file specified in the arguments
var wasIPAFileSpecified: YesNo = .Undecided
var args = Process.arguments
print("Checking for IPA file specified on the command line")
// **************************** Test code REMOVE next line ****************************
//args.append("my.ipa")


var ipaFile: NSString = ""
if args.count < 2 {
    // No IPA file specified checking for a single IPA in the current working directory
    print("- No IPA file was specified")
    print("- Checking for a single IPA file in the directory")
    let ipaFileLsResults: NSString? = executeCommand("/bin/ls", args: ["*.ipa"])
    if let ipaFilesConcatinated = ipaFileLsResults {
        let ipaFiles: [NSString?] = ipaFilesConcatinated.componentsSeparatedByString(" ")
        if ipaFiles.count == 1 {
            if let FirstIpaFile = ipaFiles[0] {
                ipaFile = FirstIpaFile
                print("-- IPA file was found: \(ipaFile)")
                wasIPAFileSpecified = .No
            }
        }
    } else {
        print("-- No IPA file was found")
    }
} else {
    // IPA file specified shecking if it exists in the current directory
    ipaFile = args[1]
    print("- IPA file specified: \(ipaFile)")
    if (!NSFileManager.defaultManager().fileExistsAtPath(ipaFile as String)){
        print("ERROR MSG: IPA file \"\(ipaFile)\" specified, but was not found in the current working directory")
        exit(1)
    } else {
        print("-- IPA file: \(ipaFile) exists")
        wasIPAFileSpecified = .Yes
    }
}


// Does the Payload directory exists? If so, should we remove it?
var shouldRemovePayload: YesNo = .Undecided
let payloadDirectoryPath = "./Payload"
print("Cecking for a preexisting \(payloadDirectoryPath) directory")
if (NSFileManager.defaultManager().fileExistsAtPath(payloadDirectoryPath))
{
    print("- The \(payloadDirectoryPath) directry already exists.")
    if wasIPAFileSpecified == .Yes {
        shouldRemovePayload = .Yes
    }
    
    while shouldRemovePayload == .Undecided {
        print("Should I remove it? Answering \"no\" will attempt to sign whats in the existing directoy there:")
        let removePayload = input()
        switch removePayload.lowercaseString.substringToIndex(removePayload.startIndex.successor()) {
            case "y":
                shouldRemovePayload = .Yes
            case "n":
                shouldRemovePayload = .No
            default:
                print("TEST MSG: You chose Wrong! Try Again (Yes/No)")
                continue
        }
    }

    // Remove the Payload directory if we need to
    if shouldRemovePayload == .Yes {
        print("-- Removing the existing Payload directory")
        let rmdirPayload: NSString? = executeCommand("/bin/rm", args: ["-rf", "Payload"])
    } else {
        if ipaFile.length < 1 {
            print("ERROR MSG: No IPA file was found and you you chose to delete the preexisting Payload directory. There is nothing to sign.")
            exit(1)
        }
    }
}

// If there is no Payload directory extract (unzip) IPA file
// CMD: unzip -q <file>
if shouldRemovePayload == .Undecided && ipaFile.length < 1 {
    print("ERROR MSG: No IPA file or Payload directory was found. There is nothing to sign.")
    exit(1)
} else {
    print("Unarchiving IPA file: \(ipaFile)")
    let unzipIpaFile: NSString? = executeCommand("/usr/bin/unzip", args: ["-q", ipaFile as String])
    if (!NSFileManager.defaultManager().fileExistsAtPath(payloadDirectoryPath)) {
        print("ERROR MSG: Could not unzip \(ipaFile). Expected to create a \"Payload\" directory")
        if let errorMSG = unzipIpaFile {
            print("unzipIpaFile")
        }
    } else {
        print("- IPA file \(ipaFile) unziped")
    }
}

// Get application directory name
// CMD ls -d ./Payload/*.app

var appDirectoryName: NSString?
var appName: NSString = "empty"
var foundAppDirectory: YesNo = .Undecided
print("Looking for the .app directory name")
commandOutput = executeCommand("/bin/ls", args: ["./Payload"])
// Did ls return anything?
if let payloadDirectoryListing = commandOutput {
    // Did ls return multiple listings
    let payloadDirectoryListingRecords: [NSString] = payloadDirectoryListing.componentsSeparatedByString("\n")
    for i in 0..<payloadDirectoryListingRecords.count {
        let fileRecord: NSString? = payloadDirectoryListingRecords[i]
        if let file = fileRecord {
            let fileComponents: [NSString] = file.componentsSeparatedByString(".")
            if fileComponents.count > 1 {
                let fileExt: NSString? = fileComponents.last
                if let ext = fileExt {
                    if ext == "app" {
                        let fileName: NSString? = fileComponents[0]
                        if let fileName = fileName {
                            appName = fileName
                            print("- Setting the application directory name to :\(appName)")
                            foundAppDirectory = .Yes
                        }
                    }

                }
                
            }
        }
    }
    
    if foundAppDirectory == .Yes {
        print("- The application directory name is :\(appName)")
    } else {
        print("ERROR MSG: Could not find the .app directory in the Payload directory.")
        exit(1)
    }
} else {
    print("ERROR MSG: Could not list the Payload directory contents.")
    exit(1)
}

// Copy embedded.mobileprovision into .app directory
// CMD: cp embedded.mobileprovision ./Payload/*.app/embedded.mobileprovision
let embeddedMobileprovisionTarget = "./Payload/\(appName).app/embedded.mobileprovision"
print("Copying embedded.mobileprovision into .app directory \(embeddedMobileprovisionTarget)")

if (NSFileManager.defaultManager().fileExistsAtPath(embeddedMobileprovisionTarget)) {
    print("- existing embedded.mobileprovision found")
    commandOutput = executeCommand("/bin/rm", args: [embeddedMobileprovisionTarget])
    if (NSFileManager.defaultManager().fileExistsAtPath(embeddedMobileprovisionTarget)) {
        print("ERROR MSG: Could not remove the existing embedded.mobileprovision")
        exit(1)
    } else {
        print("-- existing embedded.mobileprovision removed")
    }
}

commandOutput = executeCommand("/bin/cp", args: ["embedded.mobileprovision", embeddedMobileprovisionTarget])
if (!NSFileManager.defaultManager().fileExistsAtPath(embeddedMobileprovisionTarget)) {
    print("ERROR MSG: Could not copy embedded.mobileprovision")
    if let errorMSG = commandOutput {
        print(errorMSG)
    }
    exit(1)
} else {
    print("- embedded.mobileprovision copied into .app directory ")
}

// Check for the Info.plist file and BundleID
// CMD: plistbuddy -c "Print CFBundleIdentifier" ./Payload/*.app/Info.plist

let infoFilePath = "./Payload/\(appName).app/Info.plist"
print("Checking the current CFBundleIdentifier found it file: \(infoFilePath)")

var startingBundleID: NSString = getCFBundleIdentifier(infoFilePath)

// Update bundleID with embedded.mobileprovision information

print("Updating the CFBundleIdentifier in Info.plist with Entitlements:application-identifier information")
let wildCardCheck = applicationIdentifier!.componentsSeparatedByString("\n")[0].componentsSeparatedByString(".").last
var newApplicationIdentifierArray: [NSString] = applicationIdentifier!.componentsSeparatedByString(".")
//var newApplicationIdentifier: String
if let wildCardCheckValue = wildCardCheck {
    if wildCardCheckValue == "*" {
        print("- embedded.mobileprovision specifies a wildcard application ID: \(applicationIdentifier!)")
        newApplicationIdentifierArray.removeLast()
        newApplicationIdentifierArray.removeFirst()
        newApplicationIdentifierArray.append(startingBundleID.componentsSeparatedByString("\n")[0].componentsSeparatedByString(".").last!)
        var newApplicationIdentifierNSArray: NSArray = newApplicationIdentifierArray
        var newApplicationIdentifier = newApplicationIdentifierNSArray.componentsJoinedByString(".")
        print("- Chaging the current CFBundleIdentifier \"\(startingBundleID)\" with \"\(newApplicationIdentifier)\"")
        commandOutput = executeCommand("/usr/libexec/PlistBuddy", args: ["-c", "Set CFBundleIdentifier \(newApplicationIdentifier)", infoFilePath])
        getCFBundleIdentifier(infoFilePath)
    } else {
        print("- embedded.mobileprovision does not specify a wildcard application ID")
        print("- Updating Info.plist with \(applicationIdentifier!)")
        commandOutput = executeCommand("/usr/libexec/PlistBuddy", args: ["-c", "Set CFBundleIdentifier \(applicationIdentifier!)", infoFilePath])
    }
    commandOutput = executeCommand("/usr/libexec/PlistBuddy", args: ["-c", "Print CFBundleIdentifier", infoFilePath])
    
} else {
    print("ERROR MSG: Can't parse applicationIdentifier \"\(applicationIdentifier)\"")
    exit(1)
}

// Remove any previous signing
let codeSignaturePath = "./Payload/\(appName).app/_CodeSignature"
if NSFileManager.defaultManager().fileExistsAtPath(codeSignaturePath) {
    print("Removing any previous code signatures: \(codeSignaturePath)")
    commandOutput = executeCommand("/bin/rm", args: ["-r", codeSignaturePath])
    if (NSFileManager.defaultManager().fileExistsAtPath(codeSignaturePath)) {
        print("ERROR MSG: Could not remove signature")
        print("\(commandOutput)")
        exit(1)
    } else {
        print("- Removed \"\(codeSignaturePath)\"")
    }
}

// Create entitlements.xml

var newEntitlements: String = "\u{000A}"
commandOutput = executeCommand("/usr/libexec/PlistBuddy", args: ["-x", "-c", "Print Entitlements", tempPlistFile])

if let entitlements = commandOutput {
    newEntitlements += entitlements as String
    newEntitlements += "\u{000A}"
    //print("-- New Entitlements are \"\(newEntitlements)\" ")
}  else {
    print("ERROR MSG: Could not extract Entitlements from \(tempPlistFile)")
    exit(1)
}

let file = "./entitlements.xml" //this is the file. we will write to and read from it

let text = newEntitlements //just a text

if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
    //let path = dir.stringByAppendingPathComponent(file);
    let path = file
    //writing
    do {
        try text.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
    }
    catch {/* error handling here */}
    
    //reading
//    do {
//        let text2 = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
//    }
//    catch {/* error handling here */}
}

// Check for for signing certificates in the keychain
print("")
print("The following signing certificates are available:")
print("")
commandOutput = executeCommand("/usr/bin/security", args: ["find-identity", "-pcodesigning", "-v"])
if let cmdOutput = commandOutput {
    //print("\(cmdOutput)")
}

// Count the number of certs in the returned security command
certificates = commandOutput!.componentsSeparatedByString("\n")
certificates.removeLast()
certificates.removeLast()
let certCount = certificates.count
let whiteSpaceChar: NSCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
var certificateRecord: [String]
var appleTeamID: NSString
// Ask which certificate to use
var signingCertIdx: Int = 9999999
if certCount != 0 {
    print("\(commandOutput!)")
    print("Which certificate should we use? (Enter 1 - \(certCount))")
    var finalDecisionMade: YesNo = .Undecided
    
    while finalDecisionMade == .Undecided {
    // Make sure we are recieving a numeric idx in the correct range
        repeat {
            let nonNumericCharacterSet = NSCharacterSet.decimalDigitCharacterSet()
            var signingCertIdxStringRaw: NSString? = input()
            if let signingCertIdxString = signingCertIdxStringRaw {
                var certChoice = signingCertIdxString.componentsSeparatedByCharactersInSet(nonNumericCharacterSet.invertedSet).joinWithSeparator("")
                if let currentSigningCertIdx = Int(certChoice) {
                    signingCertIdx = currentSigningCertIdx
                }
            }
        } while signingCertIdx > certCount || signingCertIdx < 1
        certificateRecord = certificates[(signingCertIdx - 1)].componentsSeparatedByCharactersInSet(whiteSpaceChar)
        var teamIDField = certificateRecord.last
        if let str = teamIDField {
            var teamID: NSString? = str.substringWithRange(str.startIndex.advancedBy(1)..<str.endIndex.advancedBy(-2))
            if let ID = teamID {
                print("TeamID: \(ID)")
                appleTeamID = ID
                var teamIDCheck = applicationIdentifier!.componentsSeparatedByString(".").first
                if let ID = teamIDCheck {
                if appleTeamID != ID {
                    print("")
                    print("The TeamID from this signing certificate \"\(appleTeamID)\" does not match what was listed in the CFBundleIdentifier from the embedded.mobileprovision file \"\(applicationIdentifier!)\".")
                    var shouldContinue: YesNo = .Undecided
                    while shouldContinue == .Undecided {
                        print("Do you with to continue signing with this certificate?")
                        let removePayload = input()
                        switch removePayload.lowercaseString.substringToIndex(removePayload.startIndex.successor()) {
                            case "y":
                                shouldContinue = .Yes
                                finalDecisionMade = .Yes
                            case "n":
                                shouldContinue = .No
                                print("Which certificate should we use? (Enter 1 - \(certCount))")
                            default:
                                print("ERROR MSG: You chose Wrong! Try Again (Yes/No)")
                                continue
                        }
                    }
                } else {
                    finalDecisionMade = .Yes
                }
                    
                }
            }
        }
    }
} else {
    print("ERROR MSG: No Signing certificates were found in your keychain. \nCommand: /usr/bin/security find-identity -pcodesigning -v")
    exit(1)
}

let signingKey: NSString = certificates[(signingCertIdx - 1)].componentsSeparatedByCharactersInSet(whiteSpaceChar)[3]
let chosenKeyNumber = certificates[(signingCertIdx - 1)].componentsSeparatedByCharactersInSet(whiteSpaceChar)[2].componentsSeparatedByString(")")[0]

print("")
print("Your Signing key is: \(signingKey)")
//print("Your chosenKeyNumber key is: \(chosenKeyNumber)")
print("")


// Signing the application directory
let signField = "--sign=\(signingKey)"
let entitlementsField = "--entitlements=entitlements.xml"
let appField = "./Payload/\(appName).app"

print("Signing the application directory")
commandOutput = executeCommand("/usr/bin/codesign", args: ["--force", "-vvvv", signField, entitlementsField, appField])
if let  output = commandOutput {
    print(commandOutput!)
}

// Remove any previous signing
if NSFileManager.defaultManager().fileExistsAtPath(codeSignaturePath) {
    print("New signagure found: \(codeSignaturePath)")
} else {
    print("Something went wrong and the new signature could not be created: \(codeSignaturePath)")
}

// Packaging up the ne IPA 
// CMD: zip -qr resigned.ipa Payload

commandOutput = executeCommand("/usr/bin/zip", args: ["-qr", "resigned.ipa", "Payload"])
if let  output = commandOutput {
    print(commandOutput!)
}


