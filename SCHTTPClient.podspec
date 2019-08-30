Pod::Spec.new do |s|
  s.name     = "SCHTTPClient"
  s.version  = "1.0.1"
  s.summary  = "A modern HTTP client framework for iOS/OSX built on top of libcurl."
  s.homepage = "https://github.com/debugly/SCHTTPClient.git"
  s.license  = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author   = { "debugly" => "qianlongxu@gmail.com" }
  s.source   = { :git => "https://github.com/debugly/SCHTTPClient.git", :tag => s.version.to_s }

  s.requires_arc = true

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  s.ios.preserve_path = 'External/libcurl.iOS'
  s.osx.preserve_path = 'External/libcurl.OSX'

  s.subspec 'LibCurl' do |curl|
    curl.ios.source_files = "External/libcurl.iOS/*.h"
    curl.osx.source_files = "External/libcurl.OSX/*.h"
    curl.ios.vendored_library = 'External/libcurl.iOS/libcurl.iOS.a'
    curl.osx.vendored_libraries = 'External/libcurl.OSX/libcrypto_Mac.a' ,'External/libcurl.OSX/libcurl_Mac.a' ,'External/libcurl.OSX/libnghttp2_Mac.a' ,'External/libcurl.OSX/libssl_Mac.a'    
  end

  s.subspec 'Client' do |c|
    c.source_files = "#{s.name}/**/*.{h,m}"
    c.libraries = 'z'
    c.frameworks = %w{ Security }
    c.ios.frameworks = %w{ MobileCoreServices UIKit }
    c.osx.frameworks = %w{ CoreServices AppKit }
    c.dependency 'SCHTTPClient/LibCurl'
    c.private_header_files = "#{s.name}/Internal/*.h"
    c.prefix_header_contents = <<-PREFIXHEADER
#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    #import <MobileCoreServices/MobileCoreServices.h>
#else
    #import <CoreServices/CoreServices.h>
#endif
PREFIXHEADER

  end

end
