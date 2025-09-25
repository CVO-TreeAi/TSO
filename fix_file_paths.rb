#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'TreeShopIOSApp' }

# Remove incorrectly added files
files_to_remove = []
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref
    path = build_file.file_ref.path
    if path && path.include?('TreeShopIOSApp/TreeShopIOSApp/')
      files_to_remove << build_file
      puts "Removing incorrect path: #{path}"
    end
  end
end

files_to_remove.each do |build_file|
  target.source_build_phase.remove_build_file(build_file)
end

# Also remove from project groups
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    if child.path && child.path.include?('TreeShopIOSApp/TreeShopIOSApp/')
      puts "Removing file reference: #{child.path}"
      child.remove_from_project
    end
  end
end

# Get or create the correct groups
main_group = project.main_group['TreeShopIOSApp']
services_group = main_group['Services'] || main_group.new_group('Services')
views_group = main_group['Views'] || main_group.new_group('Views')
auth_group = views_group['Auth'] || views_group.new_group('Auth')
profile_group = views_group['Profile'] || views_group.new_group('Profile')

# Add files with correct paths
service_files = {
  'APIService.swift' => 'Services/APIService.swift',
  'SecurityService.swift' => 'Services/SecurityService.swift',
  'AuthenticationManager.swift' => 'Services/AuthenticationManager.swift',
  'CoreDataSyncManager.swift' => 'Services/CoreDataSyncManager.swift'
}

service_files.each do |filename, relative_path|
  full_path = "TreeShopIOSApp/#{relative_path}"
  if File.exist?(full_path)
    file_ref = services_group.new_file(full_path)
    target.add_file_references([file_ref])
    puts "Added #{full_path} with correct path"
  else
    puts "Warning: #{full_path} does not exist"
  end
end

# Add Auth views with correct paths
auth_files = {
  'LoginView.swift' => 'Views/Auth/LoginView.swift'
}

auth_files.each do |filename, relative_path|
  full_path = "TreeShopIOSApp/#{relative_path}"
  if File.exist?(full_path)
    file_ref = auth_group.new_file(full_path)
    target.add_file_references([file_ref])
    puts "Added #{full_path} with correct path"
  else
    puts "Warning: #{full_path} does not exist"
  end
end

# Add Profile views with correct paths
profile_files = {
  'ProfileView.swift' => 'Views/Profile/ProfileView.swift'
}

profile_files.each do |filename, relative_path|
  full_path = "TreeShopIOSApp/#{relative_path}"
  if File.exist?(full_path)
    file_ref = profile_group.new_file(full_path)
    target.add_file_references([file_ref])
    puts "Added #{full_path} with correct path"
  else
    puts "Warning: #{full_path} does not exist"
  end
end

# Save the project
project.save

puts "\nFixed file paths in Xcode project!"