Pod::Spec.new do |s|
  s.name             = 'RideOsDriver'
  s.version          = '0.1.0'
  s.summary          = 'rideOS SDK for building ridehailing driver apps'

  s.description      = <<-DESC
  rideOS SDK for building ridehailing driver apps.
                       DESC

  s.homepage         = 'https://github.com/rideOS/rideos-sdk-ios'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'rideOS' => 'support@rideos.ai' }
  s.source           = { :git => 'https://github.com/rideOS/rideos-sdk-ios.git', :tag => '0.1.0' }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  
  s.dependency 'RideOsApi', '~> 0.1'
  s.dependency 'RideOsCommon', '~> 0.1'
  s.dependency 'Eureka', '~> 5.0'
  s.dependency 'Polyline', '~> 4.2'
  s.dependency 'Protobuf', '~> 3.9'
  s.dependency 'RxCocoa', '~> 4.4'
  s.dependency 'RxSwift', '~> 4.4'
  s.dependency 'RxSwiftExt', '~> 3.4'
  s.dependency 'RxOptional', '~> 3.6'
  s.dependency 'SideMenu', '~> 5.0'
  s.dependency 'MapboxNavigation', '~> 0.34'
  
  s.source_files = 'RideOsDriver/**/*.{swift, h, m}'
  s.resource_bundles = {
    'RideOsDriver' => ['RideOsDriver/Assets.xcassets', 'RideOsDriver/*.lproj']
  }
  
  # This is needed by all pods that depend on Protobuf:
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }  
end
