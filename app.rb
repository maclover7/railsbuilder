require 'sinatra/base'
require 'octokit'
require 'travis'
require 'net/http'
require 'uri'
require 'oga'

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
    def awdwr_status(branch)
      if branch == '4-2-stable'
        document = @awdwr_status[2]
      elsif branch == 'master'
        document = @awdwr_status[1]
      end

      status = document.children.text.split("\n          ")[5]
      link = document.children[7].children[1].attributes[0].value

      if status.include?('0 errors') && status.include?('0 failures')
        "<a href='http://intertwingly.net/projects/#{link}#todos'>
          <img src='travis-passing.svg'>
        </a>"
      else
        "<a href='http://intertwingly.net/projects/#{link}#todos'>
          <img src='travis-failing.svg'>
        </a>"
      end
    end

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
      @original_build = @repo.branch(branch)

      # If we're not checking rails/rails, it's a little
      # tricky to figure out which job from the build we
      # actually want to check the state of.
      if repo == 'rails/rails'
        @build = @original_build
      else
        @build = @original_build.jobs.find { |j| j.config['env'] == 'RAILS_MASTER=1' && j.config['rvm'] == '2.3.0' }
      end

      if @build.state == 'passed'
        "<a href='https://travis-ci.org/#{repo}/builds/#{@original_build.id}'>
          <img src='travis-passing.svg'>
        </a>"
      else
        "<a href='https://travis-ci.org/#{repo}/builds/#{@original_build.id}'>
          <img src='travis-failing.svg'>
        </a>"
      end
    end

  # Service loaders
  protected
    def load_awdwr
      uri = URI.parse('http://intertwingly.net/projects/dashboard.html')
      response = Net::HTTP.get_response(uri)
      @awdwr_status = Oga.parse_html(response.body).xpath('//tr')
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
