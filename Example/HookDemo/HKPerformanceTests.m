//
//  HKPerformanceTests.m
//  HookDemo_Tests
//
//  Created by 与佳期 on 2020/10/27.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <Stinger/Stinger.h>
#import <Aspects/Aspects.h>

@interface TestClass : NSObject

- (void)methodO;

- (void)methodA;

- (void)methodS;

@end

@implementation TestClass

- (void)methodO {
    
}

- (void)methodA {
    
}

- (void)methodS {
    
}

@end


@implementation TestClass (HK)

+ (void)hk_MethodSwizzlingMethodO {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(methodO);
        SEL swizzledSelector = @selector(hook_methodO);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


- (void)hook_methodO {
    [self hook_methodO];
}

@end


@interface HKPerformanceTests : XCTestCase

@end

@implementation HKPerformanceTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testMethodSwizzlingHookMethodO {
    [TestClass hk_MethodSwizzlingMethodO];
    TestClass *object = [TestClass new];
    
    [self measureBlock:^{
        for (NSInteger i = 0; i < 1000000; i++) {
            [object methodO];
        }
    }];
}

- (void)testAspectHookMethodA {
    TestClass *object = [TestClass new];
    [object aspect_hookSelector:@selector(methodA) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
        
    } error:nil];
    //  [object aspect_hookSelector:@selector(methodA) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> params) {
    //
    //  } error:nil];
    
    [self measureBlock:^{
        for (NSInteger i = 0; i < 1000000; i++) {
            [object methodA];
        }
    }];
}

- (void)testStingerHookMethodS {
    TestClass *object = [TestClass new];
    [object st_hookInstanceMethod:@selector(methodS) option:STOptionBefore usingIdentifier:@"hook methodS before" withBlock:^(id<StingerParams> params) {
        
    }];
    //  [object st_hookInstanceMethod:@selector(methodS) option:STOptionAfter usingIdentifier:@"hook methodS After" withBlock:^(id<StingerParams> params) {
    //
    //  }];
    
    [self measureBlock:^{
        for (NSInteger i = 0; i < 1000000; i++) {
            [object methodS];
        }
    }];
}

@end
