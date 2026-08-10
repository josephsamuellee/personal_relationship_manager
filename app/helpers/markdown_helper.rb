module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?

    html = markdown_renderer.render(preprocess_markdown(text))
    sanitize(html, tags: %w[p br strong em ul ol li a span h1 h2 h3 h4 blockquote code pre], attributes: %w[href class])
  end

  private

  def preprocess_markdown(text)
    processed = text.dup
    processed.gsub!(/\[\[([^\]]+)\]\]/) do
      name = Regexp.last_match(1).strip
      person = Person.find_by_name_or_slug(name)
      if person
        "[#{name}](/people/#{person.id})"
      else
        name
      end
    end

    processed.gsub!(/(?:^|\s)(#[A-Za-z][A-Za-z0-9_-]*)/) do
      tag = Regexp.last_match(1)
      " <span class=\"tag\">#{tag.delete_prefix('#')}</span>"
    end

    processed
  end

  def markdown_renderer
    @markdown_renderer ||= Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true, link_attributes: { rel: "nofollow" }),
      autolink: true,
      fenced_code_blocks: true
    )
  end
end
