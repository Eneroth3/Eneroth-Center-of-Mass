module Eneroth
  module CenterOfMass
    # Triangular pyramid used as basic building block for volume and centroid
    # calculation.
    class Tetrahedron
      # Create tetrahedrons from all triangles in entities.
      #
      # @param entities
      #   [Array<Sketchup::Entity>, Sketchup::Entities, Sketchup::Selection]
      #
      # @param tip_point [Geom::Point3d]
      #
      # @return [Array<Tetrahedron>]
      def self.from_entities(entities, tip_point)
        entities.grep(Sketchup::Face).flat_map { |f| from_face(f, tip_point) }
      end

      # Create tetrahedrons from all triangles in a face.
      #
      # @param face [Sketchup::Face]
      # @param tip_point [Geom::Point3d]
      #
      # @return [Array<Tetrahedron>]
      def self.from_face(face, tip_point)
        LFace.triangulate(face).map { |t| new(t.push(tip_point)) }
      end

      # Create new tetrahedron from 4 points.
      #
      # @param points
      #   [<Array<(Geom::Point3d, Geom::Point3d, Geom::Point3d, Geom::Point3d)>]
      #   The first 3 points are considered the base and the last the tip.
      def initialize(points)
        @points = points
      end

      # Calculate center of tetrahedron.
      #
      # @return [Geom::Point3d]
      def center
        a, b, c, d = @points

        Geom::Point3d.new(
          (a.x + b.x + c.x + d.x) / 4,
          (a.y + b.y + c.y + d.y) / 4,
          (a.z + b.z + c.z + d.z) / 4
        )
      end

      # Calculate volume for tetrahedron.
      #
      # @return [Float] Volume in cubic inches. Volume is negative when
      #   tetrahedron is "inside out" based on winding order of the first 3
      #   points.
      def volume
        a, b, c, d = @points
        ((a - d) % ((b - d) * (c - d))) / 6
      end
    end
  end
end
