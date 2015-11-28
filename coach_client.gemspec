# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coach_client/version'

Gem::Specification.new do |spec|
  spec.name          = "coach_client"
  spec.version       = CoachClient::VERSION
  spec.authors       = ["Michael Jungo", "Amanda Karavolia", "Andrea Liechti", "Jocelyn Thode", "Simon Brulhart"]
  spec.email         = ["michael.jungo@unifr.ch"]

  spec.summary       = %q{A wrapper around the CyberCoach API of unifr}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4.0"
  spec.add_development_dependency "webmock", "~> 1.22.3"
  spec.add_development_dependency "vcr", "~> 2.9.3"

  spec.add_dependency "gyoku", "~> 1.3.1"
  spec.add_dependency "rest-client", "~> 1.8"
end
