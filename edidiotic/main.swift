//
//  main.swift
//  edidiotic
//
//  Created by Will Alexander on 10/11/21.
//

import Foundation
import IOKit

enum EdidioticError: Error {
    case ioServiceLookupError(kern_return_t)
}

let matching = IOServiceMatching("AppleDisplay")
var iterator = io_iterator_t()
let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator)

if result != KERN_SUCCESS {
    throw EdidioticError.ioServiceLookupError(result)
}

var service = IOIteratorNext(iterator)

while service != 0 {
    let info = IODisplayCreateInfoDictionary(
        service,
        UInt32(kIODisplayOnlyPreferredName)
    ).takeRetainedValue() as! [String: AnyObject]
    
    let displayProductNames = info["DisplayProductName"] as! [String: String]
    let displayProductName = displayProductNames[Locale.current.identifier]!
    print("Found display \(displayProductName)...")
    let vendorID = info["DisplayVendorID"] as! Int
    let productID = info["DisplayProductID"] as! Int
    var edid = info["IODisplayEDID"] as! Data
    
    enum DisplayType: UInt8 {
        static let mask: UInt8 = 0b00011000
        case monochromeOrGrayscale = 0b00000000
        case rgbColor = 0b00001000
        case nonRGBMulticolor = 0b00010000
        case undefined = 0b00011000
    }
    
    let displayType = DisplayType(rawValue: edid[0x18] & DisplayType.mask) ?? .undefined
    
    if displayType != .rgbColor {
        print("Changing display type from \(displayType) to \(DisplayType.rgbColor)...")
        edid[0x18] = (edid[0x18] & ~DisplayType.mask) | (DisplayType.rgbColor.rawValue & DisplayType.mask)
    }
    
    let extensionFlag = edid[0x7e]
    
    if extensionFlag != 0 {
        print("Removing \(extensionFlag) extension block(s)...")
        edid[0x7e] = 0
        edid = edid[..<0x80]
    }
    
    edid[0x7f] = 0x00 &- edid[..<0x7f].reduce(0x00, &+)

    let desktopURL = try FileManager.default.url(for: .desktopDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: true)
    
    let vendorURL = desktopURL.appendingPathComponent(String(format: "DisplayVendorID-%x", vendorID))
    try FileManager.default.createDirectory(at: vendorURL, withIntermediateDirectories: false)
    let productURL = vendorURL.appendingPathComponent(String(format: "DisplayProductID-%x", productID))
    
    let override = NSDictionary(dictionary: [
        "IODisplayEDID": edid,
        "DisplayProductName": displayProductName,
        "DisplayVendorID": vendorID,
        "DisplayProductID": productID,
    ])
    
    print("""
    Writing EDID override for display \(displayProductName) to \(productURL.path).
    Copy \(vendorURL.path) to /Library/Displays/Contents/Resources/Overrides/.
    Then, disconnect and reconnect your display.
    """)
    
    try override.write(to: productURL)
    service = IOIteratorNext(iterator)
}

IOObjectRelease(iterator)
