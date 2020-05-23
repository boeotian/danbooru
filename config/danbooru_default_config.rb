module Danbooru
  module_function

  class Configuration
    # A secret key used to encrypt session cookies, among other things. If this
    # token is changed, existing login sessions will become invalid. If this
    # token is stolen, attackers will be able to forge session cookies and
    # login as any user.
    #
    # Must be specified. Use `rake secret` to generate a random secret token.
    def secret_key_base
      ENV["SECRET_TOKEN"].presence || File.read(File.expand_path("~/.danbooru/secret_token"))
    end

    # The name of this Danbooru.
    def app_name
      if CurrentUser.safe_mode?
        "Safebooru"
      else
        "Danbooru"
      end
    end

    def canonical_app_name
      "Danbooru"
    end

    # The canonical hostname of the site.
    def hostname
      Socket.gethostname
    end

    # Contact email address of the admin.
    def contact_email
      "webmaster@#{hostname}"
    end

    # System actions, such as sending automated dmails, will be performed with
    # this account. This account must have Moderator privileges.
    #
    # Run `rake db:seed` to create this account if it doesn't already exist in your install.
    def system_user
      "DanbooruBot"
    end

    def source_code_url
      "https://github.com/danbooru/danbooru"
    end

    def commit_url(hash)
      "#{source_code_url}/commit/#{hash}"
    end

    def issues_url
      "#{source_code_url}/issues"
    end

    # Set the default level, permissions, and other settings for new users here.
    def customize_new_user(user)
      # user.level = User::Levels::MEMBER
      # user.can_approve_posts = false
      # user.can_upload_free = false
      #
      # user.comment_threshold = -1
      # user.blacklisted_tags = ["spoilers", "guro", "scat", "furry -rating:s"].join("\n")
      # user.default_image_size = "large"
      # user.per_page = 20
      # user.disable_tagged_filenames = false
      true
    end

    # An array of regexes containing disallowed usernames.
    def user_name_blacklist
      []
    end

    # Thumbnail size
    def small_image_width
      150
    end

    # Large resize image width. Set to nil to disable.
    def large_image_width
      850
    end

    # After a post receives this many comments, new comments will no longer bump the post in comment/index.
    def comment_threshold
      40
    end

    # Members cannot post more than X comments in an hour.
    def member_comment_limit
      2
    end

    # Users cannot search for more than X regular tags at a time.
    def base_tag_query_limit
      6
    end

    def tag_query_limit
      if CurrentUser.user.present?
        CurrentUser.user.tag_query_limit
      else
        base_tag_query_limit * 2
      end
    end

    # Return true if the given tag shouldn't count against the user's tag search limit.
    def is_unlimited_tag?(term)
      term.type == :metatag && term.name.in?(%w[status rating limit])
    end

    # After this many pages, the paginator will switch to sequential mode.
    def max_numbered_pages
      1_000
    end

    # Maximum size of an upload. If you change this, you must also change
    # `client_max_body_size` in your nginx.conf.
    def max_file_size
      35.megabytes
    end

    # Maximum resolution (width * height) of an upload. Default: 441 megapixels (21000x21000 pixels).
    def max_image_resolution
      21000 * 21000
    end

    # Maximum width of an upload.
    def max_image_width
      40000
    end

    # Maximum height of an upload.
    def max_image_height
      40000
    end

    # https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration
    # https://guides.rubyonrails.org/configuring.html#configuring-action-mailer
    def mail_delivery_method
      # :smtp
      :sendmail
    end

    def mail_settings
      {
        # address: "example.com",
        # user_name: "user",
        # password: "pass",
        # authentication: :login
      }
    end

    # The method to use for storing image files.
    def storage_manager
      # Store files on the local filesystem.
      # base_dir - where to store files (default: under public/data)
      # base_url - where to serve files from (default: http://#{hostname}/data)
      # hierarchical: false - store files in a single directory
      # hierarchical: true - store files in a hierarchical directory structure, based on the MD5 hash
      StorageManager::Local.new(base_url: "#{CurrentUser.root_url}/data", base_dir: Rails.root.join("public/data"), hierarchical: false)

      # Store files on one or more remote host(s). Configure SSH settings in
      # ~/.ssh_config or in the ssh_options param (ref: http://net-ssh.github.io/net-ssh/Net/SSH.html#method-c-start)
      # StorageManager::SFTP.new("i1.example.com", "i2.example.com", base_dir: "/mnt/backup", hierarchical: false, ssh_options: {})

      # Select the storage method based on the post's id and type (preview, large, or original).
      # StorageManager::Hybrid.new do |id, md5, file_ext, type|
      #   ssh_options = { user: "danbooru" }
      #
      #   if type.in?([:large, :original]) && id.in?(0..850_000)
      #     StorageManager::SFTP.new("raikou1.donmai.us", base_url: "https://raikou1.donmai.us", base_dir: "/path/to/files", hierarchical: true, ssh_options: ssh_options)
      #   elsif type.in?([:large, :original]) && id.in?(850_001..2_000_000)
      #     StorageManager::SFTP.new("raikou2.donmai.us", base_url: "https://raikou2.donmai.us", base_dir: "/path/to/files", hierarchical: true, ssh_options: ssh_options)
      #   elsif type.in?([:large, :original]) && id.in?(2_000_001..3_000_000)
      #     StorageManager::SFTP.new(*all_server_hosts, base_url: "https://hijiribe.donmai.us/data", ssh_options: ssh_options)
      #   else
      #     StorageManager::SFTP.new(*all_server_hosts, ssh_options: ssh_options)
      #   end
      # end
    end

    # The method to use for backing up image files.
    def backup_storage_manager
      # Don't perform any backups.
      StorageManager::Null.new

      # Backup files to /mnt/backup on the local filesystem.
      # StorageManager::Local.new(base_dir: "/mnt/backup", hierarchical: false)

      # Backup files to /mnt/backup on a remote system. Configure SSH settings
      # in ~/.ssh_config or in the ssh_options param (ref: http://net-ssh.github.io/net-ssh/Net/SSH.html#method-c-start)
      # StorageManager::SFTP.new("www.example.com", base_dir: "/mnt/backup", ssh_options: {})
    end

    # TAG CONFIGURATION

    # Full tag configuration info for all tags
    def full_tag_config_info
      @full_tag_category_mapping ||= {
        "general" => {
          "category" => 0,
          "short" => "gen",
          "extra" => [],
          "header" => %{<h1 class="general-tag-list">Tags</h1>},
          "relatedbutton" => "General",
          "css" => {
            "color" => "var(--general-tag-color)",
            "hover" => "var(--general-tag-hover-color)"
          }
        },
        "character" => {
          "category" => 4,
          "short" => "char",
          "extra" => ["ch"],
          "header" => %{<h2 class="character-tag-list">Characters</h2>},
          "relatedbutton" => "Characters",
          "css" => {
            "color" => "var(--character-tag-color)",
            "hover" => "var(--character-tag-hover-color)"
          }
        },
        "copyright" => {
          "category" => 3,
          "short" => "copy",
          "extra" => ["co"],
          "header" => %{<h2 class="copyright-tag-list">Copyrights</h2>},
          "relatedbutton" => "Copyrights",
          "css" => {
            "color" => "var(--copyright-tag-color)",
            "hover" => "var(--copyright-tag-hover-color)"
          }
        },
        "artist" => {
          "category" => 1,
          "short" => "art",
          "extra" => [],
          "header" => %{<h2 class="artist-tag-list">Artists</h2>},
          "relatedbutton" => "Artists",
          "css" => {
            "color" => "var(--artist-tag-color)",
            "hover" => "var(--artist-tag-hover-color)"
          }
        },
        "meta" => {
          "category" => 5,
          "short" => "meta",
          "extra" => [],
          "header" => %{<h2 class="meta-tag-list">Meta</h2>},
          "relatedbutton" => nil,
          "css" => {
            "color" => "var(--meta-tag-color)",
            "hover" => "var(--meta-tag-hover-color)"
          }
        }
      }
    end

    # TAG ORDERS

    # Sets the order of the split tag header list (presenters/tag_set_presenter.rb)
    def split_tag_header_list
      @split_tag_header_list ||= ["copyright", "character", "artist", "general", "meta"]
    end

    # Sets the order of the categorized tag string (presenters/post_presenter.rb)
    def categorized_tag_list
      @categorized_tag_list ||= ["copyright", "character", "artist", "meta", "general"]
    end

    # Sets the order of the related tag buttons (javascripts/related_tag.js)
    def related_tag_button_list
      @related_tag_button_list ||= ["general", "artist", "character", "copyright"]
    end

    # END TAG

    # Any custom code you want to insert into the default layout without
    # having to modify the templates.
    def custom_html_header_content
      nil
    end

    # The number of posts displayed per page.
    def posts_per_page
      20
    end

    # Tags that are not visible in safe mode.
    def safe_mode_restricted_tags
      restricted_tags + %w[censored condom nipples nude penis pussy sexually_suggestive]
    end

    # Tags that are only visible to Gold+ users.
    def restricted_tags
      []
    end

    # DeviantArt login cookies. Login to DeviantArt and extract these from the browser.
    # https://github.com/danbooru/danbooru/issues/4219
    def deviantart_cookies
      {
        userinfo: "XXX",
        auth_secure: "XXX",
        auth: "XXX"
      }.to_json
    end

    def pixiv_login
      nil
    end

    def pixiv_password
      nil
    end

    def nico_seiga_login
      nil
    end

    def nico_seiga_password
      nil
    end

    def nijie_login
      nil
    end

    def nijie_password
      nil
    end

    # Register at https://www.deviantart.com/developers/
    def deviantart_client_id
      nil
    end
    
    def deviantart_client_secret
      nil
    end    

    # http://tinysubversions.com/notes/mastodon-bot/
    def pawoo_client_id
      nil
    end

    def pawoo_client_secret
      nil
    end

    # 1. Register app at https://www.tumblr.com/oauth/register.
    # 2. Copy "OAuth Consumer Key" from https://www.tumblr.com/oauth/apps.
    def tumblr_consumer_key
      nil
    end

    # Should return true if the given tag should be suggested for removal in the post replacement dialog box.
    def remove_tag_after_replacement?(tag)
      tag =~ /\A(?:replaceme|.*_sample|resized|upscaled|downscaled|md5_mismatch|jpeg_artifacts|corrupted_image|source_request|non-web_source)\z/i
    end

    # Posts with these tags will be highlighted in the modqueue.
    def modqueue_warning_tags
      %w[hard_translated self_upload nude_filter third-party_edit screencap
      duplicate image_sample md5_mismatch resized upscaled downscaled]
    end

    def stripe_secret_key
    end

    def stripe_publishable_key
    end

    def twitter_api_key
    end

    def twitter_api_secret
    end

    # The default headers to be sent with outgoing http requests. Some external
    # services will fail if you don't set a valid User-Agent.
    def http_headers
      {
        "User-Agent" => "#{Danbooru.config.canonical_app_name}/#{Rails.application.config.x.git_hash}"
      }
    end

    def httparty_options
      # proxy example:
      # {http_proxyaddr: "", http_proxyport: "", http_proxyuser: nil, http_proxypass: nil}
      {
        headers: Danbooru.config.http_headers
      }
    end

    # you should override this
    def email_key
      "zDMSATq0W3hmA5p3rKTgD"
    end

    # For downloads, if the host matches any of these IPs, block it
    def banned_ip_for_download?(ip_addr)
      raise ArgumentError unless ip_addr.is_a?(IPAddr)

      if ip_addr.ipv4?
        if IPAddr.new("127.0.0.1") == ip_addr
          true
        elsif IPAddr.new("169.254.0.0/16").include?(ip_addr)
          true
        elsif IPAddr.new("10.0.0.0/8").include?(ip_addr)
          true
        elsif IPAddr.new("172.16.0.0/12").include?(ip_addr)
          true
        elsif IPAddr.new("192.168.0.0/16").include?(ip_addr)
          true
        else
          false
        end
      elsif ip_addr.ipv6?
        if IPAddr.new("::1") == ip_addr
          true
        elsif IPAddr.new("fe80::/10").include?(ip_addr)
          true
        elsif IPAddr.new("fd00::/8").include?(ip_addr)
          true
        else
          false
        end
      else
        false
      end
    end

    # The url of the Discord server associated with this site.
    def discord_server_url
      nil
    end

    # * Create a new application at https://discord.com/developers/applications
    # * Add your application's client ID below
    # * Go to your application's OAuth2 page on Discord and add the redirect
    #   URL `http://<domain>/oauth/callback`, where <domain> is your website's domain.
    def discord_client_id
      nil
    end

    def discord_client_secret
      nil
    end

    # The twitter username associated with this site (username only, don't include the @-sign).
    def twitter_username
      nil
    end

    # include essential tags in image urls (requires nginx/apache rewrites)
    def enable_seo_post_urls
      false
    end

    # Enables recording of popular searches, missed searches, and post view
    # counts. Requires Reportbooru to be configured and running - see below.
    def enable_post_search_counts
      false
    end

    # reportbooru options - see https://github.com/r888888888/reportbooru
    def reportbooru_server
    end

    def reportbooru_key
    end

    # iqdbs options - see https://github.com/r888888888/iqdbs
    def iqdbs_server
    end

    # AWS config options
    def aws_region
      "us-east-1"
    end

    def aws_credentials
      Aws::Credentials.new(Danbooru.config.aws_access_key_id, Danbooru.config.aws_secret_access_key)
    end

    def aws_access_key_id
    end

    def aws_secret_access_key
    end

    def aws_sqs_region
    end

    def aws_sqs_iqdb_url
    end

    def aws_sqs_archives_url
    end

    # Use a recaptcha on the signup page to protect against spambots creating new accounts.
    # https://developers.google.com/recaptcha/intro
    def enable_recaptcha?
      Rails.env.production? && Danbooru.config.recaptcha_site_key.present? && Danbooru.config.recaptcha_secret_key.present?
    end

    def recaptcha_site_key
    end

    def recaptcha_secret_key
    end

    # Akismet API key. Used for Dmail spam detection. http://akismet.com/signup/
    def rakismet_key
    end

    def rakismet_url
      "https://#{hostname}"
    end

    # API key for https://ipregistry.co. Used for looking up IP address
    # information and for detecting proxies during signup.
    def ip_registry_api_key
      nil
    end

    # The whitelist of email domains allowed for account verification purposes.
    # If a user signs up from a proxy, they must verify their account using an
    # email address from one of the domains on this list before they can do
    # anything on the site. This is meant to prevent users from using
    # disposable emails to create sockpuppet accounts.
    #
    # If this list is empty or nil, then there are no restrictions on which
    # email domains can be used to verify accounts.
    def email_domain_verification_list
      # ["gmail.com", "outlook.com", "yahoo.com"]
      []
    end

    # API key for Google Maps. Used for embedding maps on IP address lookup pages.
    # Generate at https://console.developers.google.com/apis/credentials
    def google_maps_api_key
      nil
    end

    # Cloudflare API token. Used to purge URLs from Cloudflare's cache when a
    # post is replaced. The token must have 'zone.cache_purge' permissions.
    # https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys
    def cloudflare_api_token
    end

    # The Cloudflare zone ID. This is the domain that cached URLs will be purged from.
    def cloudflare_zone
    end

    def recommender_server
    end

    def redis_url
      "redis://localhost:6379"
    end
  end

  class EnvironmentConfiguration
    def custom_configuration
      @custom_configuration ||= CustomConfiguration.new
    end

    def method_missing(method, *args)
      var = ENV["DANBOORU_#{method.to_s.upcase.chomp("?")}"]

      var.presence || custom_configuration.send(method, *args)
    end
  end

  def config
    @config ||= EnvironmentConfiguration.new
  end
end
