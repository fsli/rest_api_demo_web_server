# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
def seed_roles
  Role.create(id: 1, name: 'admin')
  Role.create(id: 2, name: 'manager')
  Role.create(id: 3, name: 'user')
end

def seed_users
  for i in 1 ... 4    
    User.create(username: "user#{i}", password: '$2a$10$IoEbIw7rK3jiPE9OiyW6lOUh6wKQcHvYmg13I76abIlCO7ln0TqRq', salt: '$2a$10$IoEbIw7rK3jiPE9OiyW6lO', role_id: 3)
  end
end

def seed_managers
  for i in 1 ... 3
      User.create(username: "manager#{i}", password: '$2a$10$IoEbIw7rK3jiPE9OiyW6lOUh6wKQcHvYmg13I76abIlCO7ln0TqRq', salt: '$2a$10$IoEbIw7rK3jiPE9OiyW6lO', role_id: 2)
  end
end

def seed_admin
  User.create(username: 'admin', password: '$2a$10$IoEbIw7rK3jiPE9OiyW6lOUh6wKQcHvYmg13I76abIlCO7ln0TqRq', salt: '$2a$10$IoEbIw7rK3jiPE9OiyW6lO', role_id: 1)
end

seed_roles()
seed_admin()
seed_managers()
seed_users()