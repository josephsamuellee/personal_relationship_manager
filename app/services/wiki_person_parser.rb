class WikiPersonParser
  WIKI_LINK_REGEX = /\[\[([^\]]+)\]\]/

  def self.parse(text)
    new.parse(text)
  end

  def parse(text)
    names = []
    seen = {}

    text.to_s.scan(WIKI_LINK_REGEX) do |match|
      name = match.first.strip
      next if name.blank?

      key = name.downcase
      next if seen[key]

      seen[key] = true
      names << name
    end

    names
  end
end
