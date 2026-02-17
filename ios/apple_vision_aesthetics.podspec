Pod::Spec.new do |s|
  s.name             = 'apple_vision_aesthetics'
  s.version          = '1.0.1'
  s.summary          = 'Flutter plugin for Apple Vision CalculateImageAestheticsScoresRequest'
  s.description      = <<-DESC
A Flutter plugin wrapping Apple's Vision framework CalculateImageAestheticsScoresRequest
to score image quality, detect blur, and identify utility images. iOS 18+ only.
                       DESC
  s.homepage         = 'https://github.com/dev-ale/apple_vision_aesthetics'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alejandro Garcia' => 'ale.iphone@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'apple_vision_aesthetics/Sources/apple_vision_aesthetics/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '18.0'
  s.swift_version    = '5.9'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
