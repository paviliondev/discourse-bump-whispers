# name: discourse-bump-whispers
# about: Stops the bump of whispers being suppressed
# version: 0.1
# authors: Robert Barrow
# url: https://github.com/paviliondev/discourse-bump-whispers

enabled_site_setting :bump_whispers_enabled

after_initialize do

  PostRevisor.class_eval do
    def bypass_bump?
      !@post_successfully_saved ||
        @topic_changes.errored? ||
        @opts[:bypass_bump] == true ||
        # REMOVED @post.whisper? ||
        only_hidden_tags_changed?
    end
  end

  PostCreator.class_eval do
    def update_topic_stats
      attrs = { updated_at: Time.now }

      if @post.post_type != Post.types[:whisper]
        attrs[:last_posted_at] = @post.created_at
        attrs[:last_post_user_id] = @post.user_id
        attrs[:word_count] = (@topic.word_count || 0) + @post.word_count
        attrs[:excerpt] = @post.excerpt_for_topic if new_topic?
        attrs[:bumped_at] = @post.created_at unless @post.no_bump
        @topic.update_columns(attrs)
      else
        attrs[:bumped_at] = @post.created_at
        @topic.update_columns(attrs)
      end

      @topic.update_columns(attrs)
    end
  end
end
