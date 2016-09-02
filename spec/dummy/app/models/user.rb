require 'carrierwave/orm/activerecord'

class User < ActiveRecord::Base
  extend CarrierWave::ActiveRecord

  attr_accessor :password_confirmation

  mount_uploader :avatar, AvatarUploader

  validates :email, presence: true
  validates :password, :password_confirmation, presence: true
end
