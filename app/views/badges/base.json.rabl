attributes :id
if highlight_latest_activity?
  child(:video) { extends "videos/base" }
else
  attributes :video_id
end
node(:from) { |b| puts b.inspect; partial("users/base", :object => User.find_by_id(b.badge_from)) }
node(:type) { |b| b.badge_type }
node(:description) { |b| Icon.find(b.badge_type).name }