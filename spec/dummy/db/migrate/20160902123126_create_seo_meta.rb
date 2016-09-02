class CreateSeoMeta < ActiveRecord::Migration
  def change
    create_table :seo_meta do |t|
      t.string :title
      t.text :description
      t.integer :meta_owner_id
      t.string :meta_owner_type

      t.timestamps
    end
  end
end
