Pod::Spec.new do |s|
  s.name             = 'RideOsCommon'
  s.version          = '0.1.0'
  s.summary          = 'Common code and assets used across other rideOS Cocoapods'

  s.description      = <<-DESC
  Common code and assets used across other rideOS Cocoapods.
                       DESC

  s.homepage         = 'https://github.com/rideOS/rideos-sdk-ios'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'rideOS' => 'support@rideos.ai' }
  s.source           = { :git => 'https://github.com/rideOS/rideos-sdk-ios.git', :tag => '0.1.0' }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  
  s.dependency 'RideOsApi', '~> 0.1'
  s.dependency 'Auth0', '~> 1.15'
  s.dependency 'Eureka', '~> 5.0'
  s.dependency 'JWTDecode', '~> 2.1'
  s.dependency 'Lock', '~> 2.10'
  s.dependency 'Polyline', '~> 4.2'
  s.dependency 'RxCocoa', '~> 4.4'
  s.dependency 'RxSwift', '~> 4.4'
  s.dependency 'RxSwiftExt', '~> 3.4'
  s.dependency 'SwiftSimplify', '~> 0.2'
  s.dependency 'NicoProgress', '~> 0.1'
  s.dependency 'RxReachability', '~> 0.1'
  s.dependency 'NotificationBannerSwift', '~> 2.1'
  
  s.source_files = 'RideOsCommon/**/*.{swift, h, m}'
  s.resource_bundles = {
    'RideOsCommon' => ['RideOsCommon/Assets.xcassets', 'RideOsCommon/*.lproj']
  }
  
  # This is needed by all pods that depend on Protobuf:
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }  
end
