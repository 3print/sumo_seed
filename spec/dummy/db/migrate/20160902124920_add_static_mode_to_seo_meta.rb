class AddStaticModeToSeoMeta < ActiveRecord::Migration
  def change
    add_column :seo_meta, :static_mode, :boolean
    add_column :seo_meta, :static_action, :string
  end
end
