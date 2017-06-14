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

#import <Foundation/Foundation.h>
#import "UCJSON.h"


@class UCFoo;

struct _uc_struct {
    int num;
};
typedef struct _uc_struct UCStruct;

union _uc_union {
    char ch;
    int num;
};
typedef union _uc_union UCUnion;


#pragma mark - UCSerializableObject
@interface UCSerializableObject : NSObject<UCJSONSerializable>
// Strings
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableString *mutableName;

// Numbers and primitives
@property (nonatomic, strong) NSNumber *aNumber;
@property (nonatomic) NSInteger anInteger;
@property (nonatomic) BOOL aBool;
@property (nonatomic) bool aCBool;
@property (nonatomic) char aChar;
@property (nonatomic) short aShort;
@property (nonatomic) int anInt;
@property (nonatomic) long aLong;
@property (nonatomic) long long aLongLong;
@property (nonatomic) unsigned char aUChar;
@property (nonatomic) unsigned short aUShort;
@property (nonatomic) unsigned int aUInt;
@property (nonatomic) unsigned long aULong;
@property (nonatomic) unsigned long long aULongLong;
@property (nonatomic) float aFloat;
@property (nonatomic) double aDouble;

// Other object types
@property (nonatomic, strong) NSDate *aDate;
@property (nonatomic, strong) NSData *someData;
@property (nonatomic, strong) NSMutableData *someMutableData;

// Collections
@property (nonatomic, strong) NSArray *anArray;
@property (nonatomic, strong) NSMutableArray *aMutableArray;
@property (nonatomic, strong) NSDictionary *aDictionary;
@property (nonatomic, strong) NSMutableDictionary *aMutableDictionary;

// Custom objects
@property (nonatomic, strong) UCFoo *foo;

// Custom object collections
@property (nonatomic, strong) NSArray<UCFoo*> *aFooArray;
@property (nonatomic, strong) NSDictionary<NSString*,UCFoo*> *aFooDictionary;

// C types
@property (nonatomic) UCStruct aStruct;
@property (nonatomic) UCUnion aUnion;

// Value transforming
@property (nonatomic, strong) NSDate *unixDate;
@property (nonatomic, strong) NSDate *customDate;
@property (nonatomic) NSRange aRange;

// Ignored properties
@property (nonatomic, strong) NSString *ignored;

// Key mapping
@property (nonatomic, strong) NSString *alias;

// Instance variables
- (NSUInteger)getIvar;

@end


#pragma mark - UCFoo
@interface UCFoo : NSObject<UCJSONSerializable>
@property (nonatomic, strong) NSString *foo;

@end


#pragma mark - UCSubObject
@interface UCSubObject : UCSerializableObject
@property (nonatomic, strong) NSString *subString;

@end


#pragma mark - UCInvalidObject
@interface UCInvalidObject : NSObject
@property (nonatomic, strong) NSString *invalid;

@end


#pragma mark - UCInvalidPropertyObject
@interface UCInvalidPropertyObject : NSObject<UCJSONSerializable>
@property (nonatomic, strong) NSSet *aSet;

@end


#pragma mark - 
@interface UCStructValueTransformer : NSValueTransformer
@end

@interface UCUnionValueTransformer : NSValueTransformer
@end
