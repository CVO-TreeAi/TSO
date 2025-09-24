#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group['TreeShopIOSApp']

# Create Maps group if it doesn't exist
maps_group = main_group['Maps'] || main_group.new_group('Maps')

# Add files to the Maps group
customer_map_file = maps_group.new_file('Maps/CustomerMapView.swift')
location_picker_file = maps_group.new_file('Maps/LocationPicker.swift')

# Get the main target
target = project.targets.first

# Add files to build phases
target.source_build_phase.add_file_reference(customer_map_file)
target.source_build_phase.add_file_reference(location_picker_file)

# Save the project
project.save

puts "Successfully added Maps files to Xcode project"