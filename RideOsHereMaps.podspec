Pod::Spec.new do |s|
  s.name             = 'RideOsHereMaps'
  s.version          = '0.1.0'
  s.summary          = 'Implementation of rideOS maps protocols that uses HERE Maps'

  s.description      = <<-DESC
  Implementation of rideOS maps protocols that uses HERE Maps.
                       DESC

  s.homepage         = 'https://github.com/rideOS/rideos-sdk-ios'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'rideOS' => 'support@rideos.ai' }
  s.source           = { :git => 'https://github.com/rideOS/rideos-sdk-ios.git', :tag => '0.1.0' }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
    
  s.dependency 'RideOsCommon', '~> 0.1'
  s.dependency 'RxSwift', '~> 4.4'
  s.dependency 'HEREMaps', '~> 3.11'
  
  s.source_files = 'RideOsHereMaps/**/*.{swift, h, m}'
  
  # This is needed by all pods that depend on Protobuf:
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }  
end
