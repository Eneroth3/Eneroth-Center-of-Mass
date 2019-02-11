def self.center_of_grafity(entities = Sketchup.active_model.selection)
  # To find center of gravity, iterate the tetrahedrons defined by all faces in
  # the meshes and an arbitrarily selected "tip" point. Sum the volumes of the
  # tetrahedrons corresponding to faces facing away from the tip, and subtract
  # the volume of those facing towards it (forming a cavity).

  center = Geom::Point3d.new
  volume = 0
  # TODO: Use approximate center of entities to reduce deviations due to
  # floating point precision (typically bounding box center).
  tip_point = ORIGIN

  # TODO: Separate recursive loop of instances from loop of faces inside them
  # and calculate the volume for each instance separately, so it can be
  # multiplied by its density.
  traverse_entities(entities) do |face, transformation|
    next unless face.is_a?(Sketchup::Face)
    triangles = triangulate_face(face, transformation)
    tetrahedrons = triangles.map { |t| t.push(tip_point) }
    tetrahedrons.each do |tetrahedron|
      tetra_volume = tetrahedron_volume(tetrahedron)
      # TODO: Negate local volume when transformation is flipped.
      volume += tetra_volume
      tetra_center = tetrahedron_center(tetrahedron)
      center = add_point(center, multiply_point(tetra_center, tetra_volume))
    end
  end

  divide_point(center, volume)
end

# Calculate volume of tetrahedron.
# TODO: Assure volume is negative when the tip point is in the direction of the
# normal of the opposite face.
def tetrahedron_volume(tetrahedron)
  a, b, c, d = tetrahedron

  ((a - d) % ((b - d) * (c - d))) / 6
end

def tetrahedron_center(tetrahedron)
  a, b, c, d = tetrahedron

  Geom::Point3d.new(
    (a.x + b.x + c.x + d.x ) / 4,
    (a.y + b.y + c.y + d.y ) / 4,
    (a.z + b.z + c.z + d.z ) / 4,
  )
end

# TODO: Extend Point3d with +, +=, *, *=, / and /=.
def divide_point(point, denominator)
  Geom::Point3d.new(point.to_a.map { |c| c / denominator } )
end

def multiply_point(point, factor)
  Geom::Point3d.new(point.to_a.map { |c| c * factor } )
end

def add_point(point1, point2)
  Geom::Point3d.new(point1.x + point2.x, point1.y + point2.y, point1.z + point2.z)
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
