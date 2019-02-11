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
    
    triangles = triangulate_face(face, transformation)

    # TEST CODE
    triangles.each { |t| Sketchup.active_model.active_entities.add_face(t) }
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
    next unless instance?(entity)
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

# Get the triangles making up a face.
#
# @param face [Sketchup::Face]
# @param transformation [Geom::Transformation]
#   Transformation of the face.
#
# @return [Array<Array<(Geom::Point3d, Geom::Point3d, Geom::Point3d)>>]
def self.triangulate_face(face, transformation = IDENTITY)
  mesh = face.mesh
  incides = mesh.polygons.flatten.map(&:abs)
  points = incides.map { |i| mesh.point_at(i) }
  points.each { |pt| pt.transform!(transformation) }
  
  points.each_slice(3).to_a
end
