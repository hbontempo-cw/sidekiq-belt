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
            app.replace_content("/batches/:bid") do |content|
              intermediary_position = content.index("<th>Complete</th>")
              intermediary_position_2 = content[intermediary_position..].index("</tr>")
              success_position = intermediary_position_2 + 5
              content.insert(success_position, "<td>#{action_button('success')}</td>")
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
