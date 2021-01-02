class AddReasonToDemands < ActiveRecord::Migration[6.0]
  def change
    add_column :demands, :reason, :text
  end
end
