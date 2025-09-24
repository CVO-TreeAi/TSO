#!/usr/bin/env ruby

require 'xcodeproj'
require 'set'

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

puts "Starting deep clean of project file..."

# Remove duplicate file references from all groups
def remove_duplicate_refs(group, files_to_check, seen_refs)
  group.children.dup.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      file_name = File.basename(child.path || "")
      if files_to_check.include?(file_name)
        ref_key = "#{child.path}"
        if seen_refs.include?(ref_key)
          puts "Removing duplicate reference: #{file_name} at #{child.path}"
          group.children.delete(child)
        else
          seen_refs.add(ref_key)
          puts "Keeping reference: #{file_name} at #{child.path}"
        end
      end
    elsif child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      remove_duplicate_refs(child, files_to_check, seen_refs)
    end
  end
end

# Track seen references
seen_refs = Set.new

# Clean the main group
remove_duplicate_refs(project.main_group, files_to_check, seen_refs)

# Clean build phases
project.targets.each do |target|
  puts "\nCleaning target: #{target.name}"

  # Clean source build phase
  if target.source_build_phase
    seen_build_files = {}

    target.source_build_phase.files.dup.each do |build_file|
      if build_file.file_ref
        file_name = File.basename(build_file.file_ref.path || "")

        if files_to_check.include?(file_name)
          file_key = build_file.file_ref.path

          if seen_build_files[file_key]
            puts "Removing duplicate from build phase: #{file_name}"
            target.source_build_phase.files.delete(build_file)
          else
            seen_build_files[file_key] = true
            puts "Keeping in build phase: #{file_name}"
          end
        end
      end
    end
  end

  # Clean resources build phase
  if target.resources_build_phase
    seen_resource_files = {}

    target.resources_build_phase.files.dup.each do |build_file|
      if build_file.file_ref
        file_name = File.basename(build_file.file_ref.path || "")

        if files_to_check.include?(file_name)
          file_key = build_file.file_ref.path

          if seen_resource_files[file_key]
            puts "Removing duplicate from resources: #{file_name}"
            target.resources_build_phase.files.delete(build_file)
          else
            seen_resource_files[file_key] = true
          end
        end
      end
    end
  end
end

# Save the project
project.save
puts "\n✅ Project deep cleaned successfully!"
puts "Please perform the following in Xcode:"
puts "1. Clean Build Folder (Shift+Cmd+K)"
puts "2. Quit and restart Xcode"
puts "3. Build the project again"