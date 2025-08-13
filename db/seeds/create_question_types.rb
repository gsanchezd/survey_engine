# Create all question types for SurveyEngine
# This ensures all supported question types are available in the database

puts "🔧 Creating all SurveyEngine question types..."

question_types = [
  # Text-based inputs
  {
    name: "text",
    description: "Short text input (single line)",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: false
  },
  {
    name: "textarea", 
    description: "Long text input (multi-line)",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: false
  },
  {
    name: "email",
    description: "Email address input with validation",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: false
  },
  
  # Numeric inputs
  {
    name: "number",
    description: "Numeric input",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "scale"
  },
  {
    name: "scale",
    description: "Rating scale (e.g., 1-10, NPS style)",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "scale"
  },
  
  # Date input
  {
    name: "date",
    description: "Date picker input",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: false
  },
  
  # Boolean/Yes-No
  {
    name: "boolean",
    description: "Yes/No question",
    allows_options: false,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "both"
  },
  
  # Choice-based questions
  {
    name: "single_choice",
    description: "Single selection (radio buttons)",
    allows_options: true,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "option"
  },
  {
    name: "multiple_choice",
    description: "Multiple selection (checkboxes)",
    allows_options: true,
    allows_multiple_selections: true,
    follow_up: true,
    follow_up_type: "option"
  },
  {
    name: "dropdown_single",
    description: "Single selection dropdown",
    allows_options: true,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "option"
  },
  {
    name: "dropdown_multiple",
    description: "Multiple selection dropdown",
    allows_options: true,
    allows_multiple_selections: true,
    follow_up: true,
    follow_up_type: "option"
  },
  
  # Ranking
  {
    name: "ranking",
    description: "Ranking/ordering question",
    allows_options: true,
    allows_multiple_selections: true,
    follow_up: true,
    follow_up_type: "option"
  },
  
  # Matrix questions
  {
    name: "matrix_scale",
    description: "Matrix question with scale ratings",
    allows_options: true,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "scale"
  },
  {
    name: "matrix_choice",
    description: "Matrix question with choice options",
    allows_options: true,
    allows_multiple_selections: false,
    follow_up: true,
    follow_up_type: "option"
  }
]

puts "📝 Creating #{question_types.length} question types..."

question_types.each do |qt_data|
  qt = SurveyEngine::QuestionType.find_or_create_by(name: qt_data[:name]) do |question_type|
    question_type.description = qt_data[:description]
    question_type.allows_options = qt_data[:allows_options]
    question_type.allows_multiple_selections = qt_data[:allows_multiple_selections]
  end
  
  if qt.persisted?
    status = qt.previously_new_record? ? "✅ Created" : "📋 Exists"
    follow_up_info = qt_data[:follow_up] ? " (follow-up: #{qt_data[:follow_up_type]})" : " (no follow-up)"
    puts "   #{status}: #{qt_data[:name]} - #{qt_data[:description]}#{follow_up_info}"
  else
    puts "   ❌ Failed: #{qt_data[:name]} - #{qt.errors.full_messages.join(', ')}"
  end
end

puts "\n🎉 Question types setup completed!"
puts "📊 Total question types in database: #{SurveyEngine::QuestionType.count}"

# Display summary by follow-up capability
puts "\n📋 Follow-up Capabilities Summary:"
puts "   🔄 Can have follow-ups (#{question_types.count { |qt| qt[:follow_up] }}):"
question_types.select { |qt| qt[:follow_up] }.each do |qt|
  puts "      • #{qt[:name]} - type: #{qt[:follow_up_type]}"
end

puts "   🚫 Cannot have follow-ups (#{question_types.count { |qt| !qt[:follow_up] }}):"
question_types.reject { |qt| qt[:follow_up] }.each do |qt|
  puts "      • #{qt[:name]}"
end

puts "\n🚀 All question types are now available for survey creation!"