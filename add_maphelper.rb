#!/usr/bin/env ruby

require 'xcodeproj'

project = Xcodeproj::Project.open('TreeShopIOSApp.xcodeproj')
main_group = project.main_group['TreeShopIOSApp']

# Create Helpers group if it doesn't exist
helpers_group = main_group['Helpers'] || main_group.new_group('Helpers')

# Check if MapHelper.swift already exists
existing = helpers_group.files.find { |f| f.path == 'MapHelper.swift' }

if !existing
  file_ref = helpers_group.new_reference('Helpers/MapHelper.swift')
  project.targets.first.add_file_references([file_ref])
  puts 'Added MapHelper.swift to project'
else
  puts 'MapHelper.swift already in project'
end

project.save
puts 'Done!'