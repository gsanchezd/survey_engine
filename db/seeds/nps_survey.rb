# Create a Survey based on NPS Template
# Run with: rails runner db/seeds/nps_survey.rb

# Find the NPS template
nps_template = SurveyEngine::SurveyTemplate.find_by(name: "Net Promoter Score (NPS) Survey")

unless nps_template
  puts "Error: NPS template not found. Please run the NPS template seed first."
  exit
end

# Create a new survey based on the NPS template
nps_survey = SurveyEngine::Survey.create!(
  title: "Q4 2024 Customer Satisfaction Survey",
  survey_template: nps_template,
  is_active: true,
  global: true, # Global survey not tied to specific resource
  uuid: SecureRandom.uuid
)

puts "Created NPS Survey:"
puts "- Title: #{nps_survey.title}"
puts "- Template: #{nps_survey.survey_template.name}"
puts "- UUID: #{nps_survey.uuid}"
puts "- Questions: #{nps_survey.questions.count}"
puts "- Active: #{nps_survey.is_active}"
puts "\nSurvey URL path: /survey_engine/surveys/#{nps_survey.uuid}"