//
//  EUnzipper.swift
//  EUnzipper
//
//  Created by Stone Zhang on 10/19/15.
//  Copyright © 2015 Stone. All rights reserved.
//

import Foundation

/// Use static method `createWithURL` or `createWithData` to create an instance
public struct EUnzipper {
    
    let data: NSData
    
    private let _bytes: UnsafePointer<UInt8>
    
    private let _cdirs: [String: CentralDirectory]
    
}

public extension EUnzipper {
    
    /// Create an unzipper with an URL, shortcut for `createWithData`
    static func createWithURL(zipFileURL: NSURL) -> EUnzipper? {
        if let data = NSData(contentsOfURL: zipFileURL) {
            return createWithData(data)
        }
        
        return nil
    }
    
    /// Create an unzipper with given `NSData`
    static func createWithData(data: NSData) -> EUnzipper? {
        let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
        let len = data.length
        if let rec = EndRecord.findEndRecordInBytes(bytes, length: len),
            let dirs = CentralDirectory.findCentralDirectoriesInBytes(bytes, length: len, withEndRecrod: rec) {
                return EUnzipper(data: data, _bytes: bytes, _cdirs: dirs)
        }
        
        return nil
    }
    
    /// Retrive file names inside the zip
    var files: [String] {
        return Array(_cdirs.keys)
    }
    
    /// Test if `file` exists
    func containsFile(file: String) -> Bool {
        return _cdirs[file] != nil
    }
    
    /// Get data for `file`
    func dataForFile(file: String) -> NSData? {
        if let cdir = _cdirs[file] {
            return Uncompressor.uncompressWithCentralDirectory(cdir, fromBytes: _bytes)
        }
        
        return nil
    }
    
}

// MARK: subscription
public extension EUnzipper {
    
    subscript(file: String) -> NSData? {
        return dataForFile(file)
    }
    
}