//
//  CDVWKProcessPoolFactory.m
//  HelloCordova
//
//  Created by avnath on 12/23/16.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "CDVWKProcessPoolFactory.h"

static CDVWKProcessPoolFactory *factory = nil;

@implementation CDVWKProcessPoolFactory

+ (instancetype)sharedFactory
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[CDVWKProcessPoolFactory alloc] init];
    });
    
    return factory;
}

- (instancetype)init
{
    if (self = [super init]) {
        _sharedPool = [[WKProcessPool alloc] init];
    }
    return self;
}

- (WKProcessPool*) sharedProcessPool {
    return _sharedPool;
}
@end
