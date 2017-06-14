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
//  Created by Christian Floisand on 2017-06-09.
//

#import <XCTest/XCTest.h>
#import "UCSerializableObject.h"
#import "UCTests.h"


@interface UCJSONSerializationTestCase : XCTestCase
@property (nonatomic, strong) UCSerializableObject *serializableObject;
@end

@implementation UCJSONSerializationTestCase

- (void)setUp {
    [super setUp];
    self.serializableObject = [UCSerializableObject new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSerializeNilObject {
    NSDictionary *json = [UCJSONSerialization JSONFromObject:nil];
    XCTAssertNil(json, @"");
}

- (void)testSerializeInvalidObject {
    UCInvalidObject *invalidObject = [UCInvalidObject new];
    invalidObject.invalid = @"oops";
    NSDictionary *json = [UCJSONSerialization JSONFromObject:(id<UCJSONSerializable>)invalidObject];
    XCTAssertNil(json, @"");
}

- (void)testSerializeInvalidProperty {
    UCInvalidPropertyObject *invalidPropertyObject = [UCInvalidPropertyObject new];
    invalidPropertyObject.aSet = [NSSet setWithObject:@"foo"];
    NSDictionary *json = [UCJSONSerialization JSONFromObject:invalidPropertyObject];
    XCTAssertEqual(json.count, 0, @"");
}

#pragma mark - Strings
// ------------------------------------------------------------------------------------------

- (void)testSerializeString {
    NSString *testName = @"Uppercut";
    self.serializableObject.name = testName;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSString *serializedName = [json objectForKey:@"name"];
    XCTAssertNotNil(serializedName, @"");
    XCTAssertTrue([serializedName isEqualToString:testName], @"");
}

- (void)testSerializeMutableString {
    NSMutableString *testName = [NSMutableString stringWithString:@"Uppercut"];
    self.serializableObject.mutableName = testName;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSMutableString *serializedMutableName = [json objectForKey:@"mutableName"];
    XCTAssertNotNil(serializedMutableName, @"");
    XCTAssertTrue([serializedMutableName isKindOfClass:[NSMutableString class]], @"");
    XCTAssertTrue([serializedMutableName isEqualToString:testName], @"");
}

#pragma mark - Numbers and primitives
// ------------------------------------------------------------------------------------------

- (void)testSerializeNumber {
    NSNumber *testNumber = @(42);
    self.serializableObject.aNumber = testNumber;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSNumber *serializedNumber = [json objectForKey:@"aNumber"];
    XCTAssertNotNil(serializedNumber, @"");
    XCTAssertEqualObjects(serializedNumber, testNumber, @"");
}

- (void)testSerializeInteger {
    NSInteger testInteger = 42;
    self.serializableObject.anInteger = testInteger;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSInteger serializedInteger = [[json objectForKey:@"anInteger"] integerValue];
    XCTAssertEqual(serializedInteger, testInteger, @"");
}

- (void)testSerializeBool {
    BOOL testBool = YES;
    self.serializableObject.aBool = testBool;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    BOOL serializedBool = [[json objectForKey:@"aBool"] boolValue];
    XCTAssertEqual(serializedBool, testBool, @"");
}

- (void)testSerializeCBool {
    bool testBool = true;
    self.serializableObject.aCBool = testBool;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    bool serializedCBool = [[json objectForKey:@"aCBool"] boolValue];
    XCTAssertEqual(serializedCBool, testBool, @"");
}

- (void)testSerializeChar {
    char testChar = 'u';
    self.serializableObject.aChar = testChar;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    char serializedChar = [[json objectForKey:@"aChar"] charValue];
    XCTAssertEqual(serializedChar, testChar, @"");
}

- (void)testSerializeShort {
    short testShort = SHRT_MIN;
    self.serializableObject.aShort = testShort;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    short serializedShort = [[json objectForKey:@"aShort"] shortValue];
    XCTAssertEqual(serializedShort, testShort, @"");
}

- (void)testSerializeInt {
    int testInt = INT_MIN;
    self.serializableObject.anInt = testInt;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    int serializedInt = [[json objectForKey:@"anInt"] intValue];
    XCTAssertEqual(serializedInt, testInt, @"");
}

- (void)testSerializeLong {
    long testLong = LONG_MAX;
    self.serializableObject.aLong = testLong;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    long serializedLong = [[json objectForKey:@"aLong"] longValue];
    XCTAssertEqual(serializedLong, testLong, @"");
}

- (void)testSerializeLongLong {
    long long testLongLong = LONG_LONG_MIN;
    self.serializableObject.aLongLong = testLongLong;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    long long serializedLongLong = [[json objectForKey:@"aLongLong"] longLongValue];
    XCTAssertEqual(serializedLongLong, testLongLong, @"");
}

- (void)testSerializeUnsignedChar {
    unsigned char testUChar = '@';
    self.serializableObject.aUChar = testUChar;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    unsigned char serializedUChar = [[json objectForKey:@"aUChar"] unsignedCharValue];
    XCTAssertEqual(serializedUChar, testUChar, @"");
}

- (void)testSerializeUnsignedShort {
    unsigned short testUShort = USHRT_MAX;
    self.serializableObject.aUShort = testUShort;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    unsigned short serializedUShort = [[json objectForKey:@"aUShort"] unsignedShortValue];
    XCTAssertEqual(serializedUShort, testUShort, @"");
}

- (void)testSerializeUnsignedInt {
    unsigned int testUInt = UINT_MAX;
    self.serializableObject.aUInt = testUInt;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    unsigned int serializedUInt = [[json objectForKey:@"aUInt"] unsignedIntValue];
    XCTAssertEqual(serializedUInt, testUInt, @"");
}

- (void)testSerializeUnsignedLong {
    unsigned long testULong = ULONG_MAX;
    self.serializableObject.aULong = testULong;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    unsigned long serializedULong = [[json objectForKey:@"aULong"] unsignedLongValue];
    XCTAssertEqual(serializedULong, testULong, @"");
}

- (void)testSerializeUnsignedLongLong {
    unsigned long long testULongLong = ULONG_LONG_MAX;
    self.serializableObject.aULongLong = testULongLong;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    unsigned long long serializedULongLong = [[json objectForKey:@"aULongLong"] unsignedLongLongValue];
    XCTAssertEqual(serializedULongLong, testULongLong, @"");
}

- (void)testSerializeFloat {
    float testFloat = 3.14159265359f;
    self.serializableObject.aFloat = testFloat;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    float serializedFloat = [[json objectForKey:@"aFloat"] floatValue];
    XCTAssertEqualWithAccuracy(serializedFloat, testFloat, UCJSON_TESTS_FLOAT_ACCURACY, @"");
}

- (void)testSerializeDouble {
    double testDouble = 2.7182818284590451;
    self.serializableObject.aDouble = testDouble;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    double serializedDouble = [[json objectForKey:@"aDouble"] doubleValue];
    XCTAssertEqualWithAccuracy(serializedDouble, testDouble, UCJSON_TESTS_DOUBLE_ACCURACY, @"");
}

#pragma mark - Other object types
// ------------------------------------------------------------------------------------------

- (void)testSerializeDefaultDate {
    NSDate *testDate = [NSDate date];
    self.serializableObject.aDate = testDate;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDateFormatter *defaultDateFormatter = [UCJSONSerialization defaultDateFormatter];
    NSString *serializedDateString = [json objectForKey:@"aDate"];
    XCTAssertNotNil(serializedDateString, @"");
    XCTAssertTrue([serializedDateString isEqualToString:[defaultDateFormatter stringFromDate:testDate]], @"");
}

- (void)testSerializeCustomDate {
    NSDate *testDate = [NSDate date];
    self.serializableObject.customDate = testDate;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDateFormatter *dateFormatter = [self.serializableObject dateFormatterForDateProperty:@"customDate"];
    NSString *serializedCustomDateString = [json objectForKey:@"customDate"];
    XCTAssertNotNil(serializedCustomDateString, @"");
    XCTAssertTrue([serializedCustomDateString isEqualToString:[dateFormatter stringFromDate:testDate]], @"");
}

- (void)testSerializeData {
    const uint8_t bytes[] = {0xBA, 0xDC, 0xFF, 0xEE, 0xDA, 0xDA};
    NSData *testData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    self.serializableObject.someData = testData;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSData *serializedData = [[NSData alloc] initWithBase64EncodedString:[json objectForKey:@"someData"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    XCTAssertNotNil(serializedData, @"");
    XCTAssertTrue([serializedData isEqualToData:testData], @"");
}

- (void)testSerializeMutableData {
    const uint8_t bytes[] = {0xBA, 0xDC, 0xFF, 0xEE, 0xDA, 0xDA};
    NSMutableData *testData = [NSMutableData dataWithBytes:bytes length:sizeof(bytes)];
    self.serializableObject.someMutableData = testData;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSMutableData *serializedMutableData = [[NSMutableData alloc] initWithBase64EncodedString:[json objectForKey:@"someMutableData"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    XCTAssertNotNil(serializedMutableData, @"");
    XCTAssertTrue([serializedMutableData isKindOfClass:[NSMutableData class]], @"");
    XCTAssertTrue([serializedMutableData isEqualToData:testData], @"");
}

#pragma mark - Collections
// ------------------------------------------------------------------------------------------

- (void)testSerializeArray {
    NSArray *testArray = @[@"one", @"two", @"three"];
    self.serializableObject.anArray = testArray;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSArray *serializedArray = [json objectForKey:@"anArray"];
    XCTAssertNotNil(serializedArray, @"");
    XCTAssertEqualObjects(serializedArray, testArray, @"");
}

- (void)testSerializeMutableArray {
    NSMutableArray *testArray = [NSMutableArray arrayWithArray:@[@"red", @"green", @"blue"]];
    self.serializableObject.aMutableArray = testArray;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSMutableArray *serializedMutableArray = [json objectForKey:@"aMutableArray"];
    XCTAssertNotNil(serializedMutableArray, @"");
    XCTAssertTrue([serializedMutableArray isKindOfClass:[NSMutableArray class]], @"");
    XCTAssertEqualObjects(serializedMutableArray, testArray, @"");
}

- (void)testSerializeDictionary {
    NSDictionary *testDictionary = @{@"oneKey": @"one", @"twoKey": @"two", @"threeKey": @"three"};
    self.serializableObject.aDictionary = testDictionary;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDictionary *serializedDictionary = [json objectForKey:@"aDictionary"];
    XCTAssertNotNil(serializedDictionary, @"");
    XCTAssertEqualObjects(serializedDictionary, testDictionary, @"");
}

- (void)testSerializeMutableDictionary {
    NSMutableDictionary *testDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"redKey": @"red", @"greenKey": @"green", @"blueKey": @"blue"}];
    self.serializableObject.aMutableDictionary = testDictionary;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSMutableDictionary *serializedMutableDictionary = [json objectForKey:@"aMutableDictionary"];
    XCTAssertNotNil(serializedMutableDictionary, @"");
    XCTAssertTrue([serializedMutableDictionary isKindOfClass:[NSMutableDictionary class]], @"");
    XCTAssertEqualObjects(serializedMutableDictionary, testDictionary, @"");
}

#pragma mark - Custom objects
// ------------------------------------------------------------------------------------------

- (void)testSerializeCustomObject {
    UCFoo *foo = [UCFoo new];
    foo.foo = @"foo";
    self.serializableObject.foo = foo;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDictionary *serializedFoo = [json objectForKey:@"foo"];
    XCTAssertNotNil(serializedFoo, @"");
    XCTAssertTrue([[serializedFoo objectForKey:@"foo"] isEqualToString:@"foo"], @"");
}

#pragma mark - Custom object collections
// ------------------------------------------------------------------------------------------

- (void)testSerializeCustomObjectArray {
    UCFoo *foo1 = [UCFoo new]; foo1.foo = @"foo1";
    UCFoo *foo2 = [UCFoo new]; foo2.foo = @"foo2";
    UCFoo *foo3 = [UCFoo new]; foo3.foo = @"foo3";
    NSArray<UCFoo*> *fooArray = @[foo1, foo2, foo3];
    self.serializableObject.aFooArray = fooArray;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSArray *serializedFooArray = [json objectForKey:@"aFooArray"];
    XCTAssertNotNil(serializedFooArray, @"");
    [serializedFooArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XCTAssertTrue([[obj objectForKey:@"foo"] isEqualToString:fooArray[idx].foo], @"");
    }];
    
}

- (void)testSerializeCustomObjectDictionary {
    UCFoo *foo0 = [UCFoo new]; foo0.foo = @"foo0";
    UCFoo *foo1 = [UCFoo new]; foo1.foo = @"foo1";
    UCFoo *foo2 = [UCFoo new]; foo2.foo = @"foo2";
    NSDictionary<NSString*,UCFoo*> *fooDictionary = @{@"foo0": foo0, @"foo1": foo1, @"foo2": foo2};
    self.serializableObject.aFooDictionary = fooDictionary;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDictionary *serializedFooDictionary = [json objectForKey:@"aFooDictionary"];
    XCTAssertNotNil(serializedFooDictionary, @"");
    [serializedFooDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        XCTAssertTrue([[obj objectForKey:@"foo"] isEqualToString:[fooDictionary objectForKey:key].foo], @"");
    }];
}

#pragma mark - C types
// ------------------------------------------------------------------------------------------

- (void)testSerializeCStruct {
    UCStruct testStruct;
    testStruct.num = 99;
    self.serializableObject.aStruct = testStruct;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDictionary *serializedStruct = [json objectForKey:@"aStruct"];
    XCTAssertNotNil(serializedStruct, @"");
    XCTAssertEqual([serializedStruct[@"num"] intValue], testStruct.num, @"");
}

- (void)testSerializeCUnion {
    UCUnion testUnion;
    testUnion.ch = 'u';
    self.serializableObject.aUnion = testUnion;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDictionary *serializedUnion = [json objectForKey:@"aUnion"];
    XCTAssertNotNil(serializedUnion, @"");
    XCTAssertEqual([serializedUnion[@"ch"] charValue], testUnion.ch, @"");
}

#pragma mark - Value transforming
// ------------------------------------------------------------------------------------------

- (void)testSerializeValueTransformingDateToUnixTime {
    NSDate *testDate = [NSDate date];
    self.serializableObject.unixDate = testDate;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    double serializedUnixTime = [[json objectForKey:@"unixDate"] doubleValue];
    XCTAssertEqualWithAccuracy(serializedUnixTime, testDate.timeIntervalSince1970, UCJSON_TESTS_DOUBLE_ACCURACY, @"");
}

- (void)testSerializeRange {
    NSRange testRange = NSMakeRange(4, 512);
    self.serializableObject.aRange = testRange;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSDictionary *serializedRange = [json objectForKey:@"aRange"];
    XCTAssertNotNil(serializedRange, @"");
    XCTAssertTrue(serializedRange.allKeys.count == 2, @"");
    XCTAssertEqual([serializedRange[@"location"] integerValue], testRange.location, @"");
    XCTAssertEqual([serializedRange[@"length"] integerValue], testRange.length, @"");
}

#pragma mark - Ignored properties
// ------------------------------------------------------------------------------------------

- (void)testSerializeIgnoredProperty {
    NSString *ignoredString = @"nothing";
    self.serializableObject.ignored = ignoredString;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    XCTAssertNil([json objectForKey:@"ignored"], @"");
}

#pragma mark - Key mapping
// ------------------------------------------------------------------------------------------

- (void)testSerializeKeyMapping {
    NSString *aliasString = @"alias";
    self.serializableObject.alias = aliasString;
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    XCTAssertNil([json objectForKey:@"alias"], @"");
    NSString *serializedAliasString = [json objectForKey:self.serializableObject.keyMap[@"alias"]];
    XCTAssertNotNil(serializedAliasString, @"");
    XCTAssertTrue([serializedAliasString isEqualToString:aliasString], @"");
}

#pragma mark - Instance variables
// ------------------------------------------------------------------------------------------

- (void)testSerializeInstanceVariable {
    NSDictionary *json = [UCJSONSerialization JSONFromObject:self.serializableObject];
    
    XCTAssertNotNil(json, @"");
    NSUInteger serializedIvar = [[json objectForKey:@"anIvar"] integerValue];
    XCTAssertEqual(serializedIvar, [self.serializableObject getIvar], @"");
}

#pragma mark - Subclasses
// ------------------------------------------------------------------------------------------

- (void)testSerializeSubclass {
    UCSubObject *subObject = [UCSubObject new];
    subObject.subString = @"sub";
    subObject.name = @"super";
    NSDictionary *json = [UCJSONSerialization JSONFromObject:subObject];
    
    XCTAssertNotNil(json, @"");
    NSString *serializedSuperString = [json objectForKey:@"name"];
    NSString *serializedSubString = [json objectForKey:@"subString"];
    XCTAssertNotNil(serializedSuperString, @"");
    XCTAssertNotNil(serializedSubString, @"");
    XCTAssertTrue([serializedSuperString isEqualToString:subObject.name], @"");
    XCTAssertTrue([serializedSubString isEqualToString:subObject.subString], @"");
}

@end
