//  MIT License
//
//  Copyright (c) 2017 Uppercut
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Christian Floisand on 2017-06-13.
//

#import <XCTest/XCTest.h>
#import "UCSerializableObject.h"


@interface UCJSONFileOperationsTestCase : XCTestCase
@property (nonatomic, strong) NSString *testsDir;
@end

@implementation UCJSONFileOperationsTestCase

- (void)setUp {
    [super setUp];
    
    // NOTE(christian): Environment variable set in target's scheme.
    const char *projectDir = getenv("PROJECT_DIR");
    self.testsDir = [[NSString stringWithUTF8String:projectDir] stringByAppendingPathComponent:@"Tests"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadValidJSONFile {
    NSError *error;
    NSString *filePath = [self.testsDir stringByAppendingPathComponent:@"Serialized.json"];
    NSDictionary *json = [UCJSONSerialization JSONFromFile:filePath error:&error];
    XCTAssertNotNil(json, @"");
    XCTAssertNil(error, @"");
}

- (void)testLoadUnknownJSONFile {
    NSError *error;
    NSString *filePath = [self.testsDir stringByAppendingString:@"Unknown.json"];
    NSDictionary *json = [UCJSONSerialization JSONFromFile:filePath error:&error];
    XCTAssertNil(json, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testLoadInvalidJSONFile {
    NSError *error;
    NSString *filePath = [self.testsDir stringByAppendingString:@"Invalid.json"];
    NSDictionary *json = [UCJSONSerialization JSONFromFile:filePath error:&error];
    XCTAssertNil(json, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testWriteValidJSONToFile {
    NSError *error;
    NSString *filePath = [self.testsDir stringByAppendingPathComponent:@"ValidOut.json"];
    BOOL success = [UCJSONSerialization writeJSON:@{@"foo": @"bar"} toFile:filePath error:&error];
    XCTAssertTrue(success, @"");
    XCTAssertNil(error, @"");
}

- (void)testWriteInvalidJSONToFile {
    NSError *error;
    NSString *filePath = [self.testsDir stringByAppendingPathComponent:@"InvalidOut.json"];
    BOOL success = [UCJSONSerialization writeJSON:@{@(0): @"zero"} toFile:filePath error:&error];
    XCTAssertFalse(success, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testWriteValidJSONToUnknownFilePath {
    NSError *error;
    NSString *filePath = [self.testsDir stringByAppendingPathComponent:@"/Unknown/Unknown.json"];
    BOOL success = [UCJSONSerialization writeJSON:@{@"foo": @"bar"} toFile:filePath error:&error];
    XCTAssertFalse(success, @"");
    XCTAssertNotNil(error, @"");
}

@end
