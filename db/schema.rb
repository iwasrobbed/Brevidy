# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130604202246) do

  create_table "badges", :force => true do |t|
    t.integer  "video_id"
    t.integer  "badge_type"
    t.integer  "badge_from"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "badges", ["badge_from"], :name => "index_badges_on_badge_from"
  add_index "badges", ["badge_type"], :name => "index_badges_on_badge_type"
  add_index "badges", ["created_at"], :name => "index_badges_on_created_at"
  add_index "badges", ["video_id"], :name => "index_badges_on_video_id"

  create_table "banned_users", :force => true do |t|
    t.string   "email"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "detailed_reason"
  end

  add_index "banned_users", ["email"], :name => "index_banned_users_on_email"

  create_table "banner_images", :force => true do |t|
    t.string   "path"
    t.string   "filename"
    t.boolean  "active",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "banner_images", ["active"], :name => "index_banner_images_on_active"

  create_table "blockings", :force => true do |t|
    t.integer  "requesting_user"
    t.integer  "blocked_user"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blockings", ["blocked_user"], :name => "index_blockings_on_blocked_user"
  add_index "blockings", ["requesting_user"], :name => "index_blockings_on_requesting_user"

  create_table "channel_requests", :force => true do |t|
    t.integer  "channel_id"
    t.integer  "user_id"
    t.string   "token"
    t.boolean  "ignored",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "channel_requests", ["channel_id"], :name => "index_channel_requests_on_channel_id"
  add_index "channel_requests", ["token"], :name => "index_channel_requests_on_token"
  add_index "channel_requests", ["user_id"], :name => "index_channel_requests_on_user_id"

  create_table "channels", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.boolean  "private",      :default => false
    t.boolean  "featured",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "public_token"
    t.boolean  "recommended",  :default => false
  end

  add_index "channels", ["created_at", "updated_at"], :name => "index_channels_on_created_at_and_updated_at"
  add_index "channels", ["featured"], :name => "index_channels_on_featured"
  add_index "channels", ["private"], :name => "index_channels_on_private"
  add_index "channels", ["public_token"], :name => "index_channels_on_public_token"
  add_index "channels", ["recommended"], :name => "index_channels_on_recommended"
  add_index "channels", ["user_id"], :name => "index_channels_on_user_id"

  create_table "comments", :force => true do |t|
    t.integer  "video_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content"
    t.integer  "user_id"
  end

  add_index "comments", ["created_at"], :name => "index_comments_on_created_at"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"
  add_index "comments", ["video_id"], :name => "index_comments_on_video_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "flags", :force => true do |t|
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "icons", :force => true do |t|
    t.string   "name"
    t.string   "css_class"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_type"
  end

  add_index "icons", ["active"], :name => "index_icons_on_active"

  create_table "invitation_links", :force => true do |t|
    t.integer  "user_id"
    t.string   "email_asking_for_invite"
    t.integer  "invitation_limit"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "has_been_invited",        :default => true
    t.integer  "click_count",             :default => 0
  end

  add_index "invitation_links", ["email_asking_for_invite"], :name => "index_invitation_links_on_email_asking_for_invite"
  add_index "invitation_links", ["token"], :name => "index_invitation_links_on_token"
  add_index "invitation_links", ["user_id"], :name => "index_invitation_links_on_user_id"

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.text     "interests"
    t.text     "favorite_music"
    t.text     "favorite_movies"
    t.text     "favorite_books"
    t.text     "favorite_people"
    t.text     "things_i_could_live_without"
    t.text     "one_thing_i_would_change_in_the_world"
    t.text     "quotes_to_live_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "favorite_foods"
    t.string   "bio"
    t.string   "website"
  end

  add_index "profiles", ["user_id"], :name => "index_profiles_on_user_id"

  create_table "restricted_usernames", :force => true do |t|
    t.string   "username"
    t.boolean  "inclusive",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "restricted_usernames", ["inclusive"], :name => "index_restricted_usernames_on_inclusive"
  add_index "restricted_usernames", ["username"], :name => "index_restricted_usernames_on_username"

  create_table "settings", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "hide_getting_started",                      :default => false
    t.boolean  "send_email_for_new_badges",                 :default => true
    t.boolean  "send_email_for_new_comments",               :default => true
    t.boolean  "send_email_for_replies_to_a_prior_comment", :default => true
    t.boolean  "send_email_for_new_subscriber",             :default => true
    t.boolean  "send_email_for_featured_video",             :default => true
    t.boolean  "send_email_for_private_channel_request",    :default => true
    t.boolean  "send_email_for_encoding_completion",        :default => true
  end

  add_index "settings", ["user_id"], :name => "index_settings_on_user_id"

  create_table "social_networks", :force => true do |t|
    t.string   "uid"
    t.string   "provider"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token"
    t.integer  "user_id"
    t.string   "token_secret"
  end

  add_index "social_networks", ["provider"], :name => "index_social_networks_on_provider"
  add_index "social_networks", ["token_secret"], :name => "index_social_networks_on_token_secret"
  add_index "social_networks", ["uid"], :name => "index_social_networks_on_uid"
  add_index "social_networks", ["user_id"], :name => "index_social_networks_on_user_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "subscriber_id"
    t.integer  "publisher_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "channel_id"
    t.boolean  "collaborator",  :default => false
  end

  add_index "subscriptions", ["channel_id"], :name => "index_subscriptions_on_channel_id"
  add_index "subscriptions", ["created_at"], :name => "index_subscriptions_on_created_at"
  add_index "subscriptions", ["publisher_id"], :name => "index_subscriptions_on_publisher_id"
  add_index "subscriptions", ["subscriber_id"], :name => "index_subscriptions_on_subscriber_id"

  create_table "taggings", :force => true do |t|
    t.integer  "video_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "video_owner_id"
  end

  add_index "taggings", ["created_at"], :name => "index_taggings_on_created_at"
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["video_id"], :name => "index_taggings_on_video_id"
  add_index "taggings", ["video_owner_id"], :name => "index_taggings_on_video_owner_id"

  create_table "tags", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content"
  end

  create_table "user_events", :force => true do |t|
    t.integer  "event_type"
    t.integer  "event_object_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "event_creator_id"
    t.boolean  "error_during_render", :default => false
    t.boolean  "seen_by_user",        :default => false
  end

  add_index "user_events", ["created_at"], :name => "index_user_events_on_created_at"
  add_index "user_events", ["event_object_id"], :name => "index_user_events_on_event_object_id"
  add_index "user_events", ["event_type"], :name => "index_user_events_on_event_type"
  add_index "user_events", ["seen_by_user"], :name => "index_user_events_on_seen_by_user"
  add_index "user_events", ["user_id"], :name => "index_user_events_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.string   "salt"
    t.string   "name"
    t.string   "image"
    t.date     "birthday"
    t.string   "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location"
    t.string   "reset_token"
    t.datetime "pw_reset_timestamp"
    t.string   "image_status"
    t.boolean  "is_deactivated",      :default => false
    t.boolean  "delta",               :default => true,  :null => false
    t.string   "username"
    t.string   "banner_image"
    t.integer  "banner_image_id",     :default => 1
    t.datetime "username_changed_at"
    t.integer  "background_image_id", :default => 0
  end

  add_index "users", ["created_at"], :name => "index_users_on_created_at"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username"

  create_table "video_errors", :force => true do |t|
    t.integer  "video_graph_id"
    t.integer  "error_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "error_message"
    t.integer  "user_id"
  end

  create_table "video_flags", :force => true do |t|
    t.integer  "flag_id"
    t.integer  "video_id"
    t.integer  "flagged_by"
    t.text     "detailed_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_flags", ["flag_id"], :name => "index_video_flags_on_flag_id"
  add_index "video_flags", ["flagged_by"], :name => "index_video_flags_on_flagged_by"
  add_index "video_flags", ["video_id"], :name => "index_video_flags_on_video_id"

  create_table "video_graphs", :force => true do |t|
    t.string   "thumbnail_path"
    t.string   "path"
    t.string   "callback_url"
    t.string   "base_filename"
    t.string   "encoding_type",           :default => "enc1"
    t.string   "thumbnail_type",          :default => "thumb1"
    t.integer  "status",                  :default => 0
    t.integer  "zencoder_job_id"
    t.string   "remote_host"
    t.string   "remote_video_id"
    t.string   "remote_thumbnail"
    t.boolean  "delta",                   :default => true,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitting_error_count",  :default => 0
    t.integer  "transcoding_error_count", :default => 0
    t.text     "error_message"
    t.integer  "user_id"
    t.boolean  "deleted",                 :default => false
  end

  add_index "video_graphs", ["base_filename"], :name => "index_video_graphs_on_base_filename"
  add_index "video_graphs", ["deleted"], :name => "index_video_graphs_on_deleted"
  add_index "video_graphs", ["remote_host"], :name => "index_video_graphs_on_remote_host"
  add_index "video_graphs", ["remote_video_id"], :name => "index_video_graphs_on_remote_video_id"
  add_index "video_graphs", ["status"], :name => "index_video_graphs_on_status"

  create_table "videos", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delta",              :default => true,  :null => false
    t.integer  "selected_thumbnail", :default => 0
    t.string   "public_token"
    t.boolean  "send_to_facebook",   :default => false
    t.boolean  "send_to_twitter",    :default => false
    t.integer  "video_graph_id"
    t.integer  "channel_id"
    t.string   "title"
    t.text     "description"
    t.datetime "featured_at"
  end

  add_index "videos", ["channel_id"], :name => "index_videos_on_channel_id"
  add_index "videos", ["created_at"], :name => "index_videos_on_created_at"
  add_index "videos", ["featured_at"], :name => "index_videos_on_featured_at"
  add_index "videos", ["public_token"], :name => "index_videos_on_public_token"
  add_index "videos", ["user_id"], :name => "index_videos_on_user_id"
  add_index "videos", ["video_graph_id"], :name => "index_videos_on_video_graph_id"

end
