//
//  BuryingPointAliLogConst.h
//  BuryingPoint
//
//  Created by wujian on 2019/5/16.
//  Copyright © 2019 wesk痕. All rights reserved.
//

#ifndef BuryingPointAliLogConst_h
#define BuryingPointAliLogConst_h

#define POST_VALUE_LOG_UA @"AliyunLogClientObjc/1.1.6.20180508"

#define HTTP_DATE_FORMAT @"EEE, dd MMM yyyy HH:mm:ss"

#define KEY_HOST @"Host"
#define KEY_TIME @"__time__"
#define KEY_TOPIC @"__topic__"
#define KEY_SOURCE @"__source__"
#define KEY_LOGS @"__logs__"
#define KEY_TAGS @"__tags__"

#define KEY_DATE @"Date"

#define KEY_CONTENT_LENGTH @"Content-Length"
#define KEY_CONTENT_MD5 @"Content-MD5"
#define KEY_CONTENT_TYPE @"Content-Type"

#define KEY_LOG_APIVERSION @"x-log-apiversion"
#define KEY_LOG_BODYRAWSIZE @"x-log-bodyrawsize"
#define KEY_LOG_COMPRESSTYPE @"x-log-compresstype"
#define KEY_LOG_SIGNATUREMETHOD @"x-log-signaturemethod"
#define KEY_LOG_CLIENT @"User-Agent"

#define KEY_ACS_SECURITY_TOKEN @"x-acs-security-token"
#define KEY_AUTHORIZATION @"Authorization"

#define POST_VALUE_LOG_APIVERSION @"0.6.0"
#define POST_VALUE_LOG_COMPRESSTYPE @"deflate"
#define POST_VALUE_LOG_JSON_CONTENT_TYPE @"application/json"
#define POST_VALUE_LOG_PB_CONTENT_TYPE @"application/x-protobuf"
#define POST_VALUE_LOG_SIGNATUREMETHOD @"hmac-sha1"


typedef NS_ENUM(NSUInteger, BuryingPointAliLogType) {
    BuryingPointAliLogJson,
    BuryingPointAliLogProtocBuffer,
};


#pragma mark - 以下需要根据阿里云配置项赋值
static NSString * AliLogDefaultEndPoint = @""; //cn-hangzhou.log.aliyuncs.com
static NSString * AliLogDefaultProject = @"";
static NSString * AliLogDefaultAccessKeyID = @"";
static NSString * AliLogDefaultAccessKeySecret = @"";
static NSString * AliLogDefaultLogstores = @"";

#endif /* BuryingPointAliLogConst_h */
