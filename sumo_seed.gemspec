$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sumo_seed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sumo_seed"
  s.version     = SumoSeed::VERSION
  s.authors       = ['Cédric Néhémie']
  s.email         = ['cedric.nehemie@gmail.com']
  s.homepage      = 'https://github.com/3print/sumo_seed'
  s.summary       = 'A seeding engine for rails projects'
  s.description   = 'A seeding engine for rails projects'
  s.license       = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.5"
  s.add_dependency "colorize"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "faker"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec", "~> 3.3.0"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "carrierwave"
  s.add_development_dependency "pg"
end
