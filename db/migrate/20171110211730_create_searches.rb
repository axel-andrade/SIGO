class CreateSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :searches do |t|
      t.string :logradouro
      t.string :numero
      t.string :bairro

      t.timestamps
    end
  end
end
