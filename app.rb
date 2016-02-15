require 'sinatra/base'
require 'sinatra/reloader'
require 'octokit'
require 'travis'

class Builder < Sinatra::Application
  configure :development do
    register Sinatra::Reloader
    set :views, 'views'
    set :public_folder, 'public'
  end

  OCTOKIT_CLIENT = Octokit::Client.new(access_token: ENV['GH_TOKEN'])

  get '/' do
    load_github
    load_awdwr
    load_rubybench
    erb :index
  end

  # View helpers
  protected
    def pretty_commit(commit)
      text = commit[:commit][:message].split("\n\n")[0]
      link = "https://github.com/rails/rails/commit/#{commit[:sha]}"
      "<a href='#{link}'>#{text}</a>"
    end

    def pretty_status(status)
      if status == 'success'
        "<div id='light'>
          <span class='active' id='green'></span>
        </div>"
      else
        "<div id='light'>
          <span class='active' id='red'></span>
        </div>"
      end
    end

    def travis_status(repo)
      @repo = Travis::Repository.find(repo)
      @build = @repo.branch('master')

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
      @commits_info = {}

      # Load commit's gengeral information
      @commits = OCTOKIT_CLIENT.commits('rails/rails', branch: 'master').take(5)
      @commits.each { |c| @commits_info[c] = '' }

      # Load commit's status information
      @commits_info.each do |commit, _|
        statuses = OCTOKIT_CLIENT.statuses('rails/rails', commit[:sha])
        if statuses.any?
          @commits_info[commit] = statuses[0][:state]
        else
          @commits_info[commit] = 'failure'
        end
      end
    end

    def load_rubybench
      #
    end
end
