Pod::Spec.new do |s|

  s.name         = "SBFileStreamer"
  s.version      = "1.2.0"
  s.summary      = "Basic file streamer for iOS development."
  s.description  = "Basic file streamer for Objc.Inc iOS Developers, such as ViewController/View etc."

  s.homepage     = "https://github.com/iFindTA"
  s.license      = "MIT (LICENSE)"
  s.author             = { "nanhujiaju" => "nanhujiaju@gmail.com" }
  s.platform     = :ios, "8.0"
  
  s.source       = { :git => "https://github.com/iFindTA/SBFileStreamer.git", :tag => "#{s.version}" }
  s.source_files  = "SBFileStreamer/SBFileStreamer/*.{h,m}"
  s.public_header_files = "SBFileStreamer/SBFileStreamer/*.h"

  #s.resources    = "PBBaseClasses/Pod/Assets/*.lproj","PBBaseClasses/Pod/Assets/PBBaseClasses.xcassets/*"

  s.frameworks  = "UIKit","Foundation"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency 'AFNetworking'
  s.dependency 'WHC_ModelSqliteKit'
end
