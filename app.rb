require 'sinatra/base'
require 'pathname'
require 'octokit'
require 'travis'

class Builder < Sinatra::Application
  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  configure :production, :development do
    enable :logging
    set :views, 'views'
    set :public_folder, 'public'
  end

  BRANCHES = ['4-2-stable', 'master']
  OCTOKIT_CLIENT = Octokit::Client.new(access_token: ENV['GH_TOKEN'])

  get '/' do
    load_github
    load_awdwr
    erb :index
  end

  # View helpers
  protected
    def pretty_commit(commit)
      text = commit[:commit][:message].split("\n\n")[0]
      link = "https://github.com/rails/rails/commit/#{commit[:sha]}"
      "<a href='#{link}'>#{text}</a>"
    end

    def pretty_status(commit, status)
      if commit[:commit][:message].include?('[ci skip]')
        "<div id='light'>
          <span class='active' id='black'></span>
        </div>"
      elsif status == 'success'
        "<div id='light'>
          <span class='active' id='green'></span>
        </div>"
      else
        "<div id='light'>
          <span class='active' id='red'></span>
        </div>"
      end
    end

    def travis_status(repo, branch)
      @repo = Travis::Repository.find(repo)
      @build = @repo.branch(branch)

      if repo != 'rails/rails'
        @build = @build.jobs.find { |j| j.config['env'] == 'RAILS_MASTER=1' && j.config['rvm'] == '2.3.0' }
      end

      if @build.state == 'passed'
        "<img src='travis-passing.svg'>"
      else
        "<img src='travis-failing.svg'>"
      end
    end

  # Service loaders
  protected

    def load_awdwr
      #
    end

    def load_github
      # LOAD LATEST 5 COMMITS
      @commits_info = {}
      BRANCHES.each { |b| @commits_info[b] = {} }

      BRANCHES.each do |branch|
        # Load commit's general information
        @commits = OCTOKIT_CLIENT.commits('rails/rails', branch).take(5)
        @commits.each { |c| @commits_info[branch][c] = '' }

        # Load commit's status information
        @commits_info[branch].each do |commit, _|
          statuses = OCTOKIT_CLIENT.statuses('rails/rails', commit[:sha])
          if statuses.any?
            @commits_info[branch][commit] = statuses[0][:state]
          else
            @commits_info[branch][commit] = 'failure'
          end
        end
      end
    end
end
