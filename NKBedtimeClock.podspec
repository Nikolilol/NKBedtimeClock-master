Pod::Spec.new do |s|
  s.name         = "NKBedtimeClock"
  s.version      = "0.0.1"
  s.summary      = "A view like the clock of bedtime that can set sleep time and wake up"
  s.homepage     = "https://github.com/Nikolilol/NKBedtimeClock-master"
  s.license      = "MIT"
  s.author       = { "Nikolilol" => "nikoli_89@163.com" }
  s.platform     = :ios, "8.3"
  s.ios.deployment_target = "8.3"
  s.source       = { :git => "https://github.com/Nikolilol/NKBedtimeClock-master.git", :tag => "#{s.version}" }
  s.source_files = "NKBedtimeClock/*.{h,m}"
end
