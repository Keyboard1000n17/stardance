module MarkdownHelper
  def md(text, allow_images: true)
    MarkdownRenderer.render(text, allow_images: allow_images).html_safe
  end
end
