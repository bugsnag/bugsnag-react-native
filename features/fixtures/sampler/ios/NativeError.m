//
//  NativeError.m
//  sampler
//
//  Created by Alexander Moinet on 02/05/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NativeError.h"

@implementation NativeError

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(triggerNativeError)
{
  NSException *ex = [NSException exceptionWithName:@"Kaboom" reason:@"The connection exploded" userInfo:nil];
  
  @throw ex;
}

@end
