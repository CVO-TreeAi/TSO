#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project = Xcodeproj::Project.open('TreeShopIOSApp.xcodeproj')

# Get the main target
target = project.targets.first

# Find the main group
main_group = project.main_group['TreeShopIOSApp']

puts "Adding missing files to project..."

# Files to add with their group paths
files_to_add = {
  'Maps/DrawingManager.swift' => 'Maps',
  'Managers/AddressSearchManager.swift' => 'Managers'
}

files_to_add.each do |file_path, group_name|
  full_path = "TreeShopIOSApp/#{file_path}"
  relative_path = File.basename(file_path)

  # Find or create the group
  group = main_group[group_name]
  if group.nil?
    puts "Creating group: #{group_name}"
    group = main_group.new_group(group_name)
  end

  # Check if file already exists in the group
  existing_file = group.files.find { |f| f.path == relative_path }

  if existing_file.nil? && File.exist?(full_path)
    puts "Adding file: #{file_path}"
    file_ref = group.new_reference(relative_path)
    target.add_file_references([file_ref])
  elsif existing_file
    puts "File already in project: #{file_path}"
  else
    puts "File not found: #{full_path}"
  end
end

# Save the project
project.save

puts "Done! Files added to project."