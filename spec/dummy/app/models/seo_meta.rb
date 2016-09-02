class SeoMeta < ActiveRecord::Base
  belongs_to :meta_owner, polymorphic: true

  validates :meta_owner_type, presence: true, unless: 'static_mode'
  validates :static_action, presence: true, if: 'static_mode'
end
