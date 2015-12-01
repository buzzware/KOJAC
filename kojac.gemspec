$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kojac/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kojac"
  s.version     = Kojac::VERSION
  s.authors       = ["Gary McGhee"]
  s.email         = ["contact@buzzware.com.au"]
  s.homepage      = "https://github.com/buzzware/KOJAC"
  s.license       = "MIT"

  s.summary     = "KOJAC is an opinionated design and implementation for data management within Single Page Applications."
  s.description = "KOJAC is an opinionated design and implementation for data management within Single Page Applications. It relates most heavily to the client and data protocol. The server may continue the key/value style down to a key/value-style database if desired, but that is not necessary. KOJAC also supports standard REST-style servers."

  #s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "buzztools", '~> 0.0.5'
  s.add_runtime_dependency "underscore_plus", '~> 0.9.1'
  s.add_runtime_dependency "pundit", '~> 0.2.3'
  s.add_runtime_dependency "active_model_serializers", '= 0.9.0.alpha1'

  #s.add_runtime_dependency "jquery-rails"
  #s.add_runtime_dependency "rails", ">= 3.1"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  # s.add_development_dependency "canjs-rails"
  # s.add_development_dependency "ember-rails"
  # s.add_development_dependency "jquery-rails"
  # s.add_development_dependency "capybara"
  # s.add_development_dependency "sqlite3"
end
