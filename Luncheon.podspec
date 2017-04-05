Pod::Spec.new do |s|
  s.name             = "Luncheon"
  s.version          = "0.6.0"
  s.summary          = "REST model resource mapping. Time saving. Opinionated. Convention over configuration. Inspired by Rails and ActiveRecord."
  s.homepage         = "https://github.com/Dan2552/Luncheon"
  s.license          = 'MIT'
  s.author           = { "Daniel Inkpen" => "dan2552@gmail.com" }
  s.source           = { :git => "https://github.com/Dan2552/Luncheon.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Dan2552'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.dependency 'Alamofire', '~> 4.0.1'
  s.dependency 'Placemat', '>= 0.6.0'
end
