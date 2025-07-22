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

ActiveRecord::Schema[8.0].define(version: 2025_07_22_034228) do
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
    t.index ["question_type_id"], name: "index_survey_engine_questions_on_question_type_id"
    t.index ["survey_id", "order_position"], name: "index_survey_engine_questions_on_survey_id_and_order_position", unique: true
    t.index ["survey_id"], name: "index_survey_engine_questions_on_survey_id"
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
    t.index ["global", "is_active"], name: "index_survey_engine_surveys_on_global_and_is_active"
    t.index ["is_active"], name: "index_survey_engine_surveys_on_is_active"
    t.index ["status"], name: "index_survey_engine_surveys_on_status"
  end

  add_foreign_key "survey_engine_options", "survey_engine_questions", column: "question_id"
  add_foreign_key "survey_engine_questions", "survey_engine_question_types", column: "question_type_id"
  add_foreign_key "survey_engine_questions", "survey_engine_surveys", column: "survey_id"
end
