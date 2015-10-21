//
//  EUnzipperTests.swift
//  EUnzipperTests
//
//  Created by Stone Zhang on 10/19/15.
//  Copyright © 2015 Stone. All rights reserved.
//

import UIKit
import XCTest
import EUnzipper

class EUnzipperTests: XCTestCase {
    
    lazy var unzipper: EUnzipper! = {
        let b = NSBundle(forClass: EUnzipperTests.self)
        if let url = b.URLForResource("test", withExtension: "epub") {
            return EUnzipper.createWithURL(url)
        }
        
        return nil
        }()
    
    override func setUp() {
        super.setUp()
        
        XCTAssertTrue(unzipper != nil, "Can not create unzipper")
    }
    
    // info by zipdetails
    func testNumFiles() {
        XCTAssertEqual(unzipper.files.count, 0x1B, "number of files should be 0x1B")
    }
    
    func testFileExists() {
        XCTAssertTrue(unzipper.containsFile("OEBPS/text/book_0006.xhtml"), "OEBPS/text/book_0006.xhtml should be existed")
    }
    
    func testStoreData() {
        unzipper.toURL = nil
        if let data = unzipper["mimetype"] {
            if let str = NSString(data: data, encoding: NSUTF8StringEncoding) {
                XCTAssertEqual(str, "application/epub+zip", "data content should be `application/epub+zip`")
            } else {
                XCTFail("can't init string from data")
            }
        } else {
            XCTFail("can not get data")
        }
    }
    
    func testDeflateData() {
        unzipper.toURL = nil
        if let data = unzipper["META-INF/container.xml"] {
            let b = NSBundle(forClass: EUnzipperTests.self)
            let url = b.URLForResource("container", withExtension: "xml")!
            let expectedData = NSData(contentsOfURL: url)!
            XCTAssertEqual(data, expectedData, "data should be the same")
        } else {
            XCTFail("can not get data")
        }
    }
    
    func testUnzipFiles() {
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0]
        let folderName = "test"
        let unzipPath = "\(docsDir)/\(folderName)"
        let fm = NSFileManager.defaultManager()
        if unzipper.unzipFilesToURL(NSURL.fileURLWithPath(unzipPath)) {
            XCTAssertTrue(fm.fileExistsAtPath("\(unzipPath)/OEBPS/text/book_0006.xhtml"), "\(unzipPath)/OEBPS/text/book_0006.xhtml should be existed")
        } else {
            XCTFail("can not unzip files")
        }
    }
    
    func testDataFromUnzipFile() {
        if unzipper.toURL == nil {
            testUnzipFiles()
        }
        
        if let data = unzipper["mimetype"] {
            if let str = NSString(data: data, encoding: NSUTF8StringEncoding) {
                XCTAssertEqual(str, "application/epub+zip", "uncompressed data content should be `application/epub+zip`")
            } else {
                XCTFail("can't init string from uncompressed data")
            }
        } else {
                XCTFail("can not get data from uncompressed date")
        }
    }

}
