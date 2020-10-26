//
//  HookDemo.m
//  HookDemo
//
//  Created by Honglou Gong on 2020/9/25.
//

#import "HookDemo.h"

@implementation HookDemo

- (void)methodTestOne {
    [self logOne];
}

- (void)methodTestTwo {
    [self logTwo];
}


- (void)logOne {
    [self printSleep:2];
    sleep(2);
    
    int i = 1;
    while (i < 1000) {
        i++;
    }
    [self printCount:i];
}

- (void)logTwo {
    [self printSleep:3];
    sleep(3);

    int i = 1;
    while (i < 1000000) {
        i++;
    }
    [self printCount:i];
}

- (void)printSleep:(int)count {
    NSLog(@"---start sleep:%d", count);
}

- (void)printCount:(int)count {
    NSLog(@"---loop done! count:%d", count);
}

@end
