require_relative "lib/max_page/version"

Gem::Specification.new do |spec|
  spec.name        = "maxpage"
  spec.version     = MaxPage::VERSION
  spec.authors     = ["Lucas Castro"]
  spec.email       = ["castro.lucas@gmail.com"]
  spec.homepage    = "https://github.com/lucasmncastro/maxpage"
  spec.summary     = "Simplest way to create a usage and status page for your Rails app."
  spec.description = "Max is a Ruby on Rails engine that provides a DLS to sniff and tell you if everything is running well."
  spec.license     = "MIT"
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/lucasmncastro/maxpage"
  # spec.metadata["changelog_uri"] = "https://github.com/lucasmncastro/maxpage/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 5.0"
end
