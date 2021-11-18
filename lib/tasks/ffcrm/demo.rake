# frozen_string_literal: true

# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
namespace :ffcrm do
  namespace :demo do
    desc "Load demo data"
    task load: :environment do
      require "active_record/fixtures"
      $stdout.sync = true

      3000.times do |index|
        puts "!>>> Schema ##{index+1}"
        ActiveRecord::Base.connection.schema_search_path = "\"#{"schema-#{index + 1}"}\", \"$user\", public"

        # Load fixtures
        create_demo_records
        # Simulate random user activities.
        # create_demo_activities
      end
    end

    desc "Reset the database and reload demo data along with default application settings"
    task reload: :environment do
      # Rake::Task["db:migrate:reset"].invoke
      Rake::Task["ffcrm:demo:load"].invoke
    end

    def create_demo_records
      ActiveRecord::FixtureSet.reset_cache
      Dir.glob(Rails.root.join("db", "demo", "*.{yml,csv}")).each do |fixture_file|
        ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("db/demo"), File.basename(fixture_file, ".*"))
      end
    end

    def create_demo_activities
      puts "Generating user activities..."
      %w[Account Address Campaign Comment Contact Email Lead Opportunity Task].map do |model|
        model.constantize.all
      end.flatten.each do |item|
        user = if item.respond_to?(:user)
                 item.user
               elsif item.respond_to?(:addressable)
                 item.addressable.try(:user)
        end
        related = if item.respond_to?(:addressable)
                    item.addressable
                  elsif item.respond_to?(:commentable)
                    item.commentable
                  elsif item.respond_to?(:mediator)
                    item.mediator
        end
        # Backdate within the last 30 days
        created_at = item.created_at - rand(1..30).days + rand(12 * 60).minutes
        updated_at = created_at + rand(12 * 60).minutes

        create_version(event: "create", created_at: created_at, user: user, item: item, related: related)
        create_version(event: "update", created_at: updated_at, user: user, item: item, related: related)

        if [Account, Campaign, Contact, Lead, Opportunity].include?(item.class)
          viewed_at = created_at + rand(12 * 60).minutes
          create_version(event: "view", created_at: viewed_at, user: user, item: item)
        end
        print "." if item.id % 10 == 0
      end
      puts
    end

    def create_version(options)
      version = Version.new
      options.each { |k, v| version.send(k.to_s + "=", v) }
      version.save!
    end
  end
end
