#
#  Be sure to run `pod spec lint BuryingPoint.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "BuryingPoint"
  s.version      = "0.0.5"
  s.summary      = "埋点封装+阿里云日志数据上报集成"
  s.description  = <<-DESC
  无痕埋点封装和阿里云日志数据上报集成
                     DESC

  s.homepage     = "https://gitee.com/weskTeam/BuryingPoint.git"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "wujian" => "wujian516411567@163.com" } 
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://gitee.com/weskTeam/BuryingPoint.git", :tag => "#{s.version}" }
  
  s.ios.deployment_target = '9.0'
  s.module_name = 'BuryingPoint'
  s.prefix_header_file = 'Public/BuryingPoint/BuryingPoint.pch'
  s.dependency 'Protobuf', '3.6.1'
  s.dependency 'LBaseDB'

  s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1' }


  s.prefix_header_file = 'Public/BuryingPoint/BuryingPoint.pch'

  s.subspec 'Util' do |ss|
    ss.source_files = 'Public/BuryingPoint/Util/*.{h,m}'
  end
  s.subspec 'Const' do |ss|
    ss.source_files = 'Public/BuryingPoint/Const/*.{h,m}'
    ss.dependency 'BuryingPoint/Util'
  end
  s.subspec 'Upload' do |ss|
    ss.source_files = 'Public/BuryingPoint/Upload/*.{h,m}'
    ss.dependency 'BuryingPoint/Model'
    ss.dependency 'BuryingPoint/Const'
    ss.dependency 'Protobuf'
    ss.dependency 'YYModel'
  end
  s.subspec 'Model' do |ss|
    ss.source_files = 'Public/BuryingPoint/Model/*.{h,m}'
    ss.dependency 'BuryingPoint/Const'
    ss.dependency 'YYModel'
  end

  s.subspec 'Base' do |ss|
    ss.source_files = 'Public/BuryingPoint/Base/*.{h,m}'
    ss.dependency 'BuryingPoint/Upload'
    ss.dependency 'BuryingPoint/DB'
    ss.dependency 'BuryingPoint/Const'
  end
  s.subspec 'Category' do |ss|
    ss.source_files = 'Public/BuryingPoint/Category/*.{h,m}'
    ss.dependency 'BuryingPoint/Base'
    ss.dependency 'BuryingPoint/Const'
  end
  s.subspec 'DB' do |ss|
    ss.source_files = 'Public/BuryingPoint/DB/*.{h,m}'
    ss.dependency 'BuryingPoint/Model'
    ss.dependency 'LBaseDB'
 end
  

  s.weak_frameworks = 'UserNotifications'
  s.frameworks = "UIKit", "Foundation", "QuartzCore", "CoreTelephony"
  s.requires_arc = true

end
