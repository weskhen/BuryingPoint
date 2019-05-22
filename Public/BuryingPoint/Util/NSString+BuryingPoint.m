//
//  NSString+BuryingPoint.m
//  BuryingPoint
//
//  Created by wujian on 2019/5/16.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import "NSString+BuryingPoint.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString (BuryingPoint)

- (NSString *)SHA1WithSecret:(NSString *)secret {
    const char *cKey   = [secret cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData  = [self cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC   = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    return hash;
}

@end
