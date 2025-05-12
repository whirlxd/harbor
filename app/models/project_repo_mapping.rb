class ProjectRepoMapping < ApplicationRecord
  belongs_to :user

  has_paper_trail

  validates :project_name, presence: true
  validates :repo_url, presence: true
  validates :project_name, uniqueness: { scope: :user_id }

  validates :repo_url, format: {
    with: %r{\A(https?://[^/]+/[^/]+/[^/]+)\z},
    message: "must be a valid repository URL"
  }

  validate :repo_url_exists

  IGNORED_PROJECTS = [
    nil,
    "",
    "<<LAST PROJECT>>"
  ]

  private

  def repo_url_exists
    unless GitRemote.check_remote_exists(repo_url)
      errors.add(:repo_url, "is not cloneable")
    end
  end
end
