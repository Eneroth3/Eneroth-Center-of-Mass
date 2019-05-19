module Eneroth
  module CenterOfMass
    Sketchup.require "#{PLUGIN_ROOT}/point_math"
    Sketchup.require "#{PLUGIN_ROOT}/vendor/cmty-lib/geom/transformation"
    Sketchup.require "#{PLUGIN_ROOT}/vendor/cmty-lib/entity"
    Sketchup.require "#{PLUGIN_ROOT}/vendor/cmty-lib/face"

    using PointMath

    # Calculate center of mass.
    module Calculate
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
        # Tetrahedrons formed by triangles facing towards the arbitrary tip can
        # be though of as cavities inside the body, and are regarded to have
        # negative volume.

        total_center = Geom::Point3d.new
        total_volume = 0
        # Reduce floating point deviations by locating arbitrary tip within
        # body.
        tip_point = aprox_center(entities)

        traverse_entities(entities) do |local_entities, transformation|
          center, volume = entities_centroid(local_entities, tip_point)

          # When volume is zero there is no defined centroid.
          next if volume.zero?

          center.transform!(transformation)
          # In SketchUp a flipped group/component isn't considered to have a
          # negative volume, hence abs.
          volume *= LGeom::LTransformation.determinant(transformation).abs
          center *= volume

          total_center += center
          total_volume += volume
        end

        total_center / total_volume
      end

      # TODO: Document.
      # OPTIMIZE: Return volume weighted centroid.
      def self.entities_centroid(entities, tip_point)
        center = Geom::Point3d.new
        volume = 0

        entities.grep(Sketchup::Face).each do |face|
          triangles = LFace.triangulate(face)
          tetrahedrons = triangles.map { |t| t.push(tip_point) }
          tetrahedrons.each do |tetrahedron|
            tetra_volume = tetrahedron_volume(tetrahedron)
            volume += tetra_volume
            tetra_center = tetrahedron_center(tetrahedron)
            center += tetra_center * tetra_volume
          end
        end

        # Avoid zero division for zero volume.
        return [nil, 0] if volume.zero?

        [center / volume, volume]
      end

      # Calculate volume of tetrahedron.
      #
      # @param tetrahedron [<Array<(Geom::Point3d, Geom::Point3d, Geom::Point3d,
      #   Geom::Point3d)>]
      #
      # @return [Float] Volume in cubic inches. Volume is negative when
      #   tetrahedron is "inside out" based on winding order of the first 3
      #   points.
      def self.tetrahedron_volume(tetrahedron)
        a, b, c, d = tetrahedron

        ((a - d) % ((b - d) * (c - d))) / 6
      end

      # Calculate center of tetrahedron.
      #
      # @param tetrahedron [<Array<(Geom::Point3d, Geom::Point3d, Geom::Point3d,
      #   Geom::Point3d)>]
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
      # @yieldparam entities [Sketchup::Entities]
      # @yieldparam transformation [Geom::Transformation]
      #   The local transformation. Apply to coordinates to get them all in the
      #   same coordinate system.
      #
      # @return [Void]
      def self.traverse_entities(entities, transformation = IDENTITY, &block)
        block.call(entities, transformation)
        entities.each do |entity|
          next unless LEntity.instance?(entity)
          traverse_entities(
            entity.definition.entities,
            transformation * entity.transformation,
            &block
          )
        end
      end
    end
  end
end
