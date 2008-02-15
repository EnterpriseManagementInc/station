module CMS
  # Common Methods for CMS Controllers
  module ControllerMethods
    protected

    # Return the path to this Content collection in this Container 
    def container_contents_path(options = {})
      send "container_#{ controller_name }_path",
        :container_type => @container.class.to_s.tableize,
        :container_id   => @container.id,
        *options
    end

    # Return the url to this Content collection in this Container 
    def container_contents_url(options = {})
      send "container_#{ controller_name }_url",
        :container_type => @container.class.to_s.tableize,
        :container_id   => @container.id,
        *options
    end

    # Find Container using path from the request
    def get_container
      return nil unless params[:container_type] && params[:container_id]

      @container = params[:container_type].to_sym.to_class.find params[:container_id]
    end

    # Find a Container suitable for this Content. Return Forbidden if it isn't found
    def needs_container
      @container = get_container || current_agent

      render(:text => "Forbidden", :status => 403) unless @container.respond_to?("has_owner?") && (@container.contents.clone << :posts).include?(controller_name.to_sym)
    end

    # Can the current Agent access this Container?
    def can_read_container
      access_denied if @container && !@container.read_by?(current_agent)
    end

    # Can the current Agent post to this Container?
    def can_write_container
      access_denied if @container && !@container.write_by?(current_agent)
    end

    # Merge two conditions arrays using <tt>operator</tt>. 
    # Example:
    #   merge_conditions("AND", [ "public_read = ?", true ], [ "content_type = ?", "Article" ])
    #   # => [ "( public_read = ? ) AND ( content_type = ? )", true, "Article" ]
    def merge_conditions(operator, *conditions)
      query = conditions.compact.map(&:shift).compact.map{ |c| " (#{ c }) "}.join(operator)
      Array(query) + conditions.flatten.compact
    end
  end
end
