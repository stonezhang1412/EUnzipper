//
//  EUnzipper.swift
//  EUnzipper
//
//  Created by Stone Zhang on 10/19/15.
//  Copyright © 2015 Stone. All rights reserved.
//

import UIKit

/// Use class method 'createWithURL' or 'createWidthData' to create an instance
public class EUnzipper {
    private let data: NSData
    private let _bytes: UnsafePointer<UInt8>
    private let _cdirs: [String: CentralDirectory]
    public var fromURL: NSURL?
    public var toURL: NSURL?
    
    private init(data: NSData, _bytes: UnsafePointer<UInt8>, _cdirs: [String: CentralDirectory], fromURL: NSURL?, toURL: NSURL?) {
        self.data = data
        self._bytes = _bytes
        self._cdirs = _cdirs
        self.fromURL = fromURL
        self.toURL = toURL
    }
}

// MARK: interface
public extension EUnzipper {
    /// Create an unzipper with an URL, shortcut for 'createWithData'
    class func createWithURL(zipFileURL: NSURL) -> EUnzipper? {
        if let data = NSData(contentsOfURL: zipFileURL) {
            return createWithData(data, fromURL: zipFileURL)
        }
        
        return nil
    }
    
    /// Create an unzipper with given 'NSData'
    class func createWithData(data: NSData, fromURL url: NSURL? = nil) -> EUnzipper? {
        let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
        let len = data.length
        if let rec = EndRecord.findEndRecordInBytes(bytes, length: len),
            let dirs = CentralDirectory.findCentralDirectoriesInBytes(bytes, length: len, withEndRecrod: rec) {
                return EUnzipper(data: data, _bytes: bytes, _cdirs: dirs, fromURL: url, toURL: nil)
        }
        
        return nil
    }
    
    /// Retrive file names inside the zip
    var files: [String] {
        return Array(_cdirs.keys)
    }
    
    /// Test if 'file' exists
    func containsFile(file: String) -> Bool {
        return _cdirs[file] != nil
    }
    
    /// Get data for 'file'
    func dataForFile(file: String) -> NSData? {
        if let cdir = _cdirs[file] {
            return Uncompressor.uncompressWithCentralDirectory(cdir, fromBytes: _bytes)
        }
        
        return nil
    }
    
    /// Unzip files to url
    func unzipFilesToURL(url: NSURL) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        for filePath in _cdirs.keys {
            if let data = dataForFile(filePath) {
                let fullURL = url.URLByAppendingPathComponent(filePath)
                let folderURL = data == 0 ? fullURL: fullURL.URLByDeletingLastPathComponent
                if !fileManager.fileExistsAtPath((folderURL?.path)!) {
                    do {
                        try fileManager.createDirectoryAtURL(folderURL!, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                        NSLog("Unable to create directory \(error.debugDescription)")
                    }
                }
                if data.length != 0 {
                    if !fileManager.createFileAtPath(fullURL.path!, contents: data, attributes: nil) {
                        return false
                    }
                }
            } else {
                return false
            }
        }
        
        toURL = url
        return true
    }
    
    
}

// MARK: subscription
public extension EUnzipper {
    
    subscript(file: String) -> NSData? {
        if let url = toURL {
            let fullURL = url.URLByAppendingPathComponent(file)
            let fileManager = NSFileManager.defaultManager()
            var isDir : ObjCBool = false
            if fileManager.fileExistsAtPath(fullURL.path!, isDirectory:&isDir) {
                if isDir {
                    // file exists and is a directory
                    return nil
                } else {
                    // file exists and is not a directory
                    let data: NSData? = NSData(contentsOfURL: fullURL)
                    
                    if let fileData = data {
                        return fileData
                    }
                    
                }
            } else {
                // file does not exist
                return nil
            }
        }
        return dataForFile(file)
    }
    
}