# frozen_string_literal: true

module IconsHelper
  # Wraps rails_icons so every icon carries the sizing class and says which
  # icon it is — the ligature used to do the latter for free, and specs read
  # it. The name also keeps a view local called `icon` from shadowing anything.
  def icon_svg(name, **attrs)
    name = name.to_s
    data = { icon: name }.merge(attrs.delete(:data) || {})

    icon(name, class: [ "icon", attrs.delete(:class) ].compact.join(" "), data: data, **attrs)
  end
end
