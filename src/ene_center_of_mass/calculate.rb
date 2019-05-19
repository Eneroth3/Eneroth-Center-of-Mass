module Eneroth
  module CenterOfMass
    Sketchup.require "#{PLUGIN_ROOT}/point_math"
    Sketchup.require "#{PLUGIN_ROOT}/tetrahedron"
    Sketchup.require "#{PLUGIN_ROOT}/solid_check"
    Sketchup.require "#{PLUGIN_ROOT}/density"
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

      # Calculate centroid with recursion for nested containers.
      #
      # Note that no checks are done to see if the entities are solid.
      #
      # @param entities [Array<Sketchup::Entity>, Sketchup::Entities,
      #   Sketchup::Selection]
      # @param exclude_non_solids [Boolean]
      #   Check if each entities collection represents a solid and ignore those
      #   that don't. If it is already known all entities collection represent
      #   solids, this can safely be set to false to skip redundant checks.
      # @param wysiwyg [Boolean]
      #   Only include visible entities with visible layers.
      # @param trail [Array<Sketchup::ComponentInstance, SketchUp::Group>]
      #   Trail from root to where entities are located. Used for density
      #   values cascading from parent containers.
      # @param tip_point [Geom::Point3d]
      #   Point used internally in calculations.
      #   When entities form a closed volume, this value cancels out.
      #   Should be somewhat close to the points in entities to reduce
      #   floating point imprecision.
      #
      # @return [Geom::Point3d, nil]
      #   If volume is zero, centroid is undefined (nil).
      def self.center_of_mass(entities = Sketchup.active_model.selection,
                              exclude_non_solids = false,
                              wysiwyg = true,
                              trail = Sketchup.active_model.active_path || [],
                              tip_point = aprox_center(entities))
        # To find center of mass, iterate over all the triangles in the entities
        # and form tetrahedrons between them and an arbitrary tip point.
        # Weight the tetrahedron centers by the tetrahedron volume and sum them.
        #
        # Tetrahedrons formed by triangles facing towards the arbitrary tip can
        # be though of as cavities inside the body, and are regarded to have
        # negative volume.

        total_center = Geom::Point3d.new
        total_weight = 0

        # Cache result from local_centroid for faster calculations when
        # objects re-occur.
        cache = {}

        traverse_entities(entities, wysiwyg, trail) do |local_entities, transformation, trail|
          next if exclude_non_solids && !SolidCheck.solid?(local_entities, false)

          cache[local_entities] ||= local_centroid(
            local_entities,
            tip_point.transform(transformation.inverse)
          )
          center, volume = cache[local_entities]

          # When volume is zero there is no defined centroid.
          next if volume.zero?

          # Create new object, shadowing old, as we don't want to change the
          # cached Point3d.
          center = center.transform(transformation)
          # In SketchUp a flipped group/component isn't considered to have a
          # negative volume, hence abs.
          volume *= LGeom::LTransformation.determinant(transformation).abs
          weight = volume * Density.from_path(trail)
          center *= weight

          total_center += center
          total_weight += weight
        end

        # Avoid zero division for zero volume.
        return nil if total_weight.zero?

        total_center / total_weight
      end

      # Calculate centroid without recursion for nested containers.
      #
      # Note that no checks are done to see if the entities are solid.
      #
      # @param entities [Array<Sketchup::Entity>, Sketchup::Entities,
      #   Sketchup::Selection]
      # @param tip_point [Geom::Point3d]
      #   Point used internally in calculations.
      #   When entities form a closed volume, this value cancels out.
      #   Should be somewhat close to the points in entities to reduce
      #   floating point imprecision.
      #
      # @return [Array<(Geom::Point3d, Numeric)>, Array<(nil, 0)>]
      #   Centroid, volume. If volume is zero, centroid is undefined (nil).
      def self.local_centroid(entities, tip_point = aprox_center(entities))
        center = Geom::Point3d.new
        volume = 0

        Tetrahedron.from_entities(entities, tip_point).each do |tetrahedron|
          volume += tetrahedron.volume
          center += tetrahedron.center * tetrahedron.volume
        end

        # Avoid zero division for zero volume.
        return [nil, 0] if volume.zero?

        [center / volume, volume]
      end

      # Traverse entities recursively.
      #
      # @param entities [Array<Sketchup::Entity>, Sketchup::Entities]
      # @param wysiwyg [Boolean]
      #   Only include visible entities with visible layers.
      # @param transformation [Geom::Transformation]
      #
      # @yieldparam entities [Sketchup::Entities]
      # @yieldparam transformation [Geom::Transformation]
      #   The local transformation. Apply to coordinates to get them all in the
      #   same coordinate system.
      # @yieldparam trail [Array<Sketchup::ComponentInstance, SketchUp::Group>]
      #
      # @return [Void]
      def self.traverse_entities(entities, wysiwyg, trail = [], transformation = IDENTITY, &block)
        block.call(entities, transformation, trail)
        entities.each do |entity|
          next unless LEntity.instance?(entity)
          next if wysiwyg && (!entity.visible? || !entity.layer.visible?)
          traverse_entities(
            entity.definition.entities,
            wysiwyg,
            trail + [entity],
            transformation * entity.transformation,
            &block
          )
        end
      end
    end
  end
end
