require 'elasticsearch/model'

require 'auth'
require 'steam_id'

class User < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  include Auth::Model

  has_many :team_invites
  has_many :transfers

  devise :rememberable, :trackable, :omniauthable, omniauth_providers: [:steam]

  validates :name, presence: true, uniqueness: true, length: { in: 1..64 }
  validates :steam_id, presence: true, uniqueness: true,
                       numericality: { greater_than: 0 }
  validates :description, presence: true, allow_blank: true

  validates_permission_to :edit, :team
  validates_permission_to :edit, :teams

  validates_permission_to :edit, :games

  validates_permission_to :edit, :competition
  validates_permission_to :edit, :competitions

  validates_permission_to :manage_rosters, :competition
  validates_permission_to :manage_rosters, :competitions

  after_initialize :set_defaults

  mount_uploader :avatar, AvatarUploader

  def steam_profile_url
    "http://steamcommunity.com/profiles/#{steam_id}"
  end

  def teams
    # TODO: Maybe turn this into a big query?
    teams = Set.new
    transfers.each do |transfer|
      if transfer.is_joining?
        teams << transfer.team
      else
        teams.delete(transfer.team)
      end
    end

    teams.to_a.sort! { |a, b| a.name.downcase <=> b.name.downcase }
  end

  def entered?(comp)
    comp.roster_transfer(self).exists?
  end

  alias_attribute :to_s, :name

  def steam_id_nice
    SteamId.to_str(steam_id)
  end

  def admin?
    can?(:edit, :teams) ||
      can?(:edit, :competitions) ||
      can?(:edit, :games) ||
      can?(:manage_rosters, :competitions)
  end

  def as_indexed_json(_ = {})
    as_json(only: [:name, :steam_id],
            methods: [:steam_id_nice])
  end

  def self.simple_search(q)
    search(query: { simple_query_string: { query: q } })
  end

  private

  def set_defaults
    self.remember_me = true if remember_me.nil?
  end
end
