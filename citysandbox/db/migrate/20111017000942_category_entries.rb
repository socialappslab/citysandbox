class CategoryEntries < ActiveRecord::Migration
  def up
    add_column :questions, :description, :string
    Categories.create :category => "Commerce"
    Categories.create :category => "Dignity & Rights"
    Categories.create :category => "Health & Safety"
    Categories.create :category => "History"
    Categories.create :category => "Kids & Education"
    Categories.create :category => "Public Space"
    Categories.create :category => "Transportation"
  end

  def down
  end
end