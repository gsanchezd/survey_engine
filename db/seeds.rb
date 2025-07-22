# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed standard question types
puts "Creando tipos de pregunta estándar..."
begin
  SurveyEngine::QuestionType.seed_standard_types
  puts "Tipos de pregunta creados: #{SurveyEngine::QuestionType.count}"
rescue => e
  puts "Error seeding question types: #{e.message}"
end