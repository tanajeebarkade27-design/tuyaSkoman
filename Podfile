source 'https://cdn.cocoapods.org/'
source 'https://github.com/TuyaInc/TuyaPublicSpecs.git'
source 'https://github.com/tuya/tuya-pod-specs.git'

# Uncomment the next line to define a global platform for your project
#platform :ios, '14.0'


target 'SkromanIsra' do
  # Comment the next line if you don't want to use dynamic frameworks
 use_frameworks! :linkage => :static


  # Pods for SkromanIsra
pod 'Reachability'
pod 'ESPProvision'
pod 'GoogleSignIn'
pod 'PasswordTextField'
pod 'IQKeyboardManagerSwift'
pod 'Alamofire'
pod 'PasswordTextField'
 pod 'AWSCore'
  pod 'AWSIoT'
pod 'SwiftKeychainWrapper'
pod 'NVActivityIndicatorView'
pod 'DropDown'
pod 'lottie-ios'
pod 'MARKRangeSlider'
pod 'razorpay-pod', '~> 1.3.5'
pod 'SwiftyGif'
 pod 'Firebase/Core'
  pod 'Firebase/Analytics'
pod 'Firebase/Messaging'


 pod 'ThingSmartHomeKit','~> 6.11.0'
pod 'ThingSmartActivatorKit'
  pod 'ThingSmartLockKit', '~> 6.11'
pod 'ThingSmartLockSDK', '1.4.0'

pod 'ThingSmartCameraKit'
pod 'ThingSmartActivatorCoreKit'
pod 'ThingSmartBusinessExtensionKit'

 pod 'ThingSmartCryption', :path => './'

 
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end

  
 
end
