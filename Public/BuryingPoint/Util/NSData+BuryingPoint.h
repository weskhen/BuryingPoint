//
//  NSData+BuryingPoint.h
//  BuryingPoint
//
//  Created by wujian on 2019/5/16.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (BuryingPoint)

- (nullable NSData *)gzippedDataWithCompressionLevel:(float)level;
- (nullable NSData *)gzippedData;
- (nullable NSData *)gunzippedData;
- (BOOL)isGzippedData;


+ (NSData *_Nullable)MD5Digest:(NSData *_Nullable)input;
- (NSData *_Nullable)MD5Digest;

+ (NSString *_Nullable)MD5HexDigest:(NSData *_Nullable)input;
- (NSString *_Nullable)MD5HexDigest;

@end

