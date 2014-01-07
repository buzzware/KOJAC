class AddOwnerId < ActiveRecord::Migration
  def change
	  add_column :users, :owner_id, :integer
  end
end
