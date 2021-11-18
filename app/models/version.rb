# frozen_string_literal: true

class Version < ApplicationRecord
  belongs_to :related, polymorphic: true, optional: true # TODO: Is this really optional?
  belongs_to :user, foreign_key: :whodunnit, optional: true # TODO: Is this really optional?
  belongs_to :item, polymorphic: true, optional: true
end
