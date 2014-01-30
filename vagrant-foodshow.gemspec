# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-foodshow/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-foodshow"
  spec.version       = Vagrant::Foodshow::VERSION
  spec.authors       = ["Nikita Borzykh"]
  spec.email         = ["sample.n@gmail.com"]
  spec.summary       = %q{You can share your vagrant vm with your colleagues easily by using vagrant-foodshow}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/express42/vagrant-foodshow"
  spec.license       = "MIT"

  spec.rubyforge_project = "vagrant-foodshow"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
end
