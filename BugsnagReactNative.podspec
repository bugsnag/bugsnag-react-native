require 'json'

Pod::Spec.new do |s|
  # NPM package specification
  package = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'package.json')))

  s.name           = 'BugsnagReactNative'
  s.version        = package['version']
  s.license        = 'MIT'
  s.summary        = 'Bugsnag crash and error reporting for React Native apps'
  s.author         = { 'Delisa Mason' => 'iskanamagus@gmail.com' }
  s.homepage       = "https://docs.bugsnag.com/platforms/react-native"
  s.source         = { :git => 'https://github.com/bugsnag/bugsnag-react-native.git', :tag => "v#{s.version}"}
  s.platform       = :ios, '8.0'
  s.preserve_paths = '*.js'
  s.libraries      = 'z', 'c++'
  s.frameworks     = 'MessageUI', 'SystemConfiguration'

  s.dependency 'React'

  s.source_files = 'cocoa/BugsnagReactNative.{h,m}',
                   'cocoa/vendor/bugsnag-cocoa/Source/**/*.{h,m,mm,cpp,c}',

  s.public_header_files = 'cocoa/**/{Bugsnag,BugsnagReactNative,BugsnagMetaData,BugsnagConfiguration,BugsnagBreadcrumb,BugsnagCrashReport,BSG_KSCrashReportWriter}.h'

  # If Bugsnag is previously installed via CocoaPods, use the Core subspec.
  s.subspec 'Core' do |core|
    core.source_files = 'cocoa/BugsnagReactNative.{h,m}'
    core.public_header_files = ['cocoa/BugsnagReactNative.h']
  end
end
