module ActiveRecord
  module Acts
    module Orderable
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_orderable
          has_many :orders, :as => :orderable
          include ActiveRecord::Acts::Orderable::InstanceMethods
        end
      end
            
      module InstanceMethods
        def orderable_id
          "#{self.class.name}.#{id}"
        end
      end
    end
    module Shopper
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_shopper
          has_many :shopping_transactions, :as => :shopper
        end
      end
    end
  end
end
