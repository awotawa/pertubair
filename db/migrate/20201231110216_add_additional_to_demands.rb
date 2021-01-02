class AddAdditionalToDemands < ActiveRecord::Migration[6.0]
  def change
    add_column :demands, :additional, :text
  end
end
