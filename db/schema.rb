# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101016174455) do

  create_table "countries", :force => true do |t|
    t.string   "name",       :limit => 40
    t.float    "factor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.text     "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emissions", :force => true do |t|
    t.integer  "site_id"
    t.text     "text_users"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visitors"
    t.string   "server_location"
    t.integer  "year"
    t.integer  "month"
    t.integer  "traffic"
    t.decimal  "co2_server",      :precision => 40, :scale => 5
    t.decimal  "co2_users",       :precision => 40, :scale => 5
    t.decimal  "time",            :precision => 20, :scale => 2
    t.decimal  "factor",          :precision => 10, :scale => 5
  end

  create_table "sites", :force => true do |t|
    t.string   "name",       :limit => 100
    t.string   "gid",        :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "address"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "gtoken"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
