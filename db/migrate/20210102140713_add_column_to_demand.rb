class AddColumnToDemand < ActiveRecord::Migration[6.0]
  def change
    add_column :demands, :rerouting, :integer
  end
end
