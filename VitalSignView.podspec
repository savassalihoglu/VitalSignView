#
# Be sure to run `pod lib lint VitalSignView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VitalSignView'
  s.version          = '0.1.0'
  s.summary          = 'Vitalsignview is a component for drawing continues sign like medical monitors display in IOS devices'



  s.homepage         = 'https://github.com/savassalihoglu/VitalSignView.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Savaş Salihoğlu' => 'mustafasavassalihoglu@gmail.com' }
  s.source           = { :git => 'https://github.com/savassalihoglu/VitalSignView.git',  :tag => "#{s.version}" }
  

  s.ios.deployment_target = '14.5'

  s.source_files = 'Source/**/*.swift'
  
  s.swift_version = "5.4"
  

end
