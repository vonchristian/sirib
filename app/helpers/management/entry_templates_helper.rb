module Management
  module EntryTemplatesHelper
    def link_to_add_fields(name, f, association, **args)
      new_object = f.object.public_send(association).klass.new
      id = new_object.object_id
      fields = f.fields_for(association, new_object, child_index: id) do |builder|
        render("management/entry_templates/line_fields", f: builder)
      end
      link_to name, "#", class: args[:class],
        data: { action: "click->nested-form#add", fields: fields.gsub("\n", ""), target_id: id }
    end
  end
end
