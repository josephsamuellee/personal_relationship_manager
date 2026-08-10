class TagParser
  TAG_REGEX = /(?:^|\s)#([A-Za-z][A-Za-z0-9_-]*)/

  def self.parse(text)
    new.parse(text)
  end

  def self.normalize(name)
    name.to_s.strip.delete_prefix("#").downcase
  end

  def parse(text)
    tags = []
    seen = {}

    text.to_s.scan(TAG_REGEX) do |match|
      normalized = self.class.normalize(match.first)
      next if normalized.blank?
      next if seen[normalized]

      seen[normalized] = true
      tags << normalized
    end

    tags
  end
end
