module Eneroth
  module CenterOfMass
    Sketchup.require "#{PLUGIN_ROOT}/draw"

    unless @loaded
      @loaded = true
      UI.menu("Plugins").add_item(EXTENSION.name) { Draw.draw_center_of_mass }
    end
  end
end
