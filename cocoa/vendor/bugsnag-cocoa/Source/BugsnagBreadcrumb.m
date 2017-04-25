//
//  BugsnagBreadcrumb.m
//
//  Created by Delisa Mason on 9/16/15.
//
//  Copyright (c) 2015 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import "BugsnagBreadcrumb.h"
#import "BugsnagLogger.h"
#import "Bugsnag.h"

NSString *const BSGBreadcrumbDefaultName = @"manual";
NSUInteger const BSGBreadcrumbMaxByteSize = 4096;

NSString *BSGBreadcrumbTypeValue(BSGBreadcrumbType type) {
    switch (type) {
        case BSGBreadcrumbTypeLog:
            return @"log";
        case BSGBreadcrumbTypeUser:
            return @"user";
        case BSGBreadcrumbTypeError:
            return @"error";
        case BSGBreadcrumbTypeState:
            return @"state";
        case BSGBreadcrumbTypeManual:
            return @"manual";
        case BSGBreadcrumbTypeProcess:
            return @"process";
        case BSGBreadcrumbTypeRequest:
            return @"request";
        case BSGBreadcrumbTypeNavigation:
            return @"navigation";
    }
}

@interface BugsnagBreadcrumbs()

@property (nonatomic,readwrite,strong) NSMutableArray* breadcrumbs;
@property (nonatomic,readonly,strong) NSLock* lock;
@end

@interface BugsnagBreadcrumb ()

- (NSDictionary *_Nullable)objectValue;
@end

@implementation BugsnagBreadcrumb

- (instancetype)init {
    if (self = [super init]) {
        _timestamp = [NSDate date];
        _name = BSGBreadcrumbDefaultName;
        _type = BSGBreadcrumbTypeManual;
        _metadata = @{};
    }
    return self;
}

- (BOOL)isValid {
    return self.name.length > 0 && self.timestamp != nil;
}

- (NSDictionary *)objectValue {
    NSString* timestamp = [[Bugsnag payloadDateFormatter] stringFromDate:self.timestamp];
    if (timestamp && self.name.length > 0) {
        NSMutableDictionary *data = @{
            @"name": self.name,
            @"timestamp": timestamp,
            @"type": BSGBreadcrumbTypeValue(self.type)
        }.mutableCopy;
        if (self.metadata)
            data[@"metaData"] = self.metadata;
        return data;
    }
    return nil;
}

+ (instancetype)breadcrumbWithBlock:(BSGBreadcrumbConfiguration)block {
    BugsnagBreadcrumb *crumb = [self new];
    if (block)
        block(crumb);
    if ([crumb isValid]) {
        return crumb;
    }
    return nil;
}

@end

@implementation BugsnagBreadcrumbs

NSUInteger BreadcrumbsDefaultCapacity = 20;

- (instancetype)init {
    if (self = [super init]) {
        _breadcrumbs = [NSMutableArray new];
        _capacity = BreadcrumbsDefaultCapacity;
        _lock = [NSLock new];
    }
    return self;
}

- (void)addBreadcrumb:(NSString *)breadcrumbMessage {
    [self addBreadcrumbWithBlock:^(BugsnagBreadcrumb * _Nonnull crumb) {
        crumb.metadata = @{ @"message": breadcrumbMessage };
    }];
}

- (void)addBreadcrumbWithBlock:(void(^ _Nonnull)(BugsnagBreadcrumb *_Nonnull))block {
    if (self.capacity == 0) {
        return;
    }
    BugsnagBreadcrumb* crumb = [BugsnagBreadcrumb breadcrumbWithBlock:block];
    if (crumb) {
        [self resizeToFitCapacity:self.capacity - 1];
        [self.lock lock];
        [self.breadcrumbs addObject:crumb];
        [self.lock unlock];
    }
}

- (void)setCapacity:(NSUInteger)capacity {
    if (capacity == _capacity) {
        return;
    }
    [self resizeToFitCapacity:capacity];
    [self willChangeValueForKey:NSStringFromSelector(@selector(capacity))];
    _capacity = capacity;
    [self didChangeValueForKey:NSStringFromSelector(@selector(capacity))];
}

- (void)clearBreadcrumbs {
    [self.lock lock];
    [self.breadcrumbs removeAllObjects];
    [self.lock unlock];
}

- (NSUInteger)count {
    return self.breadcrumbs.count;
}

- (BugsnagBreadcrumb *)objectAtIndexedSubscript:(NSUInteger)index {
    if (index < [self count]) {
        [self.lock lock];
        BugsnagBreadcrumb *crumb = self.breadcrumbs[index];
        [self.lock unlock];
        return crumb;
    }
    return nil;
}

- (NSArray *)arrayValue {
    if ([self count] == 0) {
        return nil;
    }
    NSMutableArray* contents = [[NSMutableArray alloc] initWithCapacity:[self count]];
    [self.lock lock];
    for (BugsnagBreadcrumb* crumb in self.breadcrumbs) {
        NSDictionary *objectValue = [crumb objectValue];
        NSError *error = nil;
        @try {
            NSData* data = [NSJSONSerialization dataWithJSONObject:objectValue options:0 error:&error];
            if (data.length <= BSGBreadcrumbMaxByteSize)
                [contents addObject:objectValue];
            else
                bsg_log_warn(@"Dropping breadcrumb (%@) exceeding %lu byte size limit", crumb.name, (unsigned long)BSGBreadcrumbMaxByteSize);
        } @catch (NSException *exception) {
            bsg_log_err(@"Unable to serialize breadcrumb: %@", error);
        }
    }
    [self.lock unlock];
    return contents;
}

- (void)resizeToFitCapacity:(NSUInteger)capacity {
    if (capacity == 0) {
        [self clearBreadcrumbs];
        return;
    }
    [self.lock lock];
    while ([self count] > capacity) {
        [self.breadcrumbs removeObjectAtIndex:0];
    }
    [self.lock unlock];
}

@end