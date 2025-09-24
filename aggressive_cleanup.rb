#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/ain/TreeShopIOSApp/TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to deduplicate
files_to_check = {
  'TreeScoreCalculator.swift' => 'Models/TreeScore/TreeScoreCalculator.swift',
  'TreeInventoryItem.swift' => 'Models/TreeScore/TreeInventoryItem.swift',
  'AdvancedWorkOrderMapView.swift' => 'Maps/AdvancedWorkOrderMapView.swift',
  'OpsPricingCalculatorView.swift' => 'Views/OpsPricingCalculatorView.swift'
}

puts "Aggressively removing all duplicates..."

# Step 1: Remove ALL references to these files from everywhere
def remove_all_refs(group, files_to_check)
  removed = []
  group.children.dup.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      file_name = File.basename(child.path || "")
      if files_to_check.keys.include?(file_name)
        puts "Removing reference: #{child.path}"
        group.children.delete(child)
        removed << child
      end
    elsif child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      removed += remove_all_refs(child, files_to_check)
    end
  end
  removed
end

# Remove all references
all_removed = remove_all_refs(project.main_group, files_to_check)

# Step 2: Remove from all build phases
project.targets.each do |target|
  if target.source_build_phase
    target.source_build_phase.files.dup.each do |build_file|
      if build_file.file_ref
        file_name = File.basename(build_file.file_ref.path || "")
        if files_to_check.keys.include?(file_name)
          puts "Removing from build phase: #{file_name}"
          target.source_build_phase.files.delete(build_file)
        end
      end
    end
  end
end

# Step 3: Add back single references with correct paths
puts "\nAdding back single references..."

main_group = project.main_group['TreeShopIOSApp']

# Create groups if they don't exist
models_group = main_group['Models'] || main_group.new_group('Models')
treescore_group = models_group['TreeScore'] || models_group.new_group('TreeScore')
maps_group = main_group['Maps'] || main_group.new_group('Maps')
views_group = main_group['Views'] || main_group.new_group('Views')

# Add TreeScore files
['TreeScoreCalculator.swift', 'TreeInventoryItem.swift'].each do |file|
  file_ref = treescore_group.new_reference(files_to_check[file])
  project.targets.first.add_file_references([file_ref])
  puts "Added: #{file} to TreeScore group"
end

# Add Map file
file_ref = maps_group.new_reference(files_to_check['AdvancedWorkOrderMapView.swift'])
project.targets.first.add_file_references([file_ref])
puts "Added: AdvancedWorkOrderMapView.swift to Maps group"

# Add View file
file_ref = views_group.new_reference(files_to_check['OpsPricingCalculatorView.swift'])
project.targets.first.add_file_references([file_ref])
puts "Added: OpsPricingCalculatorView.swift to Views group"

# Save the project
project.save

puts "\n✅ Aggressive cleanup complete!"
puts "All duplicates removed and files re-added with correct paths."
puts "\nNow in Xcode:"
puts "1. Clean Build Folder (Shift+Cmd+K)"
puts "2. Close Xcode completely"
puts "3. Delete DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData/TreeShopIOSApp-*"
puts "4. Reopen Xcode and build"