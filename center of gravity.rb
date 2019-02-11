def self.center_of_grafity(entities = Sketchup.active_model.selection)
  # To find center of gravity, iterate the tetrahedrons defined by all faces in
  # the meshes and an arbitrarily selected "tip" point. Sum the volumes of the
  # tetrahedrons corresponding to faces facing away from the tip, and subtract
  # the volume of those facing towards it (forming a cavity).
  
  point = Geom::Point3d.new
  volume = 0
  # TODO: Use center of entities to reduce deviations due to floating point
  # precision.
  tip_point = ORIGIN
  
  # TEST CODE
  Sketchup.active_model.start_operation("TEST")
  
  traverse_entities(entities) do |face, transformation|
    next unless face.is_a?(Sketchup::Face)
    
    # Get triangles from face.
    mesh = face.mesh
    triangles_point_indices = mesh.polygons
    triangles = triangles_point_indices.map { |t| t.map { |i| mesh.point_at(i.abs) }}
    
    # Transform triangles to global coordinates.
    triangles.each { |t| t.each { |pt| pt.transform!(transformation) }}
    
    triangles.each { |t| Sketchup.active_model.active_entities.add_face(t) }
    
    # TEST CODE
    #position = face.vertices.first.position.transform(transformation)
    #puts position
    #Sketchup.active_model.entities.add_text("Corner", position, Geom::Vector3d.new(1.m, 1.m, 1.m))
  end
  
  
  # TEST CODE
  Sketchup.active_model.commit_operation
  
  
  divide_point(point, volume)
end

def divide_point(point, denominator)
  Geom::Point3d.new(point.to_a.map { |c| c / denominator } )
end

def multiply_point(point, factor)
  Geom::Point3d.new(point.to_a.map { |c| c * factor } )
end

# Traverse entities recursively.
#
# @param entities [Array<Sketchup::Entity>, Sketchup::Entities]
# @param transformation [Geom::Transformation]
#
# @yieldparam entity [Sketchup::Entity]
# @yieldparam transformation [Geom::Transformation]
#   The local transformation. Multiply coordinates from entity with this to get
#   them all in the same coordinate system.
#
# @return [Void]
def self.traverse_entities(entities, transformation = IDENTITY, &block)
  entities.each do |entity|
    block.call(entity, transformation)
    return unless instance?(entity)
    traverse_entities(
      entity.definition.entities,
      transformation * entity.transformation,
      &block
    )
  end
end

# Test if entity is either group or component instance.
#
# @param entity [Sketchup::Entity]
#
# @return [Boolean]
def self.instance?(entity)
  entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
end


