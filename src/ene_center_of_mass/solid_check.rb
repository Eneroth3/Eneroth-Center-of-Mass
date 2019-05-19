module Eneroth
  module CenterOfMass
    Sketchup.require "#{PLUGIN_ROOT}/vendor/cmty-lib/entity"

    # Check if entities represent a solid.
    module SolidCheck
      # Test if entities are solid. Unlike SketchUp's native check, nested
      # instances are allowed here, as long as they are solid too.
      #
      # @param entities [Array<Sketchup::Entity>, Sketchup::Entities,
      #   Sketchup::Selection]
      #
      # @return [Boolean]
      def self.solid?(entities)
        unless entities.grep(Sketchup::Edge).all? { |e| e.faces.size.even? }
          return false
        end

        entities.all? { |e| !LEntity.instance?(e) || solid?(e.definition.entities) }
      end
    end
  end
end
