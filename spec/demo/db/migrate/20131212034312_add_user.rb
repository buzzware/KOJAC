class AddUser < ActiveRecord::Migration
  def change
	  create_table "users" do |t|
	    t.string   "email",                           :null => false
	    t.datetime "created_at",                      :null => false
	    t.datetime "updated_at",                      :null => false
	    t.integer  "ring"
	    t.string   "first_name"
	    t.string   "middle_names"
	    t.string   "last_name"
	    t.date     "dob"
	  end
  end
end
