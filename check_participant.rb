survey = SurveyEngine::Survey.find_by(uuid: '78858622-5722-4b9b-bd33-ece619faa5af')
participant = SurveyEngine::Participant.find_by(survey: survey, email: 'user@survey.com')

if participant
  puts 'Participant exists:'
  puts "  Email: #{participant.email}"
  puts "  Status: #{participant.status}"
else
  puts 'No participant found for user@survey.com in the new survey'
  puts 'Creating participant...'
  
  participant = SurveyEngine::Participant.create!(
    survey: survey,
    email: 'user@survey.com',
    status: 'invited'
  )
  
  puts "Participant created: #{participant.email} (#{participant.status})"
end

puts "Survey URL: /survey_engine/surveys/#{survey.uuid}"