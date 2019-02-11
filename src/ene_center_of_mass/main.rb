module Eneroth
  module CenterOfMass
    Sketchup.require(File.join(PLUGIN_DIR, "point_math"))
    Sketchup.require(File.join(PLUGIN_DIR, "vendor", "cmty-lib", "entity"))
    Sketchup.require(File.join(PLUGIN_DIR, "vendor", "cmty-lib", "geom", "transformation"))

    using PointMath

    # Find center of mass for entities.
    #
    # Note that no checks are done to see if the entities are solid.
    #
    # @param entities [Array<Sketchup::Entity>, Sketchup::Entities,
    #   Sketchup::Selection]
    #
    # @return [Geom::Point3d]
    def self.center_of_mass(entities = Sketchup.active_model.selection)
      # To find center of mass, iterate over all the triangles in the entities
      # and form tetrahedrons between them and an arbitrary tip point.
      # Weight the tetrahedron centers by the tetrahedron volume and sum them.
      #
      # Tetrahedrons formed by triangles facing towards the arbitrary tip can be
      # though of as cavities inside the body, and are regarded to have negative
      # volume.

      center = Geom::Point3d.new
      volume = 0
      # Reduce floating point deviations by locating arbitrary tip within body.
      tip_point = aprox_center(entities)

      # TODO: Separate recursive loop of instances from loop of faces inside
      # them and calculate the volume for each instance separately, so it can be
      # multiplied by its density.
      traverse_entities(entities) do |face, transformation|
        next unless face.is_a?(Sketchup::Face)
        triangles = triangulate_face(face, transformation)
        tetrahedrons = triangles.map { |t| t.push(tip_point) }
        tetrahedrons.each do |tetrahedron|
          tetra_volume = tetrahedron_volume(tetrahedron)
          tetra_volume *= -1 if LGeom::LTransformation.flipped?(transformation)
          volume += tetra_volume
          tetra_center = tetrahedron_center(tetrahedron)
          center += tetra_center * tetra_volume
        end
      end

      center / volume
    end

    # Find approximate center point for entities (from bounding box).
    #
    # @param entities [Array<Sketchup::Entity>, Sketchup::Entities,
    #   Sketchup::Selection]
    #
    # @return [Geom::Point3d]
    def self.aprox_center(entities)
      bb = Geom::BoundingBox.new
      entities.each { |e| bb.add(e.bounds) }

      bb.center
    end

    # Calculate volume of tetrahedron.
    #
    # @param tetrahedron [<Array<(Geom::Point3d, Geom::Point3d, Geom::Point3d)>]
    #
    # @return [Float] Volume in cubic inches. Volume is negative when
    #   tetrahedron is "inside out" based on winding order.
    def self.tetrahedron_volume(tetrahedron)
      a, b, c, d = tetrahedron

      ((a - d) % ((b - d) * (c - d))) / 6
    end

    # Calculate center of tetrahedron.
    #
    # @param tetrahedron [<Array<(Geom::Point3d, Geom::Point3d, Geom::Point3d)>]
    #
    # @return [Geom::Point3d]
    def self.tetrahedron_center(tetrahedron)
      a, b, c, d = tetrahedron

      Geom::Point3d.new(
        (a.x + b.x + c.x + d.x) / 4,
        (a.y + b.y + c.y + d.y) / 4,
        (a.z + b.z + c.z + d.z) / 4
      )
    end

    # Traverse entities recursively.
    #
    # @param entities [Array<Sketchup::Entity>, Sketchup::Entities]
    # @param transformation [Geom::Transformation]
    #
    # @yieldparam entity [Sketchup::Entity]
    # @yieldparam transformation [Geom::Transformation]
    #   The local transformation. Multiply coordinates from entity with this to
    #   get them all in the same coordinate system.
    #
    # @return [Void]
    def self.traverse_entities(entities, transformation = IDENTITY, &block)
      entities.each do |entity|
        block.call(entity, transformation)
        next unless LEntity.instance?(entity)
        traverse_entities(
          entity.definition.entities,
          transformation * entity.transformation,
          &block
        )
      end
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
  end
end
