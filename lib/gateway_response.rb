class GatewayResponse < ActiveRecord::Base
  belongs_to :shopping_transaction
  serialize :response_object
end
