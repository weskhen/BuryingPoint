//
//  BuryingPointUploadPlugin.m
//  BuryingPoint
//
//  Created by wujian on 2019/3/30.
//  Copyright © 2019年 wesk痕. All rights reserved.
//

#import "BuryingPointUploadPlugin.h"
#import "BuryingPointAliLogGroup.h"
#import "NSData+BuryingPoint.h"
#import "BuryingPointAliLogConst.h"
#import "NSString+BuryingPoint.h"

@implementation BuryingPointUploadPlugin

+ (void)uploadJsonMap:(NSDictionary *)uploadDic
            uploadUrl:(NSString *)uploadUrl
         successBlock:(BPUploadSuccessBlock)successBlock
           faildBlock:(BPUploadFailedBlock)failBlock {
    
    if (uploadUrl.length < 1) {
        NSError *error = [NSError errorWithDomain:@"上传失败" code:-1 userInfo:nil];
        if (failBlock) {
            failBlock(error);
        }
        return;
    }
    NSMutableDictionary<NSString*,NSString*> *headers = [[NSMutableDictionary alloc] init];
    [headers setValue:@"gzip" forKey:@"Content-Encoding"];
    // 设置body
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:uploadDic options:kNilOptions error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    //替换encoding后的转义符错误
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSString *parameterString = [NSString stringWithFormat:@"log=%@",jsonString];
    NSData *uploadData = [parameterString dataUsingEncoding:NSUTF8StringEncoding];
    
    [BuryingPointUploadPlugin httpPostRequest:uploadUrl headers:headers body:uploadData successBlock:successBlock faildBlock:failBlock];
}

+ (void)uploadAliLogWithList:(NSArray<BuryingPointBaseModel *> *)modelList
                  modelClass:(Class)modelClass
            logSerializeType:(NSUInteger)logSerializeType
                successBlock:(BPUploadSuccessBlock)successBlock
                  faildBlock:(BPUploadFailedBlock)failBlock {
    BuryingPointAliLogGroup *logGroup = [[BuryingPointAliLogGroup alloc] initWithModelClass:modelClass logSerializeType:logSerializeType];
    [modelList enumerateObjectsUsingBlock:^(BuryingPointBaseModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [logGroup putAliLogModel:obj];
    }];
    
    NSData *uploadData = [logGroup packageData];
    BuryingPointAliLogType logType = logGroup.logSerializeType;

    NSString *accessKeySecret = logGroup.accessKeySecret;
    NSString *accessKeyID = logGroup.accessKeyID;
    NSString *accessToken = logGroup.accessToken;
    NSString *project = logGroup.project;
    NSString *endPoint = logGroup.endPoint;
    NSString *logstores = logGroup.logstores;
    NSString *httpUrl = [NSString stringWithFormat:@"https://%@.%@/logstores/%@/shards/lb",project,endPoint,logstores];
    NSData *httpPostBodyZipped = [uploadData gzippedData];
    NSDictionary<NSString*,NSString*>* httpHeaders = [BuryingPointUploadPlugin httpHeadersFrom:logstores url:httpUrl body:uploadData accessKeySecret:accessKeySecret accessKeyID:accessKeyID accessToken:accessToken bodyZipped:httpPostBodyZipped serializerType:logType];
    [BuryingPointUploadPlugin httpPostRequest:httpUrl headers:httpHeaders body:httpPostBodyZipped successBlock:successBlock faildBlock:failBlock];
}

+ (void)httpPostRequest:(NSString *)url
               headers:(NSDictionary<NSString *,NSString *> *)headers
                  body:(NSData *)body
          successBlock:(BPUploadSuccessBlock)successBlock
            faildBlock:(BPUploadFailedBlock)failBlock {
    NSURL *httpUrl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:httpUrl];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:60];
    [request setHTTPBody:body];
    [request setHTTPShouldHandleCookies:FALSE];
    for(NSString *key in headers.allKeys) {
        [request setValue:[headers valueForKey:key] forHTTPHeaderField:key];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(response != nil) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            if (httpResponse.statusCode != 200) {
                NSError *jsonErr = nil;
                NSDictionary *jsonResult = nil;
                if (data) {
                    jsonResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
                }
                if(jsonErr == nil) {
                    if (failBlock) failBlock([NSError errorWithDomain:[jsonResult description]?:@"error" code:-1 userInfo:nil]);
                } else {
                    if (failBlock) failBlock(jsonErr);
                }
            } else {
                if (successBlock) successBlock();
            }
        } else {
            if (failBlock) failBlock([NSError errorWithDomain:[@"非法URL" stringByAppendingString:url] code:-1 userInfo:nil]);
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}


+ (NSDictionary<NSString*,NSString*>*)httpHeadersFrom:(NSString*)logstore
                                                  url:(NSString*)url
                                                 body:(NSData*)body
                                      accessKeySecret:(NSString *)accessKeySecret
                                          accessKeyID:(NSString *)accessKeyID
                                          accessToken:(NSString *)accessToken
                                           bodyZipped:(NSData*)bodyZipped
                                       serializerType:(BuryingPointAliLogType)type
{
    NSMutableDictionary<NSString*,NSString*> *headers = [[NSMutableDictionary alloc] init];
    [headers setValue:POST_VALUE_LOG_APIVERSION forKey:KEY_LOG_APIVERSION];
    [headers setValue:POST_VALUE_LOG_SIGNATUREMETHOD forKey:KEY_LOG_SIGNATUREMETHOD];
    [headers setValue:POST_VALUE_LOG_UA forKey:KEY_LOG_CLIENT];
    if (type == BuryingPointAliLogJson) {
        [headers setValue:POST_VALUE_LOG_JSON_CONTENT_TYPE forKey:KEY_CONTENT_TYPE];
    } else {
        [headers setValue:POST_VALUE_LOG_PB_CONTENT_TYPE forKey:KEY_CONTENT_TYPE];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = HTTP_DATE_FORMAT;
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    [headers setValue:[NSString stringWithFormat:@"%@ GMT",timeStamp] forKey:KEY_DATE];
    [headers setValue:[bodyZipped MD5HexDigest] forKey:KEY_CONTENT_MD5];
    
    [headers setValue:[NSString stringWithFormat:@"%ld",[bodyZipped length]] forKey:KEY_CONTENT_LENGTH];
    [headers setValue:[NSString stringWithFormat:@"%lu",(unsigned long)[body length]] forKey:KEY_LOG_BODYRAWSIZE];
    [headers setValue:POST_VALUE_LOG_COMPRESSTYPE forKey:KEY_LOG_COMPRESSTYPE];
    [headers setValue:[NSURL URLWithString:url].host forKey:KEY_HOST];
    
    NSString *signString = [NSString stringWithFormat:@"POST\n%@\n%@\n%@\n", [headers valueForKey:KEY_CONTENT_MD5],[headers valueForKey:KEY_CONTENT_TYPE],[headers valueForKey:KEY_DATE]];
    if(accessToken != nil) {
        [headers setValue:accessToken forKey:KEY_ACS_SECURITY_TOKEN];
        signString = [signString stringByAppendingFormat:@"x-acs-security-token:%@\n", [headers valueForKey:KEY_ACS_SECURITY_TOKEN]];
    }
    
    signString = [signString stringByAppendingFormat:@"x-log-apiversion:%@\n",POST_VALUE_LOG_APIVERSION];
    signString = [signString stringByAppendingFormat:@"x-log-bodyrawsize:%@\n",[headers valueForKey:KEY_LOG_BODYRAWSIZE]];
    signString = [signString stringByAppendingFormat:@"x-log-compresstype:%@\n",POST_VALUE_LOG_COMPRESSTYPE];
    signString = [signString stringByAppendingFormat:@"x-log-signaturemethod:%@\n",POST_VALUE_LOG_SIGNATUREMETHOD];
    signString = [signString stringByAppendingFormat:@"/logstores/%@/shards/lb",logstore];
    
    NSString *sign = [signString SHA1WithSecret:accessKeySecret];
    
    [headers setValue:[NSString stringWithFormat:@"LOG %@:%@",accessKeyID,sign] forKey:KEY_AUTHORIZATION];
    return headers;
}

@end
