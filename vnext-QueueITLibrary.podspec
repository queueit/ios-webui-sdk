Pod::Spec.new do |s|
s.name = "vnext-QueueITLibrary"
s.version = "3.1.14"
s.summary = "Library for integrating Queue-it into an iOS app using web UI"
s.homepage = "https://github.com/queueit/ios-webui-sdk"
s.license = 'MIT'
s.authors  = { 'Queue-It' => 'https://queue-it.com' }
s.platform = :ios, '9.3'
s.source   = { :git => 'https://github.com/queueit/ios-webui-sdk.git', :branch => 'poc-vnext', :tag => '3.3.0' }
s.requires_arc = true
s.source_files = "QueueITLib/*.{h,m}"
end
