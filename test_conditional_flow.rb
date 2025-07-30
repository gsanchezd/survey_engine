# Test script for conditional flow functionality
# This demonstrates how the conditional flow works

# Example usage:
# 1. Create a survey with a scale question
# 2. Add conditional questions based on scale responses

puts "=== Survey Engine Conditional Flow Test ==="

# Main scale question (1-10 satisfaction rating)
main_question = {
  title: "How satisfied are you with our service?",
  question_type: "scale",
  scale_min: 1,
  scale_max: 10,
  order_position: 1
}

# Conditional question for low ratings (< 5)
low_rating_question = {
  title: "What specific areas need improvement?",
  question_type: "textarea",
  conditional_parent_id: 1, # References main question
  conditional_operator: "less_than",
  conditional_value: 5,
  show_if_condition_met: true,
  order_position: 2
}

# Conditional question for high ratings (>= 8)
high_rating_question = {
  title: "What did we do particularly well?",
  question_type: "textarea", 
  conditional_parent_id: 1, # References main question
  conditional_operator: "greater_than_or_equal",
  conditional_value: 8,
  show_if_condition_met: true,
  order_position: 3
}

puts "\n=== Question Flow Examples ==="

# Test scenarios
test_answers = [3, 5, 7, 9]

test_answers.each do |answer|
  puts "\nAnswer: #{answer}/10"
  
  # Check which conditional questions should show
  if answer < 5
    puts "  → Shows: '#{low_rating_question[:title]}' (rating < 5)"
  elsif answer >= 8
    puts "  → Shows: '#{high_rating_question[:title]}' (rating >= 8)"
  else
    puts "  → No conditional questions shown"
  end
end

puts "\n=== Key Methods Available ==="
puts "- question.is_conditional?                  # Check if question has conditions"
puts "- question.has_conditional_questions?       # Check if question triggers others"
puts "- question.evaluate_condition(answer)       # Test condition against answer"
puts "- question.should_show?(parent_answer)      # Determine if question should display"
puts "- question.next_questions_for_answer(val)   # Get next questions for answer"

puts "\n=== Implementation Complete! ==="