#
# Be sure to run `pod lib lint Luncheon.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Luncheon"
  s.version          = "0.4.0"
  s.summary          = "REST model resource mapping. Time saving. Opinionated. Convention over configuration. Inspired by Rails and ActiveRecord."
  s.homepage         = "https://github.com/Dan2552/Luncheon"
  s.license          = 'MIT'
  s.author           = { "Daniel Inkpen" => "dan2552@gmail.com" }
  s.source           = { :git => "https://github.com/Dan2552/Luncheon.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Dan2552'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Luncheon' => ['Pod/Assets/*.png']
  }

  s.dependency 'Alamofire', '~> 3.3'
  s.dependency 'Placemat', '~> 0.2'
end
