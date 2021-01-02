# rails g migration AddMoreColumnsToDemand
class AddMoreColumnsToDemand < ActiveRecord::Migration[6.0]
  def change
    # add_column :table, :new_column, :type
    add_column :demands, :departure_country, :string
    add_column :demands, :arrival_country, :string
    add_column :demands, :departure_airport, :text
    add_column :demands, :arrival_airport, :text
    add_column :demands, :departure_airport_iata, :text
    add_column :demands, :arrival_airport_iata, :text
  end
end
