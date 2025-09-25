#!/usr/bin/env ruby

require 'xcodeproj'
require 'set'

# Open the project
project_path = 'TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'TreeShopIOSApp' }

# Track files we've already seen to avoid duplicates
seen_files = Set.new
files_to_remove = []

# Find and remove duplicate build files
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref
    path = build_file.file_ref.path
    if path
      # Extract just the filename for comparison
      filename = File.basename(path)

      # Check if this is a duplicate
      if seen_files.include?(filename)
        files_to_remove << build_file
        puts "Removing duplicate build file: #{path}"
      else
        seen_files.add(filename)
      end
    end
  end
end

# Remove duplicate build files
files_to_remove.each do |build_file|
  target.source_build_phase.remove_build_file(build_file)
end

# Clean up duplicate file references in groups
def clean_group_duplicates(group)
  seen_in_group = Set.new
  refs_to_remove = []

  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      filename = File.basename(child.path || "")
      if seen_in_group.include?(filename)
        refs_to_remove << child
        puts "Removing duplicate file reference: #{child.path}"
      else
        seen_in_group.add(filename)
      end
    elsif child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      clean_group_duplicates(child)
    end
  end

  refs_to_remove.each { |ref| ref.remove_from_project }
end

# Clean all groups
project.main_group.groups.each do |group|
  clean_group_duplicates(group)
end

# Save the project
project.save

puts "\nSuccessfully cleaned up #{files_to_remove.size} duplicate files from the project!"