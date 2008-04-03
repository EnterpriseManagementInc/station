require 'digest/sha1'

module CMS
  # Agent(s) can CRUD Content(s) in Container(s), generating Post(s)
  module Agent
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Agent capabilities
      #
      # Agent(s) can post Content(s) to Container(s)
      #
      # Options
      # * <tt>authentication</tt>: Array with Authentication methods supported for this Agent. 
      # Defaults to <tt>[ :login_and_password, :openid ]</tt>
      # * <tt>activation</tt>: Agent must verify email
      def acts_as_agent(options = {})
        options[:authentication] ||= [ :login_and_password, :openid ]
        
        cattr_reader :agent_options
        class_variable_set "@@agent_options", options

        #
        # Authentication Methods
        #

        if options[:authentication].include? :login_and_password
          include CMS::Agent::Authentication::LoginAndPassword
        end

        if options[:authentication].include? :openid
          include CMS::Agent::Authentication::OpenID
        end

        # Verifies agent email
        if options[:activation]
          include CMS::Agent::Activation
        end

        # Remember Agent in browser through cookies
        include CMS::Agent::Remember

        has_many :performances, 
                 :class_name => "CMS::Performance", 
                 :dependent => :destroy,
                 :as => :agent

        include CMS::Agent::InstanceMethods
      end
         
      # Icon image path
      def icon_image
        'icons/' + self.to_s.underscore.concat(".png")
      end
    end

    module InstanceMethods
      # All Containers this Agent can post to
      def containers
        #TODO: Roles
        containers = []
        # Meanwhile, return self if Agent can post to self
        containers.unshift(self) if self.respond_to?("contents")

        containers
      end
    end
  end
end
