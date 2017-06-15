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
//  Created by Christian Floisand on 2016-07-28.
//

#import "UCJSON.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define IVAR_ADDR(type, ivar, obj) (type *)((__bridge void *)obj + ivar_getOffset(ivar))
#define IVAR(type, ivar, obj) *IVAR_ADDR(type, ivar, obj)

static NSDictionary<NSString*,NSString*>*
UCGetKeyMap(id<UCJSONSerializable> instance) {
    NSDictionary *keyMap = nil;
    if ([instance respondsToSelector:@selector(keyMap)]) {
        keyMap = [instance keyMap];
    }
    
    return keyMap;
}

static NSSet<NSString*>*
UCGetDoNotSerializeSet(id<UCJSONSerializable> instance) {
    NSSet<NSString*> *doNotSerialize = [NSSet setWithObject:@"isa"]; // NOTE(christian): Exclude the "isa" ivar of NSObject.
    if ([instance respondsToSelector:@selector(doNotSerialize)]) {
        doNotSerialize = [doNotSerialize setByAddingObjectsFromSet:[instance doNotSerialize]];
    }
    
    return doNotSerialize;
}

static NSString*
UCIvarNameFromIvar(Ivar ivar) {
    NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
    if ([ivarName hasPrefix:@"_"]) {
        ivarName = [ivarName substringFromIndex:1];
    }
    
    return ivarName;
}

static Class
UCClassFromIvarType(const char *ivarType) {
    size_t len = strlen(ivarType);
    char *className = (char *)malloc(sizeof(char) * (len - 2));
    memcpy(className, (char *)ivarType + 2, len - 3);
    className[len-3] = '\0';
    Class class = objc_lookUpClass(className);
    free(className);
    
    return class;
}

static NSString*
UCGetSerializationKey(NSDictionary *keyMap, NSString *propertyName) {
    NSString *key = [keyMap objectForKey:propertyName];
    return key;
}

static NSDateFormatter*
UCDefaultDateFormatter() {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        // NOTE(christian): RFC 3339 date format.
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        formatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    });
    
    return formatter;
}

static NSDateFormatter*
UCGetDateFormatter(id<UCJSONSerializable> instance, NSString *propertyName) {
    NSDateFormatter *formatter = nil;
    if ([instance respondsToSelector:@selector(dateFormatterForDateProperty:)]) {
        formatter = [instance dateFormatterForDateProperty:propertyName];
    }
    if (!formatter) {
        formatter = UCDefaultDateFormatter();
    }
    
    return formatter;
}

static BOOL
UCIsClassMutable(Class class) {
    return ([class isSubclassOfClass:[NSMutableString class]] ||
            [class isSubclassOfClass:[NSMutableData class]] ||
            [class isSubclassOfClass:[NSMutableArray class]] ||
            [class isSubclassOfClass:[NSMutableDictionary class]]);
}


#pragma mark - Native types serialization
@interface NSString (UCJSONSerialization)
- (NSString *)__serialize;
- (NSString *)__deserialize;
- (NSDate *)__deserializeToNSDateWithInstace:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName;
- (NSData *)__deserializeToNSData;
@end
@implementation NSString (UCJSONSerialization)
- (NSString *)__serialize { return self; }
- (NSString *)__deserialize { return self; }
- (NSDate *)__deserializeToNSDateWithInstace:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName {
    NSDateFormatter *formatter = UCGetDateFormatter(instance, propertyName);
    return [formatter dateFromString:self];
}
- (NSData *)__deserializeToNSData {
    return [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}
@end

@interface NSNumber (UCJSONSerialization)
- (NSNumber *)__serialize;
- (NSNumber *)__deserialize;
@end
@implementation NSNumber (UCJSONSerialization)
- (NSNumber *)__serialize { return self; }
- (NSNumber *)__deserialize { return self; }
@end

@interface NSNull (UCJSONSerialization)
- (NSNull *)__serialize;
- (NSNull *)__deserialize;
@end
@implementation NSNull (UCJSONSerialization)
- (NSNull *)__serialize { return self; }
- (NSNull *)__deserialize { return self; }
@end

@interface NSDate (UCJSONSerialization)
- (NSString *)__serializeWithInstance:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName;
- (NSDate *)__deserialize;
@end
@implementation NSDate (UCJSONSerialization)
- (NSString *)__serializeWithInstance:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName {
    NSDateFormatter *formatter = UCGetDateFormatter(instance, propertyName);
    return [formatter stringFromDate:self];
}
- (NSDate *)__deserialize { return self; }
@end

@interface NSData (UCJSONSerialization)
- (NSString *)__serialize;
@end
@implementation NSData (UCJSONSerialization)
- (NSString *)__serialize { return [self base64EncodedStringWithOptions:0]; }
@end


#pragma mark - UCJSONSerialization
@implementation UCJSONSerialization

+ (id)__ivarValueFromIvar:(Ivar)ivar instance:(id)instance {
    id ivarValue;
    const char *ivarType = ivar_getTypeEncoding(ivar);
    char typeEncoding = *ivarType;
    switch (typeEncoding) {
        case 'c': ivarValue = [NSNumber numberWithChar:IVAR(char, ivar, instance)];      break;
        case 'i': ivarValue = [NSNumber numberWithInt:IVAR(int, ivar, instance)];        break;
        case 's': ivarValue = [NSNumber numberWithShort:IVAR(short, ivar, instance)];    break;
        case 'l': ivarValue = [NSNumber numberWithLong:IVAR(long, ivar, instance)];      break;
        case 'q': ivarValue = [NSNumber numberWithLongLong:IVAR(long long, ivar, instance)]; break;
        case 'C': ivarValue = [NSNumber numberWithUnsignedChar:IVAR(unsigned char, ivar, instance)]; break;
        case 'I': ivarValue = [NSNumber numberWithUnsignedInt:IVAR(unsigned int, ivar, instance)];   break;
        case 'S': ivarValue = [NSNumber numberWithUnsignedShort:IVAR(unsigned short, ivar, instance)];  break;
        case 'L': ivarValue = [NSNumber numberWithUnsignedLong:IVAR(unsigned long, ivar, instance)];    break;
        case 'Q': ivarValue = [NSNumber numberWithUnsignedLongLong:IVAR(unsigned long long, ivar, instance)]; break;
        case 'f': ivarValue = [NSNumber numberWithFloat:IVAR(float, ivar, instance)];    break;
        case 'd': ivarValue = [NSNumber numberWithDouble:IVAR(double, ivar, instance)];  break;
        case 'B': ivarValue = [NSNumber numberWithBool:IVAR(BOOL, ivar, instance)];     break;
            
        case '*':
        {
            // TODO(christian): Should char strings be supported due to the issue in deserializing them? See __setIvar below.
            NSAssert(NO, @"[UCJSONSerialization] Raw (char *) strings are unsupported at this time.");
            char **val = IVAR_ADDR(char*, ivar, instance);
            ivarValue = [NSString stringWithUTF8String:*val];
        } break;
            
        case '@':
        {
            ivarValue = object_getIvar(instance, ivar);
        } break;
            
        case '{':
        case '(': {
            // NOTE(christian): C struct or union.
            ivarValue = [NSValue valueWithBytes:IVAR_ADDR(void, ivar, instance) objCType:ivarType];
        } break;
            
        default:
            NSAssert(NO, @"[UCJSONSerialization] Unsupported type encoding.");
            break;
    }
    
    return ivarValue;
}

+ (id)__serializeObject:(id)obj withInstance:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName {
    if ([obj respondsToSelector:@selector(__serialize)]) {
        obj = [obj __serialize];
    } else if ([obj respondsToSelector:@selector(__serializeWithInstance:propertyName:)]) {
        obj = [obj __serializeWithInstance:instance propertyName:propertyName];
    } else {
        if ([obj isKindOfClass:[NSArray class]]) {
            obj = [self __serializeArray:obj withInstance:instance propertyName:propertyName];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            obj = [self __serializeDictionary:obj withInstance:instance propertyName:propertyName];
        } else if ([obj conformsToProtocol:@protocol(UCJSONSerializable)]) {
            NSMutableDictionary *subJson = [NSMutableDictionary dictionary];
            [self __serializeIvarsOfInstance:obj withClass:[obj class] jsonDictionary:&subJson];
            obj = subJson;
        } else {
            obj = nil;
        }
    }
    
    return obj;
}

+ (NSDictionary *)__serializeDictionary:(NSDictionary *)dictionary withInstance:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName {
    NSMutableDictionary *dictJson = [NSMutableDictionary dictionary];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSAssert([key isKindOfClass:[NSString class]], @"[UCJSONSerialization] Dictionary keys must be of type NSString.");
        obj = [self __serializeObject:obj withInstance:instance propertyName:propertyName];
        if (!obj) {
            obj = [NSNull null];
        }
        [dictJson setObject:obj forKey:key];
    }];
    
    return dictJson;
}

+ (NSArray *)__serializeArray:(NSArray *)array withInstance:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName {
    NSMutableArray *arrayJson = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj = [self __serializeObject:obj withInstance:instance propertyName:propertyName];
        if (!obj) {
            obj = [NSNull null];
        }
        [arrayJson addObject:obj];
    }];
    
    return arrayJson;
}

+ (void)__serializeIvarsOfInstance:(id<UCJSONSerializable>)instance withClass:(Class)class jsonDictionary:(NSMutableDictionary * __autoreleasing *)json {
    Class superclass = class_getSuperclass(class);
    if (superclass && superclass != [NSObject class]) {
        [self __serializeIvarsOfInstance:instance withClass:superclass jsonDictionary:json];
    }
    
    unsigned int ivarCount;
    Ivar *classIvars = class_copyIvarList(class, &ivarCount);
    
    if (ivarCount > 0) {
        NSDictionary *keyMap = UCGetKeyMap(instance);
        NSSet<NSString*> *doNotSerialize = UCGetDoNotSerializeSet(instance);
        
        for (unsigned int i = 0; i < ivarCount; ++i) {
            Ivar ivar = classIvars[i];
            NSString *ivarName = UCIvarNameFromIvar(ivar);
            if ([doNotSerialize member:ivarName] == nil) {
                id ivarValue = [self __ivarValueFromIvar:ivar instance:instance];
                
                if ([instance respondsToSelector:@selector(valueTransformerForProperty:)]) {
                    NSValueTransformer *transformer = [instance valueTransformerForProperty:ivarName];
                    if (transformer) {
                        ivarValue = [transformer transformedValue:ivarValue];
                    }
                }
                
                ivarValue = [self __serializeObject:ivarValue withInstance:instance propertyName:ivarName];
                if (ivarValue) {
                    NSString *key = UCGetSerializationKey(keyMap, ivarName);
                    if (!key) {
                        key = ivarName;
                    }
                    
                    [*json setObject:ivarValue forKey:key];
                }
            }
        }
    }
    
    free(classIvars);
}

+ (id)__deserializeNativeValue:(id)value toClass:(Class)class withInstance:(id<UCJSONSerializable>)instance propertyName:(NSString *)propertyName keyPath:(NSString *)keyPath {
    if ([value isKindOfClass:[NSString class]]) {
        if ([class isSubclassOfClass:[NSDate class]]) {
            value = [value __deserializeToNSDateWithInstace:instance propertyName:propertyName];
        } else if ([class isSubclassOfClass:[NSData class]]) {
            value = [value __deserializeToNSData];
        } else {
            NSAssert([class isSubclassOfClass:[NSString class]], @"[UCJSONSerialization] Native value class expected to be NSString.");
            value = [value __deserialize];
        }
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        value = [self __deserializeDictionary:value withPropertyName:propertyName instance:instance keyPath:keyPath];
    } else if ([value isKindOfClass:[NSArray class]]) {
        value = [self __deserializeArray:value withPropertyName:propertyName instance:instance];
    } else {
        value = [value __deserialize];
    }
    
    if (UCIsClassMutable(class) && ![value isEqual:[NSNull null]]) {
        value = [value mutableCopy];
    }
    
    return value;
}

+ (NSArray *)__deserializeArray:(NSArray *)arrayJson withPropertyName:(NSString *)propertyName instance:(id<UCJSONSerializable>)instance {
    NSMutableArray *array = [NSMutableArray array];
    id obj = arrayJson.firstObject;
    if (obj) {
        Class class = NULL;
        if ([instance respondsToSelector:@selector(classForArrayElementsOfProperty:)]) {
            class = [instance classForArrayElementsOfProperty:propertyName];
        }
        
        if (!class) {
            class = [obj class];
        }
        
        [arrayJson enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([class conformsToProtocol:@protocol(UCJSONSerializable)]) {
                obj = [self objectOfClass:class fromJSON:obj];
            } else {
                obj = [self __deserializeNativeValue:obj toClass:class withInstance:instance propertyName:propertyName keyPath:propertyName];
            }
            
            [array addObject:obj];
        }];
    }
    
    return array;
}

+ (NSDictionary *)__deserializeDictionary:(NSDictionary *)dictJson withPropertyName:(NSString *)propertyName instance:(id<UCJSONSerializable>)instance keyPath:(NSString *)keyPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dictJson enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSAssert([key isKindOfClass:[NSString class]], @"[UCJSONSerialization] Dictionary keys must be of type NSString.");
        Class class = NULL;
        if ([instance respondsToSelector:@selector(classForDictionaryObjectWithKeyPath:)]) {
            class = [instance classForDictionaryObjectWithKeyPath:[keyPath stringByAppendingFormat:@".%@", key]];
        }
        
        if (class && [class conformsToProtocol:@protocol(UCJSONSerializable)]) {
            obj = [self objectOfClass:class fromJSON:obj];
        } else {
            if (!class) {
                class = [obj class];
            }
            
            obj = [self __deserializeNativeValue:obj toClass:class withInstance:instance propertyName:propertyName keyPath:[keyPath stringByAppendingFormat:@".%@", key]];
        }
        
        [dict setObject:obj forKey:key];
    }];
    
    return dict;
}

+ (NSDictionary *)__deserializeDictionary:(NSDictionary *)dictJson withPropertyName:(NSString *)propertyName instance:(id<UCJSONSerializable>)instance {
    return [self __deserializeDictionary:dictJson withPropertyName:propertyName instance:instance keyPath:propertyName];
}

+ (void)__setIvar:(Ivar)ivar withValue:(id)value forInstance:(id)instance {
    const char *ivarType = ivar_getTypeEncoding(ivar);
    char typeEncoding = *ivarType;
    switch (typeEncoding) {
        case 'c': IVAR(char, ivar, instance) = [value charValue];      break;
        case 'i': IVAR(int, ivar, instance) = [value intValue];        break;
        case 's': IVAR(short, ivar, instance) = [value shortValue];    break;
        case 'l': IVAR(long, ivar, instance) = [value longValue];      break;
        case 'q': IVAR(long long, ivar, instance) = [value longLongValue];             break;
        case 'C': IVAR(unsigned char, ivar, instance) = [value unsignedCharValue];     break;
        case 'I': IVAR(unsigned int, ivar, instance) = [value unsignedIntValue];       break;
        case 'S': IVAR(unsigned short, ivar, instance) = [value unsignedShortValue];   break;
        case 'L': IVAR(unsigned long, ivar, instance) = [value unsignedLongValue];     break;
        case 'Q': IVAR(unsigned long long, ivar, instance) = [value unsignedLongLongValue]; break;
        case 'f': IVAR(float, ivar, instance) = [value floatValue];    break;
        case 'd': IVAR(double, ivar, instance) = [value doubleValue];  break;
        case 'B': IVAR(BOOL, ivar, instance) = [value boolValue];      break;
            
        case '*':
        {
            NSAssert(NO, @"[UCJSONSerialization] (char *) instance variables unsupported for deserialization at this time.");
            // TODO(christian): What should be done about the malloc here? Should it be assumed that the object will free char strings?
            // What if the char string is a const string? etc.
            // e.g. char *str;
            //      str = "string";
            const char *stringVal = [value UTF8String];
            char **val = IVAR_ADDR(char*, ivar, instance);
            *val = (char *)malloc(strlen(stringVal));
            memcpy(*val, stringVal, strlen(stringVal));
        } break;
            
        case '@':
        {
            Class class = UCClassFromIvarType(ivarType);
            NSString *ivarName = UCIvarNameFromIvar(ivar);
            
            if ([class conformsToProtocol:@protocol(UCJSONSerializable)]) {
                value = [self objectOfClass:class fromJSON:value];
            } else {
                value = [self __deserializeNativeValue:value toClass:class withInstance:instance propertyName:ivarName keyPath:ivarName];
            }
            
            object_setIvar(instance, ivar, value);
        } break;
            
        case '{':
        case '(': {
            // NOTE(christian): C struct or union.
            NSAssert([value isKindOfClass:[NSValue class]], @"[UCJSONSerialization] C types (structs & unions) must be contained in an NSValue object.");
            [value getValue:IVAR_ADDR(void, ivar, instance)];
        } break;
            
        default:
            NSAssert(NO, @"[UCJSONSerialization] Unsupported type encoding.");
            break;
    }
}

+ (void)__deserializeIvarsOfInstance:(id<UCJSONSerializable>)instance withClass:(Class)cl json:(NSDictionary *)json {
    Class superclass = class_getSuperclass(cl);
    if (superclass && superclass != [NSObject class]) {
        [self __deserializeIvarsOfInstance:instance withClass:superclass json:json];
    }
    
    NSDictionary *keyMap = UCGetKeyMap(instance);
    NSSet<NSString*> *doNotSerialize = UCGetDoNotSerializeSet(instance);
    
    unsigned int ivarCount;
    Ivar *classIvars = class_copyIvarList(cl, &ivarCount);
    
    for (unsigned int i = 0; i < ivarCount; ++i) {
        Ivar ivar = classIvars[i];
        NSString *ivarName = UCIvarNameFromIvar(ivar);
        if ([doNotSerialize member:ivarName] == nil) {
            NSString *key = UCGetSerializationKey(keyMap, ivarName);
            if (!key) {
                key = ivarName;
            }
            
            id obj = [json objectForKey:key];
            if (obj) {
                if ([instance respondsToSelector:@selector(valueTransformerForProperty:)]) {
                    NSValueTransformer *transformer = [instance valueTransformerForProperty:key];
                    NSAssert((transformer ? [[transformer class] allowsReverseTransformation] : YES), @"[UCJSONSerialization] Value transformers must allow reverse transformation.");
                    if (transformer && [[transformer class] allowsReverseTransformation]) {
                        obj = [transformer reverseTransformedValue:obj];
                    }
                }
                
                [self __setIvar:ivar withValue:obj forInstance:instance];
            }
        }
    }
    
    free(classIvars);
}

+ (NSDictionary *)JSONFromObject:(id<UCJSONSerializable>)object {
    NSMutableDictionary *json = nil;
    if (object && [object conformsToProtocol:@protocol(UCJSONSerializable)]) {
        json = [NSMutableDictionary dictionary];
        [self __serializeIvarsOfInstance:object withClass:[object class] jsonDictionary:&json];
        BOOL validJson = [NSJSONSerialization isValidJSONObject:json];
        if (!validJson) {
            json = nil;
        }
    }
    
    return json;
}

+ (id<UCJSONSerializable>)objectOfClass:(Class)class fromJSON:(NSDictionary *)json {
    id<UCJSONSerializable> object = nil;
    if (json && class) {
        object = [class new];
        BOOL success = [self setObject:object fromJSON:json];
        if (!success) {
            object = nil;
        }
    }
    
    return object;
}

+ (BOOL)setObject:(id<UCJSONSerializable>)object fromJSON:(NSDictionary *)json {
    BOOL success = NO;
    if (object && json) {
        BOOL validJson = [NSJSONSerialization isValidJSONObject:json];
        if (validJson) {
            BOOL validObject = [object conformsToProtocol:@protocol(UCJSONSerializable)];
            if (validObject) {
                [self __deserializeIvarsOfInstance:object withClass:[object class] json:json];
                success = YES;
            }
        }
    }
    
    return success;
}

+ (NSDictionary *)JSONFromFile:(NSString *)file error:(NSError * __autoreleasing *)error {
    return [self JSONFromFile:file withOptions:NSJSONReadingMutableContainers error:error];
}

+ (NSDictionary *)JSONFromFile:(NSString *)file withOptions:(NSJSONReadingOptions)options error:(NSError * __autoreleasing *)error {
    id json = nil;
    if (file) {
        NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:file];
        [inputStream open];
        
        if (inputStream.streamStatus == NSStreamStatusOpen) {
            NSError *jsonError;
            json = [NSJSONSerialization JSONObjectWithStream:inputStream options:0 error:&jsonError];
            if (!json || !([json isKindOfClass:[NSDictionary class]] || [json isKindOfClass:[NSArray class]])) {
                *error = jsonError;
                json = nil;
            }
            
            [inputStream close];
        } else {
            if (error) {
                *error = inputStream.streamError;
            }
        }
    }
    
    return json;
}

+ (BOOL)writeJSON:(NSDictionary *)json toFile:(NSString *)file error:(NSError * __autoreleasing *)error {
    return [self writeJSON:json toFile:file withOptions:NSJSONWritingPrettyPrinted error:error];
}

+ (BOOL)writeJSON:(NSDictionary *)json toFile:(NSString *)file withOptions:(NSJSONWritingOptions)options error:(NSError * __autoreleasing *)error {
    BOOL success = NO;
    if (json && file) {
        NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:file append:NO];
        [outputStream open];
        
        if (outputStream.streamStatus == NSStreamStatusOpen) {
            NSError *jsonError;
            NSInteger result = 0;
            
            @try {
                result = [NSJSONSerialization writeJSONObject:json toStream:outputStream options:options error:&jsonError];
            } @catch (NSException *exception) {
                if (error) {
                    NSDictionary *userInfo = nil;
                    if (exception.reason) {
                        userInfo = @{NSLocalizedDescriptionKey: exception.reason};
                    }
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:userInfo];
                }
            } @finally {
                if (result > 0) {
                    success = YES;
                } else if (error && (*error == nil)) {
                    *error = jsonError;
                }
                
                [outputStream close];
            }
            
        } else {
            if (error) {
                *error = outputStream.streamError;
            }
        }
    }
    
    return success;
}

+ (BOOL)serializeObject:(id<UCJSONSerializable>)object toFile:(NSString *)file error:(NSError * __autoreleasing *)error {
    NSDictionary *json = [self JSONFromObject:object];
    return [self writeJSON:json toFile:file error:error];
}

+ (id<UCJSONSerializable>)deserializeObjectOfClass:(Class)class fromFile:(NSString *)file error:(NSError * __autoreleasing *)error {
    NSDictionary *json = [self JSONFromFile:file error:error];
    return [self objectOfClass:class fromJSON:json];
}

+ (NSDateFormatter *)defaultDateFormatter {
    return UCDefaultDateFormatter();
}

@end


#pragma mark - UCDateToUnixTimeTransformer
@implementation UCDateToUnixTimeTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    NSNumber *unixTime = nil;
    if (value) {
        unixTime = [NSNumber numberWithDouble:[value timeIntervalSince1970]];
    }
    return unixTime;
}

- (id)reverseTransformedValue:(id)value {
    NSDate *date = nil;
    if (value) {
        date = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
    }
    return date;
}

@end


#pragma mark - UCRangeTransforer
@implementation UCRangeTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    NSDictionary *dictValue = nil;
    if (value) {
        NSRange range = [value rangeValue];
        dictValue = @{@"location": @(range.location), @"length": @(range.length)};
    }
    return dictValue;
}

- (id)reverseTransformedValue:(id)value {
    NSValue *rangeValue = nil;
    if (value) {
        NSRange range;
        range.location = [[value objectForKey:@"location"] unsignedIntegerValue];
        range.length = [[value objectForKey:@"length"] unsignedIntegerValue];
        rangeValue = [NSValue valueWithBytes:&range objCType:@encode(NSRange)];
    }
    return rangeValue;
}

@end
