#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'TreeShopIOSApp' }

# Get the main group
main_group = project.main_group['TreeShopIOSApp']

# Create groups if they don't exist
services_group = main_group['Services'] || main_group.new_group('Services')
views_group = main_group['Views'] || main_group.new_group('Views')
auth_group = views_group['Auth'] || views_group.new_group('Auth')
profile_group = views_group['Profile'] || views_group.new_group('Profile')
tests_group = project.main_group['TreeShopIOSAppTests'] || project.main_group.new_group('TreeShopIOSAppTests')

# Add Service files
service_files = [
  'TreeShopIOSApp/Services/APIService.swift',
  'TreeShopIOSApp/Services/SecurityService.swift',
  'TreeShopIOSApp/Services/AuthenticationManager.swift',
  'TreeShopIOSApp/Services/CoreDataSyncManager.swift'
]

service_files.each do |file_path|
  if File.exist?(file_path)
    file_ref = services_group.new_file(file_path)
    target.add_file_references([file_ref])
    puts "Added #{file_path}"
  end
end

# Add Auth View files
auth_files = [
  'TreeShopIOSApp/Views/Auth/LoginView.swift'
]

auth_files.each do |file_path|
  if File.exist?(file_path)
    file_ref = auth_group.new_file(file_path)
    target.add_file_references([file_ref])
    puts "Added #{file_path}"
  end
end

# Add Profile View files
profile_files = [
  'TreeShopIOSApp/Views/Profile/ProfileView.swift'
]

profile_files.each do |file_path|
  if File.exist?(file_path)
    file_ref = profile_group.new_file(file_path)
    target.add_file_references([file_ref])
    puts "Added #{file_path}"
  end
end

# Add Test files (but not to main target)
test_files = [
  'TreeShopIOSAppTests/TreeScoreCalculatorTests.swift',
  'TreeShopIOSAppTests/CoreDataTests.swift',
  'TreeShopIOSAppTests/LoadoutManagerTests.swift'
]

# Check if test target exists, if not create it
test_target = project.targets.find { |t| t.name == 'TreeShopIOSAppTests' }
if test_target.nil?
  test_target = project.new_target(
    :unit_test_bundle,
    'TreeShopIOSAppTests',
    :ios,
    '17.0'
  )
  test_target.add_dependency(target)
  puts "Created test target"
end

test_files.each do |file_path|
  if File.exist?(file_path)
    file_ref = tests_group.new_file(file_path)
    test_target.add_file_references([file_ref])
    puts "Added #{file_path} to test target"
  end
end

# Save the project
project.save

puts "\nSuccessfully added all authentication and test files to the project!"