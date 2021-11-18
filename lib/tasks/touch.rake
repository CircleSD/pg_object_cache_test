# frozen_string_literal: true

#------------------------------------------------------------------------------
# Capture memory usage from Docker container using the following command: -
#
# while true; do docker stats --no-stream --format "table {{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" | tail -n +2 | tee -a tmp/stats.txt; sleep 1; done
#------------------------------------------------------------------------------
namespace :touch do
  desc "Touch each table within each schema"
  task test: :environment do
    3000.times do |index|
      # reset pg connection
      if ENV["RESET_CONNECTION"] && index % 500 == 0
        ActiveRecord::Base.connection.reconnect!
        puts "!>>> Reset connection --------------------------------------------------"
      end

      # select schema and touch each table
      puts "!>>> Schema ##{index + 1}"
      ActiveRecord::Base.connection.schema_search_path = "\"#{"schema-#{index + 1}"}\", \"$user\", public"
      AccountContact.select([:id]).first
      AccountOpportunity.select([:id]).first
      Account.select([:id]).first
      Activity.select([:id]).first
      Address.select([:id]).first
      Avatar.select([:id]).first
      Campaign.select([:id]).first
      ContactOpportunity.select([:id]).first
      Contact.select([:id]).first
      Comment.select([:id]).first
      Email.select([:id]).first
      FieldGroup.select([:id]).first
      Field.select([:id]).first
      Group.select([:id]).first
      GroupsUser.select([:group_id]).first
      Lead.select([:id]).first
      List.select([:id]).first
      Opportunity.select([:id]).first
      Permission.select([:id]).first
      Session.select([:id]).first
      Setting.select([:id]).first
      Tag.select([:id]).first
      Tagging.select([:id]).first
      Task.select([:id]).first
      User.select([:id]).first
      Version.select([:id]).first
    end
  end
end
