Pod::Spec.new do |s|
s.name = "QueueITLibrary"
s.version = "3.4.0"
s.summary = "Library for integrating Queue-it into an iOS app using web uI"
s.homepage = "https://github.com/queueit/ios-webui-sdk"
s.license = 'MIT'
s.authors  = { 'Queue-It' => 'https://queue-it.com' }
s.platform = :ios, '9.3'
s.source   = { :git => 'https://github.com/queueit/ios-webui-sdk.git', :tag => '3.4.0' }
s.requires_arc = true
s.source_files = "QueueITLib/*.{h,m}"
end
