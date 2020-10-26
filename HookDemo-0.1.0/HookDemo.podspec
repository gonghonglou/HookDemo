Pod::Spec.new do |s|
  s.name = "HookDemo"
  s.version = "0.1.0"
  s.summary = "A short description of HookDemo."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"gonghonglou"=>"gonghonglou@icloud.com"}
  s.homepage = "https://github.com/gonghonglou/HookDemo"
  s.description = "TODO: Add long description of the pod here."
  s.source = { :path => '.' }

  s.ios.deployment_target    = '8.0'
  s.ios.vendored_framework   = 'ios/HookDemo.framework'
end
