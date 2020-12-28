class CreateDemands < ActiveRecord::Migration[6.0]
  def change
    create_table :demands do |t|
      t.string :designator
      t.integer :distance
      t.text :status
      t.integer :indemnite

      t.timestamps
    end
  end
end
