require 'net/http'
require 'json'
require 'erb'

module Jekyll
  class DevRantTag < Liquid::Tag

    def initialize(tag_name, rant_id, tokens)
      super
      @rant_id = rant_id.strip
      @cache_folder = File.expand_path "../_dev_rant_cache", File.dirname(__FILE__)
      FileUtils.mkdir_p @cache_folder
    end

    def render(context)
      rant = get_cached_rant || get_rant
      draw_rant rant
    end

    def get_cached_rant()
      cache_file = get_cache_file_for @rant_id
      JSON.parse(File.read cache_file) if File.exist?(cache_file)
    end

    def get_rant()
      uri = URI("https://www.devrant.io/api/devrant/rants/#{@rant_id}?app=3")
      res = Net::HTTP.get(uri)
      cache @rant_id, res
      JSON.parse(res)
    end

    def cache(rant, data)
      cache_file = get_cache_file_for rant
      File.open(cache_file, "w") do |io|
        io.write data
      end
    end

    def get_cache_file_for(rant)
      File.join @cache_folder, "#{rant}.cache"
    end

    def draw_rant(rant)
      rant_text = rant['rant']['text']
      rant_image = rant['rant']['attached_image']
      rant_comments = rant['comments']
      avatar = rant['rant']['user_avatar']

      template = %q{<div class="rant-content">
          <div class="username-row" style="overflow: hidden;">
            <a href="#" class="profile-avatar-circle" style="background-color: #<%= avatar['b'] %>;">
              <img src="https://avatars.devrant.io/<%= avatar['i'] %>" />
            </a>
            <div class="username-details">
            <div class="rant-username"><%= rant['rant']['user_username'] %></div>
            </div>
          </div>
          <p><%= rant_text %></p>
          <% if rant_image %>
          <img src="<%= rant_image['url'] %>" />
          <% end %>
          <% if rant['rant']['tags'] %>
          <div class="rantlist-tags">
          <% rant['rant']['tags'].each() do |t| %>
          <a href="#"><%= t %></a>
          <% end %>
          </div>
          <% end %>
        </div>
      }

      template = ERB.new(template, nil, '<>')
      template.result(binding)
    end
  end
end

Liquid::Template.register_tag('dev_rant', Jekyll::DevRantTag)
