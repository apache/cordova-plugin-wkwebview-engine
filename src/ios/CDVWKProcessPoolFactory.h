//
//  CDVWKProcessPoolFactory.h
//  HelloCordova
//
//  Created by avnath on 12/23/16.
//
//

#import <WebKit/WebKit.h>

@interface CDVWKProcessPoolFactory : NSObject
@property (nonatomic, retain) WKProcessPool* sharedPool;

+(instancetype) sharedFactory;
-(WKProcessPool*) sharedProcessPool;
@end
