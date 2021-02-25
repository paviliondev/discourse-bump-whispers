# name: discourse-bump-whispers
# about: Stops the bump of whispers being suppressed
# version: 0.1
# email contacts: robert@thepavilion.io
# authors: Robert Barrow
# url: https://github.com/paviliondev/discourse-bump-whispers

enabled_site_setting :bump_whispers_enabled

after_initialize do

  module PostRevisorExtensions 
    def bypass_bump?

      if SiteSetting.bump_whispers_enabled && @post.topic.category_id &&
        ([@post.topic.category_id, Category.find_by(id: @post.topic.category_id).parent_category_id] & SiteSetting.bump_whispers_categories.split("|").map(&:to_i)).any?

        !@post_successfully_saved ||
          @topic_changes.errored? ||
          @opts[:bypass_bump] == true ||
          only_hidden_tags_changed?
      else
        super
      end
    end
  end

  class ::PostRevisor
    prepend PostRevisorExtensions
  end

  module PostCreatorExtensions
    private def update_topic_stats

      if SiteSetting.bump_whispers_enabled && @post.topic.category_id &&
        ([@post.topic.category_id, Category.find_by(id: @post.topic.category_id).parent_category_id] & SiteSetting.bump_whispers_categories.split("|").map(&:to_i)).any?

        attrs = { updated_at: Time.now }

        if @post.post_type != Post.types[:whisper]
          attrs[:last_posted_at] = @post.created_at
          attrs[:last_post_user_id] = @post.user_id
          attrs[:word_count] = (@topic.word_count || 0) + @post.word_count
          attrs[:excerpt] = @post.excerpt_for_topic if new_topic?
          attrs[:bumped_at] = @post.created_at unless @post.no_bump
        else
          attrs[:bumped_at] = @post.created_at
        end

        @topic.update_columns(attrs)
      else
        super
      end
    end
  end

  class ::PostCreator
    prepend PostCreatorExtensions
  end
end
