Factory.define(:user) do |f|
  f.name {Faker::Name.first_name}
  f.password_hash {User.sha1("password")}
  f.email {Faker::Internet.email}
end

Factory.define(:banned_user, :parent => :user) do |f|
  f.is_banned true
end

Factory.define(:privileged_user, :parent => :user) do |f|
  f.is_privileged true
end

Factory.define(:contributor_user, :parent => :user) do |f|
  f.is_contributor true
end

Factory.define(:janitor_user, :parent => :user) do |f|
  f.is_janitor true
end

Factory.define(:moderator_user, :parent => :user) do |f|
  f.is_moderator true
end

Factory.define(:admin_user, :parent => :user) do |f|
  f.is_admin true
end
