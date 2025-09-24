#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/ain/TreeShopIOSApp/TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to check for duplicates
files_to_check = [
  'TreeScoreCalculator.swift',
  'TreeInventoryItem.swift',
  'AdvancedWorkOrderMapView.swift',
  'OpsPricingCalculatorView.swift'
]

# Get the main target
target = project.targets.first

# Track files we've seen
seen_files = {}

# Find and remove duplicate file references from the target
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref
    file_name = File.basename(build_file.file_ref.real_path.to_s)

    if files_to_check.include?(file_name)
      if seen_files[file_name]
        puts "Removing duplicate: #{file_name}"
        target.source_build_phase.remove_file_reference(build_file.file_ref)
      else
        seen_files[file_name] = true
        puts "Keeping: #{file_name}"
      end
    end
  end
end

# Also check and remove duplicate references in the file structure
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    file_name = File.basename(child.real_path.to_s) rescue nil
    if files_to_check.include?(file_name)
      # Count how many references exist
      refs = project.main_group.recursive_children.select do |c|
        c.is_a?(Xcodeproj::Project::Object::PBXFileReference) &&
        (File.basename(c.real_path.to_s) rescue nil) == file_name
      end

      if refs.count > 1
        puts "Found #{refs.count} references to #{file_name} in project structure"
      end
    end
  end
end

# Save the project
project.save
puts "\nProject cleaned. Please clean build folder in Xcode (Shift+Cmd+K) and rebuild."