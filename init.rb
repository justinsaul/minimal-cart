require File.dirname(__FILE__) + '/lib/acts_as_orderable'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Orderable)
