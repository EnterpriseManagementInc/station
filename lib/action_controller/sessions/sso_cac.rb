module ActionController #:nodoc:
  module Sessions
    # Methods for Sessions based on LoginAndPassword Authentication
    module SsoCac
      # Init Session using LoginAndPassword Authentication
      def create_session_with_sso_cac(params = self.params)
        #return unless request.headers.has_key?("HTTP_DN") && request.headers["HTTP_DN"] !~ /CN=(.*)/
        return unless request.headers.has_key?("HTTP_DN")
        agent = nil
        cn_capture = /CN=(.*)/.match(request.headers["HTTP_DN"]).captures[0]

        agent = User.find_by_cert(cn_capture)

        if agent
          if agent.class.agent_options[:activation] && ! agent.activated_at
            flash[:notice] = t(:please_activate_account)
          elsif agent.respond_to?(:disabled) && agent.disabled
            flash[:error] = t(:disabled, :scope => agent.class.to_s.tableize)
          else
            flash[:success] = t(:logged_in_successfully)
            return self.current_agent = agent
          end
        else
          flash[:error] ||= t(:invalid_credentials)
        end
        return
      end
    end
  end
end
