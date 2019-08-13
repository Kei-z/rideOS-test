Pod::Spec.new do |s|
  s.name             = 'RideOsRider'
  s.version          = '0.1.0'
  s.summary          = 'rideOS SDK for building ridehailing rider apps'

  s.description      = <<-DESC
  rideOS SDK for building ridehailing rider apps.
                       DESC

  s.homepage         = 'https://github.com/rideOS/rideos-sdk-ios'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'rideOS' => 'support@rideos.ai' }
  s.source           = { :git => 'https://github.com/rideOS/rideos-sdk-ios.git', :tag => '0.1.0' }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  
  s.dependency 'RideOsApi', '~> 0.1'
  s.dependency 'RideOsCommon'
  s.dependency 'RxCocoa', '~> 4.4'
  s.dependency 'RxSwift', '~> 4.4'
  s.dependency 'RxSwiftExt', '~> 3.4'
  s.dependency 'RxOptional', '~> 3.6'
  s.dependency 'SideMenu', '~> 5.0'
  
  s.source_files = 'RideOsRider/**/*.{swift, h, m}'
  s.resource_bundles = {
    'RideOsRider' => ['RideOsRider/Assets.xcassets', 'RideOsRider/*.lproj']
  }
  
  # This is needed by all pods that depend on Protobuf:
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }  
end
