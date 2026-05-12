# frozen_string_literal: true

class SpecialActionButtonComponent < ViewComponent::Base
  attr_reader :text, :type, :href, :method, :disable_with, :disabled, :icon, :html_options

  def initialize(
    text: nil,
    type: :submit,
    href: nil,
    method: nil,
    disable_with: nil,
    disabled: false,
    icon: "icons/right-arrow.svg",
    **html_options
  )
    @text = text
    @type = type
    @href = href
    @method = method
    @disable_with = disable_with
    @disabled = disabled
    @icon = icon
    @html_options = html_options
  end

  def root_classes
    class_names(
      "special-action-btn",
      { "special-action-btn--disabled" => disabled },
      html_options[:class]
    )
  end

  def shared_attributes
    attrs = html_options.except(:class).merge(class: root_classes)
    attrs[:disabled] = true if disabled
    attrs
  end

  def button_attributes
    attrs = shared_attributes
    if disable_with.present? && type == :submit
      attrs[:data] ||= {}
      attrs[:data][:turbo_submits_with] = disable_with
    end
    attrs
  end

  def link_attributes
    attrs = shared_attributes
    if method.present? && method.to_sym != :get
      attrs[:data] ||= {}
      attrs[:data][:turbo_method] = method
    end
    attrs
  end

  def link?
    href.present?
  end

  def display_text
    text || ""
  end

  def icon_tag
    return nil if icon.blank?
    return helpers.inline_svg_tag(icon, class: "special-action-btn__icon", aria: { hidden: true }) if icon.end_with?(".svg")
    helpers.image_tag(icon, class: "special-action-btn__icon", "aria-hidden": true)
  end
end
