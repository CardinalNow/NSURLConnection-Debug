//
//  NSURLConnection+Debug.m
//  Vantiv
//
//  Created by Rusty Weneck on 3/15/13.
//  Copyright (c) 2013 Cardinal Solutions. All rights reserved.
//

#import <objc/runtime.h>
#import "NSURLConnection+Debug.h"

#define DEBUGABLE true //If true, disable ALL SSL trust chain checks for the application.

@implementation NSURLConnection (Debug)

/**
 *  iOS 6 delegate signature
 */
-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

-(id)swizzled_initWithRequest:(NSURLRequest *)request delegate:(id)delegate{
    if (DEBUGABLE){
        //Double Swizzle, set the method on the delegate to our instance
        Method original;

        original = class_getInstanceMethod([delegate class], @selector(connection:willSendRequestForAuthenticationChallenge:));

        if (original){
            // Get the "- (id)swizzled_initWithFrame:" method.
            Method swizzle = class_getInstanceMethod([self class], @selector(connection:willSendRequestForAuthenticationChallenge:));
            // Swap their implementations.
            method_exchangeImplementations(original, swizzle);
        }else{
            // Get the "- (id)swizzled_initWithFrame:" method.
            IMP swizzle = [self methodForSelector:@selector(connection:willSendRequestForAuthenticationChallenge:)];
            // Add the implementation to the class
            class_addMethod([delegate class], @selector(connection:willSendRequestForAuthenticationChallenge:), swizzle, "B@:@@");
        }
    }
    // This is the confusing part we need to call the original init method, but we've switched its implementation with the swizzled one.
    id result = [self swizzled_initWithRequest:request delegate:delegate];
    return result;
}

+ (void)load
{
    // The "+ load" method is called once, very early in the application life-cycle.
    // It's called even before the "main" function is called. Beware: there's no
    // autorelease pool at this point, so avoid Objective-C calls.
    Method original, swizzle;

    // Get the "- (BOOL)sqizzled_connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace" method.
    original = class_getInstanceMethod(self, @selector(initWithRequest:delegate:));
    // Get the "- (id)swizzled_initWithFrame:" method.
    swizzle = class_getInstanceMethod(self, @selector(swizzled_initWithRequest:delegate:));
    // Swap their implementations.
    method_exchangeImplementations(original, swizzle);
}

@end
