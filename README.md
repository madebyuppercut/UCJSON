# UCJSON

---

UCJSON is a generic JSON serialization library for use in iOS and macOS apps, employing a clean and flexible API.

## Installation
Simply download this repository and copy UCJSON.h & UCJSON.m into your project.

## Usage
Adopt the `UCJSONSerializable` protocol for objects that you will be serializing/deserializing (no subclassing required).
```
@interface SerializableClass : NSObject<UCJSONSerializable>
@property (nonatomic, strong) NSString *aString;
@property (nonatomic) NSInteger anInteger;
@end
```
#### Serializing
To serialize an object to a JSON model:
```
SerializableClass *obj = ...;
NSDictionary *json = [UCJSONSerialization JSONFromObject:obj];
```
To serialize an object directly to a JSON file:
```
SerializableClass *obj = ...;
NSString *filePath = ...;
NSError *error;
BOOL success = [UCJSONSerialization serializeObject:obj toFile:filePath: error:&error];
```
If you don't want to serialize directly to a file, you can write the JSON model object to a file at a later time:
```
SerializableClass *obj = ...;
NSDictionary *json = [UCJSONSerialization JSONFromObject:obj];

...

NSString *filePath = ...;
NSError *error;
BOOL success = [UCJSONSerialization writeJSON:json toFile:filePath error:&error];
```
#### Deserializing
To deserialize an object from a JSON model object:
```
NSDictionary *json = ...;
SerializableClass *obj = [UCJSONSerialization objectOfClass:[SerializableClass class] fromJSON:json];
```
If you already have an instance of the class that you wish to set or update with a JSON model object:
```
NSDictionary *json = ...;
SerializableClass *obj = ...;
BOOL success = [UCJSONSerialization setObject:obj fromJSON:json];
```
To directly deserialize an object from a JSON file:
```
NSString *filePath = ...;
NSError *error;
SerializableClass *obj = [UCJSONSerialization deserializeObjectOfClass:[SerializableClass class] fromFile:filePath error:&error];
```
To load a JSON model object from a file:
```
NSString *filePath = ...;
NSError *error;
NSDictionary *json = [UCJSONSerialization JSONFromFile:filePath error:&error];
```
## Advanced
UCJSON automatically handles the following types:
- `NSString` & `NSMutableString`
- `NSNumber`
- `NSDate`
- `NSData` & `NSMutableData`
- `NSArray` & `NSMutableArray`
- `NSDictionary` & `NSMutableDictionary`
- `BOOL` & `bool`
- `char` & `unsigned char`
- `int` (`NSInteger` on 32-bit platforms) & `unsigned int` (`NSUInteger` on 32-bit platforms)
- `long` (`NSInteger` on 64-bit platforms) & `unsigned long` (`NSUInteger` on 64-bit platforms)
- `long long` & `unsigned long long`
- `float` (`CGFloat` on 32-bit platforms)
- `double` (`CGFloat` on 32-bit platforms)
- objects that conform to `UCJSONSerializable`

#### Instance variables
By default, instance variables are included in serialization/deserialization. e.g.:
```
@implementation MyClass {
    NSInteger _aValue;
}
```
`_aValue` will be serialized as "aValue". This can be ignored by implementing `-doNotSerialize` (see below for details).

#### Arrays
Arrays must be a homogenous collection of supported types. If an array contains custom objects conforming to `UCJSONSerializable`, implement the `-classForArrayElementsOfProperty:` method from the `UCJSONSerializable` protocol:
```
- (Class)classForArrayElementsOfProperty:(NSString *)property {
    if ([property isEqualToString:@"anArray"]) {
        return [AClass class];
    }
    return NULL;
}
```
If an array does not contain a homogeneous collection of objects, it can still be serialized using a value transformer by implementing `-valueTransformerForProperty:`.

#### Dictionaries
Dictionaries must use `NSString`s for keys. Values, like arrays, can be any supported type. If a value in a dictionary is a custom class conforming to `UCJSONSerializable`, implement the `-classForDictionaryObjectWithKeyPath:` method:
```
- (Class)classForDictionaryObjectWithKeyPath:(NSString *)keyPath {
    NSArray<NSString*> *kpComponents = [keyPath componentsSeparatedByString:@"."];
    if (kpComponents.count == 2 && [kpComponents.firstObject isEqualToString:@"aDictionary"]) {
        NSString *key = kpComponents.lastObject;
        if ([key isEqualToString:@"foo"]) {
            return [Foo class];
        }
    }
    return nil;
}
```

#### C types
C `struct`s and `union`s are handled but require the object to implement the `-valueTransformerForProperty:` method from the `UCJSONSerializable` protocol:
```
- (NSValueTransformer *)valueTransformerForProperty:(NSString *)property {
    if ([property isEqualToString:@"aStruct"]) {
        AStructValueTransformer *transformer = [AStructValueTransformer new];
        return transformer;
    }
    return nil;
}
```
For an example of creating an `NSValueTransformer` subclass, see the `UCStructValueTransformer` class used by `UCSerializableObject` in the unit tests. There are also 2 value transformers included in UCJSON.h/UCJSON.m: one for transforming `NSDate` objects into Unix time, and another for serializing `NSRange` values.

#### Dates
By default, `NSDate` properties are serialized as strings using the RFC 3339 profile of the ISO 8601 standard. To serialize using a different format or standard, implement the `-dateFormatterForDateProperty:` method:
```
- (NSDateFormatter *)dateFormatterForDateProperty:(NSString *)property {
    if ([property isEqualToString:@"aDate"]) {
        static NSDateFormatter *formatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            formatter = [NSDateFormatter new];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterNoStyle;
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_CA"];
        });
        return formatter;
    }
    return nil;
}
```

#### Key mapping
To serialize a property with a different key in the JSON model object, return its mapping in `-keyMap`, which maps the property's name (the key in the returned dictionary) to its serialization key (the corresponding value). e.g.:
```
- (NSDictionary<NSString*,NSString*> *)keyMap {
    return @{@"userName": @"user"};
}
```
In the above example, the property `userName` will be serialized as "user" in the JSON representation. When deserializing, it will map "user" back to `userName`.

#### Ignored properties
To ignore properties or instance variables from serialization, implement the `-doNotSerialize` method, returning a set of strings identifying the properties to ignore:
```
- (NSSet<NSString*> *)doNotSerialize {
    return [NSSet setWithObject:@"ignored"];
}
```

## License
UCJSON is released under the MIT license. See LICENSE for more details.
