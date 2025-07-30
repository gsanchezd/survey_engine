# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_24_191603) do
  create_table "survey_engine_answer_options", force: :cascade do |t|
    t.integer "answer_id", null: false
    t.integer "option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id", "option_id"], name: "index_answer_options_on_answer_option", unique: true
    t.index ["answer_id"], name: "index_survey_engine_answer_options_on_answer_id"
    t.index ["option_id"], name: "index_survey_engine_answer_options_on_option_id"
  end

  create_table "survey_engine_answers", force: :cascade do |t|
    t.integer "response_id", null: false
    t.integer "question_id", null: false
    t.text "text_answer"
    t.integer "numeric_answer"
    t.decimal "decimal_answer", precision: 10, scale: 2
    t.boolean "boolean_answer"
    t.text "other_text"
    t.integer "selection_count", default: 0
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answered_at"], name: "index_survey_engine_answers_on_answered_at"
    t.index ["question_id"], name: "index_survey_engine_answers_on_question_id"
    t.index ["response_id", "question_id"], name: "index_answers_on_response_question", unique: true
    t.index ["response_id"], name: "index_survey_engine_answers_on_response_id"
  end

  create_table "survey_engine_options", force: :cascade do |t|
    t.integer "question_id", null: false
    t.string "option_text", null: false
    t.string "option_value", null: false
    t.integer "order_position", null: false
    t.boolean "is_other", default: false, null: false
    t.boolean "is_exclusive", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.text "skip_logic"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id", "is_active"], name: "index_survey_engine_options_on_question_id_and_is_active"
    t.index ["question_id", "order_position"], name: "index_survey_engine_options_on_question_id_and_order_position", unique: true
    t.index ["question_id"], name: "index_survey_engine_options_on_question_id"
  end

  create_table "survey_engine_participants", force: :cascade do |t|
    t.integer "survey_id", null: false
    t.string "email", null: false
    t.string "status", default: "invited", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_survey_engine_participants_on_status"
    t.index ["survey_id", "email"], name: "index_participants_on_survey_email", unique: true
    t.index ["survey_id"], name: "index_survey_engine_participants_on_survey_id"
  end

  create_table "survey_engine_question_types", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "allows_options", default: false, null: false
    t.boolean "allows_multiple_selections", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_survey_engine_question_types_on_name", unique: true
  end

  create_table "survey_engine_questions", force: :cascade do |t|
    t.integer "survey_id", null: false
    t.integer "question_type_id", null: false
    t.string "title", null: false
    t.text "description"
    t.boolean "is_required", default: false, null: false
    t.integer "order_position", null: false
    t.integer "scale_min"
    t.integer "scale_max"
    t.string "scale_min_label"
    t.string "scale_max_label"
    t.integer "max_characters"
    t.integer "min_selections"
    t.integer "max_selections"
    t.boolean "allow_other", default: false, null: false
    t.boolean "randomize_options", default: false, null: false
    t.text "validation_rules"
    t.string "placeholder_text"
    t.text "help_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "conditional_parent_id"
    t.string "conditional_operator"
    t.decimal "conditional_value"
    t.boolean "show_if_condition_met", default: true
    t.index ["conditional_parent_id"], name: "index_survey_engine_questions_on_conditional_parent_id"
    t.index ["question_type_id"], name: "index_survey_engine_questions_on_question_type_id"
    t.index ["survey_id", "order_position"], name: "index_survey_engine_questions_on_survey_id_and_order_position", unique: true
    t.index ["survey_id"], name: "index_survey_engine_questions_on_survey_id"
  end

  create_table "survey_engine_responses", force: :cascade do |t|
    t.integer "survey_id", null: false
    t.integer "participant_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_survey_engine_responses_on_completed_at"
    t.index ["participant_id"], name: "index_survey_engine_responses_on_participant_id"
    t.index ["survey_id"], name: "index_survey_engine_responses_on_survey_id"
  end

  create_table "survey_engine_surveys", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.boolean "is_active", default: false, null: false
    t.boolean "global", default: false, null: false
    t.datetime "published_at"
    t.datetime "expires_at"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.string "surveyable_type"
    t.integer "surveyable_id"
    t.index ["global", "is_active"], name: "index_survey_engine_surveys_on_global_and_is_active"
    t.index ["is_active"], name: "index_survey_engine_surveys_on_is_active"
    t.index ["status"], name: "index_survey_engine_surveys_on_status"
    t.index ["surveyable_type", "surveyable_id"], name: "idx_on_surveyable_type_surveyable_id_ffe4fd0636"
    t.index ["surveyable_type", "surveyable_id"], name: "index_survey_engine_surveys_on_surveyable"
    t.index ["uuid"], name: "index_survey_engine_surveys_on_uuid", unique: true
  end

  add_foreign_key "survey_engine_answer_options", "survey_engine_answers", column: "answer_id"
  add_foreign_key "survey_engine_answer_options", "survey_engine_options", column: "option_id"
  add_foreign_key "survey_engine_answers", "survey_engine_questions", column: "question_id"
  add_foreign_key "survey_engine_answers", "survey_engine_responses", column: "response_id"
  add_foreign_key "survey_engine_options", "survey_engine_questions", column: "question_id"
  add_foreign_key "survey_engine_participants", "survey_engine_surveys", column: "survey_id"
  add_foreign_key "survey_engine_questions", "survey_engine_question_types", column: "question_type_id"
  add_foreign_key "survey_engine_questions", "survey_engine_questions", column: "conditional_parent_id"
  add_foreign_key "survey_engine_questions", "survey_engine_surveys", column: "survey_id"
  add_foreign_key "survey_engine_responses", "survey_engine_participants", column: "participant_id"
  add_foreign_key "survey_engine_responses", "survey_engine_surveys", column: "survey_id"
end
