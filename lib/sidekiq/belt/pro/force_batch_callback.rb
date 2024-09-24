# frozen_string_literal: true

require "sidekiq/web/helpers"

module Sidekiq
  module Belt
    module Pro
      module ForceBatchCallback
        module SidekiqForceBatchCallback
          def self.action_button(action)
            action_name = "force_#{action}"
            action_chars = action.chars
            action_button = action_chars[0].upcase + action_chars[1..].join
            <<~ERB
              <form action="<%= root_path %>batches/<%= bid %>/force_callback/#{action}" method="post">
                <%= csrf_tag %>
                <input class="btn btn-danger" type="submit" name="#{action_name}" value="<%= t('#{action_button}') %>"
                  data-confirm="Do you want to force the #{action} callback for batch <%= bid %>? <%= t('AreYouSure') %>" />
              </form>
            ERB
          end

          def self.registered(app)
            app.replace_content("/batches") do |content|
              content.gsub!("</th>\n      <%", "</th><th><%= t('Force Callback') %></th>\n      <%")

              content.gsub!(
                "</td>\n        </tr>\n      <% end %>",
                "</td>\n<td>#{action_button('success')}\n#{action_button('complete')}\n#{action_button('death')}</td>\n      </tr>\n    <% end %>"
              )
            end

            app.post("/batches/:bid/force_callback/:action") do
              Sidekiq::Batch::Callback.perform_inline(params[:action], params[:bid])

              return redirect "#{root_path}batches"
            end
          end
        end

        def self.use!
          require("sidekiq/web")

          Sidekiq::Web.register(Sidekiq::Belt::Pro::ForceBatchCallback::SidekiqForceBatchCallback)
        end
      end
    end
  end
end
