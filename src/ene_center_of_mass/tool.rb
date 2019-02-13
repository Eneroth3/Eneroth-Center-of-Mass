module Eneroth
  module CenterOfMass
    # Test a way to preview the center of gravity with a tool.
    # Load this file to activate tool.
    class HighlightBox
      def activate
        # TODO: Enter selection mode if selection is empty.
        # Or mimic selection tool throughout this tool?
        Sketchup.status_text = "Finding center of mass..."
        entities = Sketchup.active_model.selection
        @center = CenterOfMass.center_of_mass(entities)
        @bounds = Geom::BoundingBox.new
        entities.each { |e| @bounds.add(e.bounds) }

        Sketchup.active_model.active_view.invalidate
      end

      def deactivate(view)
        view.invalidate
      end

      def draw(view)
        bounds = Geom::BoundingBox.new
        bounds.add(@bounds)
        pad_bounds(bounds, 30)

        view.line_width = 2
        3.times do |d|
          point0 = Geom::Point3d.new(
            d == 0 ? bounds.min.x : @center.x,
            d == 1 ? bounds.min.y : @center.y,
            d == 2 ? bounds.min.z : @center.z
          )
          point1 = Geom::Point3d.new(
            d == 0 ? bounds.max.x : @center.x,
            d == 1 ? bounds.max.y : @center.y,
            d == 2 ? bounds.max.z : @center.z
          )
          view.set_color_from_line(point0, point1)
          view.draw(GL_LINES, [point0, point1])
        end

        view.draw_points([@center])
      end

      def resume(view)
        view.invalidate
      end

      # TODO: Draw construction point some way (press enter?)

      private

      # Pad bounding box.
      #
      # @param bounds [Geom::BoundingBox]
      # @param padding [Numeric] Padding in logical pixels.
      #
      # @return [Void]
      def pad_bounds(bounds, padding)
        view = Sketchup.active_model.active_view
        pd = view.pixels_to_model(padding, bounds.center)
        bounds.add(bounds.max.offset(Geom::Vector3d.new(pd, pd, pd)))
        bounds.add(bounds.min.offset(Geom::Vector3d.new(-pd, -pd, -pd)))
      end
    end
    Sketchup.active_model.select_tool(HighlightBox.new)
  end
end
