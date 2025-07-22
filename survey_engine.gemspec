require_relative "lib/survey_engine/version"

Gem::Specification.new do |spec|
  spec.name        = "survey_engine"
  spec.version     = SurveyEngine::VERSION
  spec.authors     = [ "Gonzalo Sánchez" ]
  spec.email       = [ "gonzalo.sanchez.d@gmail.com" ]
  spec.homepage    = "https://github.com/gonzalosanchez/survey_engine"
  spec.summary     = "A Rails Engine for building survey functionality"
  spec.description = "SurveyEngine provides a complete solution for creating, managing and collecting responses to surveys within Rails applications."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gonzalosanchez/survey_engine"
  spec.metadata["changelog_uri"] = "https://github.com/gonzalosanchez/survey_engine/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.2"
end
