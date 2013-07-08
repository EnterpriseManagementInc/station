#begin
#  require 'net/ldap'
#rescue MissingSourceFile
#  raise "Station: You need 'net/ldap gem for cac authentication support"
#end

module ActiveRecord #:nodoc:
  module Agent
    # Agent Authentication Methods
    module Authentication
      # Central Authentication Service (CAS) authentication support
      #
      # Options:
      # * cas_filter: Options to pass to the CAS Filter
      module SSO_CAC
      end
      Cac = SSO_CAC
    end
  end
end
