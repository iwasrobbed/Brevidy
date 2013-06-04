attributes :id, :content
if highlight_latest_activity?
  child(:video) { extends "videos/base" }
else
  attributes :video_id
  node(:created_at) { |c| c.created_at.to_i }
end
node(:from) { |c| partial("users/base", :object => User.find_by_id(c.user_id)) }