//
//  CrashyCrashy.m
//  BugsnagReactNativeExample
//
//  Created by Christian Schlensker on 1/3/17.
//  Copyright © 2017 Bugsnag. All rights reserved.
//

#import "CrashyCrashy.h"
#import "RCTBridgeModule.h"

@implementation CrashyCrashy
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(generateCrash)
{
  @throw [NSException exceptionWithName: @"Oopsy Exception" reason: @"oopsy!" userInfo:nil];
}

@end
