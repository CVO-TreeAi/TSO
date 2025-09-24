#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/ain/TreeShopIOSApp/TreeShopIOSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get main group
main_group = project.main_group['TreeShopIOSApp']

# Create or get Models group
models_group = main_group['Models'] || main_group.new_group('Models')

# Create TreeScore subgroup
treescore_group = models_group['TreeScore'] || models_group.new_group('TreeScore')

# Add TreeScore model files
treescore_files = [
  'TreeScoreCalculator.swift',
  'TreeInventoryItem.swift'
]

treescore_files.each do |file|
  file_path = "Models/TreeScore/#{file}"
  unless treescore_group.find_file_by_path(file_path)
    file_ref = treescore_group.new_reference(file_path)
    project.targets.first.add_file_references([file_ref])
    puts "Added #{file} to TreeScore group"
  end
end

# Get or create Maps group
maps_group = main_group['Maps'] || main_group.new_group('Maps')

# Add AdvancedWorkOrderMapView
advanced_map_file = 'AdvancedWorkOrderMapView.swift'
advanced_map_path = "Maps/#{advanced_map_file}"
unless maps_group.find_file_by_path(advanced_map_path)
  file_ref = maps_group.new_reference(advanced_map_path)
  project.targets.first.add_file_references([file_ref])
  puts "Added #{advanced_map_file} to Maps group"
end

# Get Views group
views_group = main_group['Views']

# Add OpsPricingCalculatorView
pricing_file = 'OpsPricingCalculatorView.swift'
pricing_path = "Views/#{pricing_file}"
unless views_group.find_file_by_path(pricing_path)
  file_ref = views_group.new_reference(pricing_path)
  project.targets.first.add_file_references([file_ref])
  puts "Added #{pricing_file} to Views group"
end

# Save the project
project.save
puts "Successfully added all Maps integration files to Xcode project"