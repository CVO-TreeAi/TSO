#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group['TreeShopIOSApp']

# Create Scheduling group if it doesn't exist
scheduling_group = main_group['Scheduling'] || main_group.new_group('Scheduling')

# Add files to the Scheduling group
eventkit_file = scheduling_group.new_file('Scheduling/EventKitManager.swift')
scheduling_view_file = scheduling_group.new_file('Scheduling/SchedulingView.swift')

# Create CoreData group if needed and add WorkOrder file
coredata_group = main_group['CoreData'] || main_group.new_group('CoreData')
workorder_file = coredata_group.new_file('CoreData/CDWorkOrder+CoreDataClass.swift')

# Get the main target
target = project.targets.first

# Add files to build phases
target.source_build_phase.add_file_reference(eventkit_file)
target.source_build_phase.add_file_reference(scheduling_view_file)
target.source_build_phase.add_file_reference(workorder_file)

# Save the project
project.save

puts "Successfully added Scheduling files to Xcode project"