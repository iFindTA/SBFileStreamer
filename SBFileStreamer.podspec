Pod::Spec.new do |s|

  s.name         = "SBFileStreamer"
  s.version      = "1.0.0"
  s.summary      = "Basic file streamer for iOS development."
  s.description  = "Basic file streamer for Objc.Inc iOS Developers, such as ViewController/View etc."

  s.homepage     = "https://github.com/iFindTA"
  s.license      = "MIT (LICENSE)"
  s.author             = { "nanhujiaju" => "nanhujiaju@gmail.com" }
  s.platform     = :ios, "8.0"
  
  s.source       = { :git => "https://github.com/iFindTA/PBBaseClasses.git", :tag => "#{s.version}" }
  s.source_files  = "PBBaseClasses/Pod/Classes/BaseControllers/*.{h,m}","PBBaseClasses/Pod/Classes/BaseHeaders/*.h","PBBaseClasses/Pod/Classes/BaseViews/*.{h,m}","PBBaseClasses/Pod/Classes/Categories/*.{h,m}","PBBaseClasses/Pod/Classes/Constants/*.h"
  s.public_header_files = "PBBaseClasses/Pod/Classes/Constants/*.h","PBBaseClasses/Pod/Classes/Categories/*.h","PBBaseClasses/Pod/Classes/BaseViews/*.h","PBBaseClasses/Pod/Classes/BaseHeaders/*.h","PBBaseClasses/Pod/Classes/BaseControllers/*.h"
  s.preserve_paths  = 'PBBaseClasses/Pod/Classes/**/*'

  s.resources    = "PBBaseClasses/Pod/Assets/*.lproj","PBBaseClasses/Pod/Assets/PBBaseClasses.xcassets/*"

  s.frameworks  = "UIKit","Foundation"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  #s.dependency "JSONKit", "~> 1.4"
  s.dependency 'PBKits'
  s.dependency 'YYKit'
  s.dependency 'Masonry'
  s.dependency 'WZLBadge'
  s.dependency 'PBMediator'
  s.dependency 'SVProgressHUD'
  s.dependency 'SJFullscreenPopGesture'
