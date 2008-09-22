require 'atom/entry'

module CMS
  # A Content is a unit of information suitable to be published online.
  # Examples of contents are texts, images, events, URIs
  #
  # Content(s) are posted by Agent(s) to Container(s), resulting in Entry(s)
  #
  # == Contents in some container
  # You can use the named_scope +in_container+ to get all Contents in some container.
  #   Content.in_container(some_container) #=> Array of contents in the container
  #
  # Contents instances have entries columns in entry_*
  module Content
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    # Return the first Content class supporting this Content Type
    def self.class_supporting(content_type)
      mime_type = Mime::Type.lookup(content_type)
      
      for content_class in CMS::content_classes
        return content_class if content_class.mime_types.include?(mime_type)
      end
      nil
    end

    module ClassMethods
      # Provides an ActiveRecord model with Content capabilities
      #
      # Content(s) are posted by Agent(s) to Container(s), creating Entry(s)
      #
      # Options:
      # * <tt>:named_collection</tt> - this Content has an particular collection name, (ex. blog for articles, calendar for events, etc..)
      # * <tt>:atompub_mime_types</tt> - array of Mime Types accepted for this Content via AtomPub. Defaults to "application/atom+xml;type=entry"
      # * <tt>:has_media</tt> - this Content has attachment data. Supported plugins: attachment_fu (<tt>:attachment_fu</tt>)
      # * <tt>:disposition</tt> - specifies whether the Content will be shown inline or as attachment (see Rails send_file method). Defaults to :attachment
      # * <tt>:per_page</tt> - number of contents shown per page, using will_pagination plugin. Defaults to 9
      #
      def acts_as_content(options = {})
        CMS.register_model(self, :content)

        #FIXME: should this be the default mime type??
        options[:atompub_mime_types] ||= "application/atom+xml;type=entry"
        options[:disposition]        ||= :attachment
        options[:per_page]           ||= 9

        cattr_reader :content_options
        class_variable_set "@@content_options", options

        cattr_reader :per_page
        class_variable_set "@@per_page", options[:per_page]

        attr_writer :entry

        validates_associated :entry

        after_save :entry_save!


        has_many :content_entries, 
                 :class_name => "Entry",
                 :dependent => :destroy,
                 :as => :content

        acts_as_sortable

        # Named scope in_container returns all Contents in some container
        named_scope :in_container, lambda { |container|
          if container && container.respond_to?("container_options")
            container_conditions = " AND entries.container_id = '#{ container.id }' AND entries.container_type = '#{ container.class.base_class.to_s }'"
          end

          entry_columns = Entry.column_names.map{|n| "entries.#{ n } AS entry_#{ n }" }.join(', ')
          { :select => "#{ self.table_name }.*, #{ entry_columns }",
            :joins => "INNER JOIN entries ON entries.content_id = #{ self.table_name }.id AND entries.content_type = '#{ self.base_class.to_s }'" + container_conditions.to_s
          }
        }

        include CMS::Content::InstanceMethods
      end
      
      def mime_types
        Mime::Type.parse content_options[:atompub_mime_types]
      end

      # Returns the symbol for a set of Contents of this item
      # e.g. <tt>:articles</tt> for Article
      def collection
        self.to_s.tableize.to_sym
      end
      
      # Returns the word for a named collection of this item
      # a.g. <tt>"Gallery"</tt> for Photo
      def named_collection
        content_options[:named_collection] ? content_options[:named_collection].to_s : self.to_s.humanize.pluralize
      end

      # Returns the translated named collection for this item
      # a.g. <tt>"Galería"</tt> for Photo
      def translated_named_collection
        content_options[:named_collection] ? content_options[:named_collection].to_s.t : self.to_s.humanize.t(self.to_s.humanize.pluralize, 99)
      end

      protected

      # Atom Parser
      # Extracts parameter information from an Atom Element
      #
      # Implement this in your class if you want AtomPub support in your Content
      def atom_parser(data)
        {}
      end
    end

    module InstanceMethods
      # Returns the entry associated with this Content.
      #
      # It only works if the request have some Container:
      #   GET /container/1/content/ #=> @content.entry != nil
      # but
      #   GET /content/1 #=> @content.entry == nil
      #
      def entry
        @entry ||= if entry_attributes.any? 
                     e = Entry.new(entry_attributes)
                     if e.valid?
                       e.id = entry_attributes[:id]
                       e.instance_variable_set("@new_record", false)
                       e
                     else
                       nil
                     end
                  else 
                    nil
                  end
      end


      # Returns the mime type for this Content instance. 
      # TODO: Works with attachment_fu
      def mime_type
        respond_to?("content_type") ? Mime::Type.lookup(content_type) : nil
      end

      # Returns the Mime::Type symbol for this content
      def format
        mime_type ? mime_type.to_sym : Mime::HTML.to_sym
      end
      
      # Has this Content been posted in this Container? Is there any Entry linking both?
      def posted_in?(container)
        return false unless container
        content_entries.select{ |p| p.container == container }.any?
      end
      

      # Can this <tt>agent</tt> read this Content?
      # True if there exists a Entry for this Content that can be read by <tt>agent</tt> 
      def read_by?(agent = nil)
        content_entries.select{ |p| p.read_by?(agent) }.any?
      end

      # Method useful for icon files
      #
      # If the Content has a Mime Type, return it scaped with '-' 
      #   application/jpg => application-jpg
      # else, return the underscored class name:
      #   photo
      def mime_type_or_class_name
        mime_type ? mime_type.to_s.gsub(/[\/\+]/, '-') : self.class.to_s.underscore
      end

      private

      def entry_save! # :nodoc:
        if entry
          entry.content = self
          raise "Invalid entry when saving #{ self.inspect }" unless entry.valid?
          entry.save!
        else
          logger.warn "CMS Warning: Saving Content without an Entry"
          self.content_entries.map(&:save!)
        end
      end

      def entry_attributes #:nodoc:
        returning HashWithIndifferentAccess.new do |entry_attrs|
          attributes.each do |content_attr|
            entry_attrs[$1] = content_attr.last if content_attr.first =~ /^entry_(.*)$/
          end
        end
      end
    end
  end
end
