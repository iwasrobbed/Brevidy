collection @badges => :badges

node(:type) { |b| Icon.find_by_name(b[:name]).id }
node(:description) { |b| b[:name] }
node(:count) { |b| b[:count] }
