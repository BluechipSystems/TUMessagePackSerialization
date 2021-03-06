//
//  TUMessagePackSerializationWritingTests.m
//  TUMessagePackSerializationTests
//
//  Created by David Beck on 8/22/13.
//  Copyright (c) 2013 ThinkUltimate. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <TUMessagePackSerialization/TUMessagePackSerialization.h>


@interface TUMessagePackSerializationWritingTests : XCTestCase

@end

@implementation TUMessagePackSerializationWritingTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)_testWritingWithValue:(id)value type:(NSString *)testType additionalTests:(void(^)(id result))additionalTests options:(TUMessagePackWritingOptions)options
{
    NSData *expectedData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:testType withExtension:@"msgpack"]];
    
    NSError *error = nil;
    NSData *result = [TUMessagePackSerialization dataWithMessagePackObject:value options:options error:&error];
    
    XCTAssertNil(error, @"Error reading %@: %@", testType, error);
    
    XCTAssertEqualObjects(result, expectedData, @"%@ value incorrect", testType);
    
    if (additionalTests != nil) {
        additionalTests(result);
    }
}

- (void)_testWritingWithValue:(id)value type:(NSString *)testType
{
    [self _testWritingWithValue:value type:testType additionalTests:nil options:0];
}

- (void)_testWritingPerformanceWithValue:(id)value additionalTests:(void(^)(id result))additionalTests options:(TUMessagePackWritingOptions)options
{
    [self measureBlock:^{
        NSData *result = [TUMessagePackSerialization dataWithMessagePackObject:value options:options error:NULL];
        
        if (additionalTests != nil) {
            additionalTests(result);
        }
    }];
}


#pragma mark - Fixint

- (void)testPositiveFixint
{
    [self _testWritingWithValue:@42 type:@"PositiveFixint"];
}

- (void)testNegativeFixint
{
    [self _testWritingWithValue:@-28 type:@"NegativeFixint"];
}


#pragma mark - UInt

- (void)testUInt8
{
    [self _testWritingWithValue:@250 type:@"UInt8"];
}

- (void)testUInt16
{
    [self _testWritingWithValue:@48516 type:@"UInt16"];
}

- (void)testUInt32
{
    [self _testWritingWithValue:@1299962209 type:@"UInt32"];
}

- (void)testUInt64
{
    [self _testWritingWithValue:@6223172016852725913 type:@"UInt64"];
}


#pragma mark - Int

- (void)testInt8
{
    [self _testWritingWithValue:@-100 type:@"Int8"];
}

- (void)testInt16
{
    [self _testWritingWithValue:@-200 type:@"Int16"];
}

- (void)testInt32
{
    [self _testWritingWithValue:@-1299962209 type:@"Int32"];
}

- (void)testInt64
{
    [self _testWritingWithValue:@-6223172016852725913 type:@"Int64"];
}


#pragma mark - Floating point

// float reading test will go here when we can create the test file some how

- (void)testDouble
{
    [self _testWritingWithValue:@5672562398523.6523 type:@"Double"];
}


#pragma mark - Bool

- (void)testPositiveTrue
{
    [self _testWritingWithValue:@YES type:@"True"];
}

- (void)testPositiveFalse
{
    [self _testWritingWithValue:@NO type:@"False"];
}


#pragma mark - Nil

- (void)testNil
{
    [self _testWritingWithValue:[NSNull null] type:@"Nil"];
}


#pragma mark - Strings

- (void)testFixstr
{
    [self _testWritingWithValue:@"test" type:@"Fixstr"];
}

// Str8 reading test will go here when we can create the test file some how

- (void)testStr16
{
    [self _testWritingWithValue:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tempus aliquet augue a scelerisque. Ut viverra velit nisl, sit amet convallis arcu iaculis id. Curabitur semper, nibh ut ornare hendrerit, orci massa facilisis velit, eget tincidunt enim velit non tellus. Class aptent taciti sociosqu ad litora torquent metus." type:@"Str16"];
}

- (void)testStr32
{
    NSString *testString = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Str32" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
    
    [self _testWritingWithValue:testString type:@"Str32"];
    
    [self _testWritingPerformanceWithValue:testString additionalTests:nil options:0];
}

- (void)testCString
{
    // because the encoder uses a special fast path for encoding NS/CFStrings that are stored as UTF8, we need special testing for the scenario
    
    CFStringRef utf8String = CFSTR("test");
    XCTAssert(CFStringGetCStringPtr(utf8String, kCFStringEncodingUTF8) != NULL, @"Test did not generate a UTF-8 string.");
    
    [self _testWritingWithValue:(__bridge NSString *)utf8String type:@"Fixstr"];
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            [TUMessagePackSerialization dataWithMessagePackObject:(__bridge id)(utf8String) options:0 error:NULL];
        }
    }];
    
    CFRelease(utf8String);
}

- (void)testUnicodeString
{
    // because the encoder uses a special fast path for encoding NS/CFStrings that are stored as UTF8, we need special testing for the scenario
    
    CFStringRef utf16String = CFBridgingRetain(@"\u1F603");
    XCTAssert(CFStringGetCStringPtr(utf16String, kCFStringEncodingUTF8) == NULL, @"Test did not generate a UTF-16 string.");
    
    
    
    NSError *error = nil;
    NSData *result = [TUMessagePackSerialization dataWithMessagePackObject:(__bridge id)(utf16String) options:0 error:&error];
    id object = [TUMessagePackSerialization messagePackObjectWithData:result options:TUMessagePackReadingAllowFragments error:&error];
    
    XCTAssertNil(error, @"Error writting %@: %@", utf16String, error);
    
    XCTAssertEqualObjects((__bridge id)(utf16String), object, @"Strings don't match after passing through MessagePack.");
    
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            [TUMessagePackSerialization dataWithMessagePackObject:(__bridge id)(utf16String) options:0 error:NULL];
        }
    }];
    
    
    CFRelease(utf16String);
}


#pragma mark - Bin

- (void)testBin8
{
    NSData *testData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Bin8" ofType:@"txt"]];
    
    [self _testWritingWithValue:testData type:@"Bin8"];
}

- (void)testBin16
{
    NSData *testData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Bin16" ofType:@"rtf"]];
    
    [self _testWritingWithValue:testData type:@"Bin16"];
}

- (void)testBin32
{
    NSData *testData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Bin32" ofType:@"pages"]];
    
    [self _testWritingWithValue:testData type:@"Bin32"];
}


#pragma mark - Array

- (void)testFixarray
{
    [self _testWritingWithValue:@[@1, @"b", @3.5] type:@"Fixarray"];
}

- (void)testArray16
{
    NSMutableArray *testArray = [[NSMutableArray alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 200; i++) {
        [testArray addObject:@(i)];
    }
    
    [self _testWritingWithValue:testArray type:@"Array16"];
}

- (void)testArray32
{
    NSMutableArray *testArray = [[NSMutableArray alloc] initWithCapacity:82590];
    for (NSUInteger i = 1; i <= 82590; i++) {
        [testArray addObject:@(i)];
    }
    
    [self _testWritingWithValue:testArray type:@"Array32"];
    
    [self _testWritingPerformanceWithValue:testArray additionalTests:nil options:0];
}


#pragma mark - Map (Dictionary)

// we use TUOrderedMap to test maps because NSDictionary would not preserve the order of keys and usually fail

- (void)testFixMap
{
    NSMutableDictionary *testMap = [[TUOrderedMap alloc] initWithCapacity:3];
    testMap[@"key"] = @"value";
    testMap[@"one"] = @1;
    testMap[@"float"] = @2.8;
    
    [self _testWritingWithValue:testMap type:@"Fixmap"];
}

- (void)testMap16
{
    NSMutableDictionary *testMap = [[TUOrderedMap alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 200; i++) {
        testMap[@(i)] = @(i + 100);
    }
    
    [self _testWritingWithValue:testMap type:@"Map16"];
}

- (void)testMap32
{
    NSMutableDictionary *testMap = [[TUOrderedMap alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 82590; i++) {
        testMap[@(i)] = @(i + 100);
    }
    
    [self _testWritingWithValue:testMap type:@"Map32"];
    
    [self _testWritingPerformanceWithValue:testMap additionalTests:nil options:0];
}

- (void)testMap32Unordered
{
    NSMutableDictionary *testMap = [[NSMutableDictionary alloc] initWithCapacity:200];
    for (NSUInteger i = 1; i <= 82590; i++) {
        testMap[@(i)] = @(i + 100);
    }
    
    [self _testWritingPerformanceWithValue:testMap additionalTests:nil options:0];
}


#pragma mark - Ext

// Ext writing test will go here when we can create the test file some how


#pragma mark - Test Twitter

// this is our 'real world' test that brings it all together
- (void)testTwitter
{
    // we feed the rsulting data back into the serializer rather than comparing it to set data because NSDictionary from the json file will not preserve the order
    
    NSData *twitterData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Twitter" withExtension:@"json"]];
    id twitter = [NSJSONSerialization JSONObjectWithData:twitterData options:0 error:NULL];
    
    NSError *error = nil;
    NSData *result = [TUMessagePackSerialization dataWithMessagePackObject:twitter options:0 error:&error];
    
    XCTAssertNil(error, @"Error writing Twitter: %@", error);
    
    id object = [TUMessagePackSerialization messagePackObjectWithData:result options:0 error:&error];
    
    XCTAssertNil(error, @"Error reading written Twitter: %@", error);
    
    XCTAssertEqualObjects(twitter, object, @"Twitter value incorrect");
    
    [self measureBlock:^{
        [TUMessagePackSerialization dataWithMessagePackObject:twitter options:0 error:NULL];
    }];
}

@end
