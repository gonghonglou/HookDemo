//
//  HookDemoObj.h
//  HookDemo_Example
//
//  Created by Honglou Gong on 2020/10/7.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HookDemoObj : NSObject

- (void)loopLogWithCount:(NSInteger)count;

- (void)logString:(NSString *)string;

@property (nonatomic, copy) void (^testBlock)(void);

@end

NS_ASSUME_NONNULL_END
