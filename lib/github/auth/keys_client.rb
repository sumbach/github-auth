require 'httparty'

module Github::Auth
  # Client for fetching public SSH keys using the Github API
  class KeysClient
    attr_reader :username, :hostname

    UsernameRequiredError = Class.new StandardError
    GithubUnavailableError = Class.new StandardError
    GithubUserDoesNotExistError = Class.new StandardError

    DEFAULT_HOSTNAME = 'https://api.github.com'
    USER_AGENT = "github_auth-#{VERSION}"

    DEFAULT_OPTIONS = {
      username: nil,
      hostname: DEFAULT_HOSTNAME
    }

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge options
      raise UsernameRequiredError unless options.fetch :username

      @username = options.fetch :username
      @hostname = options.fetch :hostname
    end

    def keys
      @keys ||= Array(github_response).map do |entry|
        Github::Auth::Key.new username, entry.fetch('key')
      end
    end

    private

    def github_response
      response = http_client.get(
        "#{hostname}/users/#{username}/keys", headers: headers
      )
      raise GithubUserDoesNotExistError if response.code == 404
      response.parsed_response
    rescue SocketError, Errno::ECONNREFUSED => e
      raise GithubUnavailableError.new e
    end

    def http_client
      HTTParty
    end

    def headers
      { 'User-Agent' => USER_AGENT }
    end
  end
end
