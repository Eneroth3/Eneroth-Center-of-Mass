module Eneroth
  module CenterOfMass
    Sketchup.require "#{PLUGIN_ROOT}/density"

    # Interface for controlling density.
    module DensityControl
      # TODO: Implement.
      def self.show
        if @dialog && @dialog.visible?
          @dialog.bring_to_front
        else
          create_dialog unless @dialog
          @dialog.set_file("#{PLUGIN_ROOT}/dialogs/density_control.html")
          attach_callbacks
          @dialog.show
        end
      end

      #-------------------------------------------------------------------------

      def self.attach_callbacks

      end
      private_class_method :attach_callbacks

      def self.create_dialog
        @dialog = UI::HtmlDialog.new(
          dialog_title:    EXTENSION.name,
          preferences_key: name, # Full module name
          resizable:       false,
          style:           UI::HtmlDialog::STYLE_DIALOG,
          width:           400,
          height:          200,
          left:            200,
          top:             100
        )
      end
      private_class_method :create_dialog
    end
  end
end
