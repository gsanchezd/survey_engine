require "test_helper"

module SurveyEngine
  class ConditionalFlowTest < ActiveSupport::TestCase
    def setup
      @survey_template = SurveyTemplate.create!(name: "Conditional Flow Template #{SecureRandom.hex(4)}")
      @survey = Survey.create!(
        title: "Conditional Flow Survey #{SecureRandom.hex(4)}",
        survey_template: @survey_template
      )
      @scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      @text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
    end

    test "should create complete satisfaction survey flow" do
      # Main satisfaction question (1-10 scale)
      satisfaction_question = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "How satisfied are you with our service?",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # Low satisfaction follow-up (< 5)
      improvement_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "What specific areas need improvement?",
        conditional_parent: satisfaction_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 2
      )

      # High satisfaction follow-up (>= 8)
      praise_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "What did we do particularly well?",
        conditional_parent: satisfaction_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 8,
        show_if_condition_met: true,
        order_position: 3
      )

      # Test various satisfaction scores
      test_scenarios = [
        { score: 2, shows: [improvement_question], hides: [praise_question] },
        { score: 4, shows: [improvement_question], hides: [praise_question] },
        { score: 5, shows: [], hides: [improvement_question, praise_question] },
        { score: 7, shows: [], hides: [improvement_question, praise_question] },
        { score: 8, shows: [praise_question], hides: [improvement_question] },
        { score: 10, shows: [praise_question], hides: [improvement_question] }
      ]

      test_scenarios.each do |scenario|
        score = scenario[:score]
        expected_shows = scenario[:shows]
        expected_hides = scenario[:hides]

        # Test which questions should show
        next_questions = satisfaction_question.next_questions_for_answer(score)
        
        expected_shows.each do |question|
          assert_includes next_questions, question, 
            "Question '#{question.title}' should show for score #{score}"
          assert question.should_show?(score), 
            "Question '#{question.title}' should_show? should return true for score #{score}"
        end

        expected_hides.each do |question|
          assert_not_includes next_questions, question, 
            "Question '#{question.title}' should not show for score #{score}"
          assert_not question.should_show?(score), 
            "Question '#{question.title}' should_show? should return false for score #{score}"
        end
      end
    end

    test "should handle multiple conditional questions from same parent" do
      # Main rating question
      rating_question = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "Rate your experience (1-10)",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # Very low rating (1-2)
      very_low_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "We're sorry to hear that. What went wrong?",
        conditional_parent: rating_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 2,
        show_if_condition_met: true,
        order_position: 2
      )

      # Low rating (3-5)
      low_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "How can we improve?",
        conditional_parent: rating_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 3
      )

      # High rating (8-10)
      high_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "What made your experience great?",
        conditional_parent: rating_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 8,
        show_if_condition_met: true,
        order_position: 4
      )

      # Test score 1 - should show both very_low and low questions
      next_questions = rating_question.next_questions_for_answer(1)
      assert_includes next_questions, very_low_question
      assert_includes next_questions, low_question
      assert_not_includes next_questions, high_question

      # Test score 4 - should show only low question
      next_questions = rating_question.next_questions_for_answer(4)
      assert_not_includes next_questions, very_low_question
      assert_includes next_questions, low_question
      assert_not_includes next_questions, high_question

      # Test score 9 - should show only high question
      next_questions = rating_question.next_questions_for_answer(9)
      assert_not_includes next_questions, very_low_question
      assert_not_includes next_questions, low_question
      assert_includes next_questions, high_question
    end

    test "should handle inverted conditional logic with show_if_condition_met false" do
      # Main question
      main_question = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "How likely are you to recommend us? (1-10)",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # This question shows when score is NOT high (opposite of typical promoter logic)
      not_promoter_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "What would make you more likely to recommend us?",
        conditional_parent: main_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 9,
        show_if_condition_met: false, # Show when condition is NOT met
        order_position: 2
      )

      # Test scores - question should show for non-promoters (< 9)
      assert not_promoter_question.should_show?(1)
      assert not_promoter_question.should_show?(8)
      assert_not not_promoter_question.should_show?(9)
      assert_not not_promoter_question.should_show?(10)

      # Test via parent question
      next_questions = main_question.next_questions_for_answer(7)
      assert_includes next_questions, not_promoter_question

      next_questions = main_question.next_questions_for_answer(10)
      assert_not_includes next_questions, not_promoter_question
    end

    test "should properly validate complex conditional survey structure" do
      # Main demographic question
      age_question = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "What is your age?",
        scale_min: 18,
        scale_max: 100,
        order_position: 1
      )

      # Student-specific question (age < 25)
      student_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "What is your field of study?",
        conditional_parent: age_question,
        conditional_operator: "less_than",
        conditional_value: 25,
        show_if_condition_met: true,
        order_position: 2
      )

      # Senior-specific question (age >= 65)
      senior_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "Are you retired?",
        conditional_parent: age_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 65,
        show_if_condition_met: true,
        order_position: 3
      )

      # Verify all questions are valid
      assert age_question.valid?, "Age question should be valid: #{age_question.errors.full_messages}"
      assert student_question.valid?, "Student question should be valid: #{student_question.errors.full_messages}"
      assert senior_question.valid?, "Senior question should be valid: #{senior_question.errors.full_messages}"

      # Verify relationships
      assert age_question.has_conditional_questions?
      assert_equal 2, age_question.conditional_questions.count
      assert student_question.is_conditional?
      assert senior_question.is_conditional?

      # Test the flow logic
      # Young adult (22) - should see student question
      assert student_question.should_show?(22)
      assert_not senior_question.should_show?(22)

      # Middle-aged (45) - should see neither
      assert_not student_question.should_show?(45)
      assert_not senior_question.should_show?(45)

      # Senior (70) - should see senior question
      assert_not student_question.should_show?(70)
      assert senior_question.should_show?(70)
    end

    test "should maintain proper question ordering with conditional questions" do
      # Create questions with specific order positions
      q1 = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "Main Question",
        scale_min: 1,
        scale_max: 5,
        order_position: 1
      )

      q2 = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "Regular Question 2",
        order_position: 2
      )

      # Conditional question with order position 3
      q3_conditional = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "Conditional Question",
        conditional_parent: q1,
        conditional_operator: "less_than",
        conditional_value: 3,
        show_if_condition_met: true,
        order_position: 3
      )

      q4 = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "Regular Question 4",
        order_position: 4
      )

      # Verify all questions have correct order positions
      ordered_questions = @survey_template.questions.ordered
      assert_equal [1, 2, 3, 4], ordered_questions.map(&:order_position)

      # Verify conditional question is in the right position
      assert_equal q3_conditional, ordered_questions[2]

      # Verify scopes work correctly
      root_questions = @survey_template.questions.root_questions.ordered
      conditional_questions = @survey_template.questions.conditional_questions.ordered

      assert_equal [q1, q2, q4], root_questions
      assert_equal [q3_conditional], conditional_questions
    end

    test "should handle edge cases in conditional evaluation" do
      main_question = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "Rate from 1 to 10",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # Edge case: equal_to boundary
      boundary_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "Exactly 5 question",
        conditional_parent: main_question,
        conditional_operator: "equal_to",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 2
      )

      # Test boundary values
      assert_not boundary_question.should_show?(4)
      assert boundary_question.should_show?(5)
      assert_not boundary_question.should_show?(6)

      # Test with decimal values (edge case)
      assert boundary_question.should_show?(5.0)
      assert_not boundary_question.should_show?(5.1)
      assert_not boundary_question.should_show?(4.9)
    end

    test "conditional questions should be destroyed when parent is destroyed" do
      parent_question = Question.create!(
        survey_template: @survey_template,
        question_type: @scale_type,
        title: "Parent Question",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      conditional_question = Question.create!(
        survey_template: @survey_template,
        question_type: @text_type,
        title: "Conditional Question",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 2
      )

      conditional_id = conditional_question.id

      # Verify the conditional question exists
      assert Question.exists?(conditional_id)

      # Destroy parent question
      assert_difference('Question.count', -2) do
        parent_question.destroy!
      end

      # Verify conditional question was also destroyed
      assert_not Question.exists?(conditional_id)
    end
  end
end