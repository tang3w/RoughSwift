Pod::Spec.new do |s|
  s.name             = "RoughSwift"
  s.summary          = "Create hand-drawn, sketchy, comic shape in Swift"
  s.version          = "1.0.0"
  s.homepage         = "https://github.com/onmyway133/RoughSwift"
  s.license          = 'MIT'
  s.author           = { "Khoa Pham" => "onmyway133@gmail.com" }
  s.source           = {
    :git => "https://github.com/onmyway133/RoughSwift.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/onmyway133'

  s.requires_arc = true
  s.resources  = 'Sources/rough.js'
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'JavascriptCore', 'QuartzCore'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.2'
  s.watchos.deployment_target = "3.0"
end
