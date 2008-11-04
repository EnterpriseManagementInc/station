class Logotype < ActiveRecord::Base
  has_attachment :max_size => 2.megabyte,
                 :content_type => :image, 
                 :thumbnails => { 
                   '256' => '256x256>', 
                   '128' => '128x128>', 
                   '96' => '96x96>',
                   '72' => '72x72>',
                   '64' => '64x64>',
                   '48' => '48x48>',
                   '32' => '32x32>',
                   '22' => '22x22>',
                   '16' => '16x16>'
                 }
                 
  alias_attribute :media, :uploaded_data
  attr_accessible :media

  belongs_to :db_file
  belongs_to :logotypable , :polymorphic => true

  validates_as_attachment

  def format
    Mime::Type.lookup(content_type).to_sym
  end
end
