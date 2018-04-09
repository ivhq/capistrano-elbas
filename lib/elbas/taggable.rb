module Elbas
  module Taggable
    def tag(tags_hash = {})
      with_retry do
        tag_array = tags_hash.map { |k,v| { key: k, value: v } }
        aws_counterpart.create_tags(tags: tag_array)
      end
    end
  end
end
