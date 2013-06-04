require 'spec_helper'

describe VideoGraph do
  
  before do
    @video = FactoryGirl.create(:video)
    @vg = @video.video_graph
  end
    
  describe "protected attributes" do
    it "should prevent mass assignment" do
      @vg.should_not allow_mass_assignment_of(:thumbnail_path => "hello/there")
      @vg.should_not allow_mass_assignment_of(:path => "yes/sir")
      @vg.should_not allow_mass_assignment_of(:callback_url => "http://poop.com")
      @vg.should_not allow_mass_assignment_of(:base_filename => "asdf1234")
      @vg.should_not allow_mass_assignment_of(:encoding_type => "enc20")
      @vg.should_not allow_mass_assignment_of(:thumbnail_type => "thumb20")
      @vg.should_not allow_mass_assignment_of(:status => 999999)
      @vg.should_not allow_mass_assignment_of(:zencoder_job_id => 999999)
      @vg.should_not allow_mass_assignment_of(:remote_host => "vimeo.com")
      @vg.should_not allow_mass_assignment_of(:remote_video_id => "zxcv")
      @vg.should_not allow_mass_assignment_of(:submitting_error_count => 5)
      @vg.should_not allow_mass_assignment_of(:transcoding_error_count => 9)
      @vg.should_not allow_mass_assignment_of(:error_message => "oops")
      @vg.should_not allow_mass_assignment_of(:user_id => 999999)
      @vg.should_not allow_mass_assignment_of(:deleted => true)
    end
  end
  
  describe "lifecycle actions" do
    it "should populate the base filename" do
      @vg.base_filename.should_not be_nil
    end
    it "should populate the path and thumbnail_path" do
      @vg.path.should_not be_nil
      @vg.thumbnail_path.should_not be_nil
    end
  end
  
  describe "validations" do
    it "should require a user_id" do
      bad_vg = FactoryGirl.build(:video_graph, :user_id => nil)
      bad_vg.save
      bad_vg.should_not be_valid
      bad_vg.errors['user_id'].should_not be_empty
      
      good_vg = FactoryGirl.build(:video_graph, :user_id => 999)
      good_vg.save
      good_vg.should be_valid
      good_vg.errors['user_id'].should be_empty
    end
    it "should require a base_filename" do
      bad_vg = FactoryGirl.create(:video_graph)
      bad_vg.base_filename = nil
      bad_vg.save
      bad_vg.should_not be_valid
      bad_vg.errors['base_filename'].should_not be_empty
      
      good_vg = FactoryGirl.create(:video_graph)
      good_vg.should be_valid
      good_vg.errors['base_filename'].should be_empty
    end
    it "should require an encoding_type" do
      bad_vg = FactoryGirl.create(:video_graph)
      bad_vg.encoding_type = nil
      bad_vg.save
      bad_vg.should_not be_valid
      bad_vg.errors['encoding_type'].should_not be_empty
      
      good_vg = FactoryGirl.create(:video_graph)
      good_vg.should be_valid
      good_vg.errors['encoding_type'].should be_empty
    end
    it "should require a thumbnail_type" do
      bad_vg = FactoryGirl.create(:video_graph)
      bad_vg.thumbnail_type = nil
      bad_vg.save
      bad_vg.should_not be_valid
      bad_vg.errors['thumbnail_type'].should_not be_empty
      
      good_vg = FactoryGirl.create(:video_graph)
      good_vg.should be_valid
      good_vg.errors['thumbnail_type'].should be_empty
    end
    it "should require a status" do
      bad_vg = FactoryGirl.create(:video_graph)
      bad_vg.status = nil
      bad_vg.save
      bad_vg.should_not be_valid
      bad_vg.errors['status'].should_not be_empty
      
      good_vg = FactoryGirl.create(:video_graph)
      good_vg.should be_valid
      good_vg.errors['status'].should be_empty
    end
    it "should require the remote_host to only be youtube or vimeo domains" do      
      bad_vg = FactoryGirl.build(:video_graph, :remote_host => "not-a-valid-domain.com")
      bad_vg.save
      bad_vg.should_not be_valid
      bad_vg.errors['remote_host'].should_not be_empty
      
      good_vg = FactoryGirl.build(:video_graph, :remote_host => "vimeo.com")
      good_vg.save
      good_vg.should be_valid
      good_vg.errors['remote_host'].should be_empty
      
      good_vg = FactoryGirl.build(:video_graph, :remote_host => "youtube.com")
      good_vg.save
      good_vg.should be_valid
      good_vg.errors['remote_host'].should be_empty
      
      good_vg = FactoryGirl.build(:video_graph, :remote_host => "youtu.be")
      good_vg.save
      good_vg.should be_valid
      good_vg.errors['remote_host'].should be_empty
    end
  end
end


# == Schema Information
#
# Table name: video_graphs
#
#  id                      :integer         not null, primary key
#  thumbnail_path          :string(255)
#  path                    :string(255)
#  callback_url            :string(255)
#  base_filename           :string(255)
#  encoding_type           :string(255)     default("enc1")
#  thumbnail_type          :string(255)     default("thumb1")
#  status                  :integer         default(0)
#  zencoder_job_id         :integer
#  remote_host             :string(255)
#  remote_video_id         :string(255)
#  remote_thumbnail        :string(255)
#  delta                   :boolean         default(TRUE), not null
#  created_at              :datetime
#  updated_at              :datetime
#  submitting_error_count  :integer         default(0)
#  transcoding_error_count :integer         default(0)
#  error_message           :text
#  user_id                 :integer
#  deleted                 :boolean         default(FALSE)
#

