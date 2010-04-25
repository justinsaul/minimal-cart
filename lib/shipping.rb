# See LICENSE file in the root for details
class Shipping < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :street_address, :city, :state, :zip_code, :country
  validates_length_of :last_name, :in => 2..255
  validates_length_of :street_address, :in => 2..255
  validates_length_of :city, :in => 2..255 
  validates_length_of :state, :in => 2..255
  validates_length_of :country, :in => 2..255
end
