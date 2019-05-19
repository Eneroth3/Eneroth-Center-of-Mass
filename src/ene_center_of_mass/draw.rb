module Eneroth
  module CenterOfMass
    Sketchup.require "#{PLUGIN_ROOT}/solid_check"
    Sketchup.require "#{PLUGIN_ROOT}/calculate"

    SOLID_PROMPT =
      "The selection contains non-solids.\n\n"\
      "Do you want to exclude them from center of mass calculation?".freeze

    EMPTY_SELECTION = "Please select something and try again.".freeze

    STATUS_WORKING = "Calculating center of mass...".freeze

    STATUS_DONE = "Done.".freeze

    # Calculate and draw center of mass.
    module Draw
      # Find center of mass for selection and draw a crosshair over it.
      #
      # @return [Void]
      def self.draw_center_of_mass
        selection = Sketchup.active_model.selection
        selection.empty? && UI.messagebox(EMPTY_SELECTION) && return

        exclude_non_solids =
          !SolidCheck.solid?(selection)\
          && UI.messagebox(SOLID_PROMPT, MB_YESNO) == IDYES

        Sketchup.status_text = STATUS_WORKING
        point = Calculate.center_of_mass(selection, exclude_non_solids)
        draw_cross(point, entities_bounds(selection).diagonal)
        Sketchup.status_text = STATUS_DONE
      end

      # Find bounding box for entities.
      #
      # @param entities [Array<Sketchup::Entity>, Sketchup::Entities,
      #   Sketchup::Selection]
      #
      # @return [Geom::BoundingBox]
      def self.entities_bounds(entities)
        bb = Geom::BoundingBox.new
        entities.each { |e| bb.add(e.bounds) }

        bb
      end

      # Highlight point in space by drawing 3D cross over it.
      #
      # @param position [Geom::Point3d]
      # @param size [Length]
      #
      # @return [Void]
      def self.draw_cross(position, size)
        model = Sketchup.active_model
        model.start_operation("Find Center of Gravity", true)

        group = model.active_entities.add_group
        # Avoid setting uniform scaling due to Sketchup issue.
        # https://rubocop-sketchup.readthedocs.io/en/stable/cops_bugs/#sketchupbugsuniformscaling
        group.transformation =
          Geom::Transformation.new(position) *
          Geom::Transformation.scaling(size, size, size)

        group.entities.add_edges([0.5, 0, 0], [-0.5, 0, 0])
        group.entities.add_edges([0, 0.5, 0], [0, -0.5, 0])
        group.entities.add_edges([0, 0, 0.5], [0, 0, -0.5])

        model.commit_operation
      end
    end
  end
end
