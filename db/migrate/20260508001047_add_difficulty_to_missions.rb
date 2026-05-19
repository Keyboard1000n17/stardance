class AddDifficultyToMissions < ActiveRecord::Migration[8.1]
  def change
    add_column :missions, :difficulty, :string
  end
end
