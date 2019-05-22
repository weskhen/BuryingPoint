# 无痕埋点及上报阿里云日志

#### 介绍
该项目主要提供了无痕埋点的功能,有关无痕埋点 文章应该有一大堆,这边不做阐述.埋点没有覆盖全部事件,只对一些简单常用的处理了,后期需求对具体的业务扩张对象(Model)

其次,项目也提供了目前比较流行的阿里云日志上报功能, 上报格式支持json和protocol buffer格式.

##### .protocol 文件转objc

  Sls.pbobjc.h和Sls.pbobjc.m 文件的导出:

1. 首页需要安装protoc版本:

   可网上自行下载:如我之前的版本是protoc-3.0.0.

   安装proto 版本protoc-3.0.0-osx-x86_64,将该bin文件下的protoc  放入到/usr/local/bin/ 

   

2. protoc文件转objc

   1. cd到当前目录下,执行命令行 

   ```
   protoc sls.proto --objc_out="./" 
   ```

   会在当前的文件下多处两个文件.

   可能会有警告,如:

   ```
   [libprotobuf WARNING google/protobuf/compiler/parser.cc:547] No syntax specified for the proto file: sls.proto. Please use 'syntax = "proto2";' or 'syntax = "proto3";' to specify a syntax version. (Defaulted to proto2 syntax.)
   ```

   说明需要指定protoc版本,如果文件导出成功 此处可忽略.

   在sls.proto文件中的第一行插入 

   `syntax = "proto2"; `或`syntax = "proto3";`

#### 软件架构
软件架构说明


#### 安装教程

1. 支持pod `pod  'BuryingPoint'`

#### 使用说明

1. pod安装后. 在BuryingPointAliLogConst.h 中有需要修改的阿里云日志相关的配置项

   ```objective-c
   #pragma mark - 以下需要根据阿里云配置项赋值
   static NSString * AliLogDefaultEndPoint = @""; //cn-hangzhou.log.aliyuncs.com
   static NSString * AliLogDefaultProject = @"";
   static NSString * AliLogDefaultAccessKeyID = @"";
   static NSString * AliLogDefaultAccessKeySecret = @"";
   static NSString * AliLogDefaultLogstores = @"";
   ```

   在使用前赋值.

2. 埋点事件可以继承`BuryingPointBaseModel`,添加各种日志事件类型.

3. 提供了上报事件的入口

   ```objective-c
   /// 根据上报策略 上报埋点
   - (void)handleEventLogWithModel:(BuryingPointBaseModel *)model strategy:(BPLogUploadStrategy)strategy;
   
   /// 校验所有埋点数据立即上传
   - (void)checkUploadBuryingPointImmediately;
   ```

   

#### 其他 

欢迎沟通交流….