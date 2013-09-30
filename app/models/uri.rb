# Require Ruby URI Module, not defined by this file but with the 
# same source file name
URI

# URI storage in the database
class Uri < ActiveRecord::Base

             
  # Return this URI string         
  def to_s
    self.uri
  end

  def to_uri
    @to_uri ||= ::URI.parse(self.uri)
  end

  # Dereference URI and return HTML document
  def html
    # NOTE: Must read StringIO or Tmpfile
    @html ||= Station::Html.new(dereference(:accept => 'text/html').try(:read))
  end

  def dereference(options = {})
    headers = {}
    headers['Accept'] = options[:accept] if options.key?(:accept)

    to_uri.open(headers)
  rescue
    nil
  end


  # Returns the AtomPub Service Document associated with this URI.
  def atompub_service_document
    #FIXME: use html?
    Atom::Service.discover self.uri
  end

  delegate :hcard, :hcard?,
           :foaf, :foaf?,
           :to => :html

  private

  # Extract service link from HTML head
  def parse_atompub_service_link(html) #:nodoc:
    # TODO: link service
    # TODO: meta refresh
    nil
  end
end
