# https://github.com/chef/chef/blob/master/lib/chef/resource/locale.rb
# https://docs.chef.io/resources/locale/
resource_name :locale

LC_VARIABLES ||= %w{LC_ADDRESS LC_COLLATE LC_CTYPE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME}.freeze
LOCALE_CONF ||= "/etc/locale.conf".freeze
LOCALE_REGEX ||= /\A\S+/.freeze
LOCALE_PLATFORM_FAMILIES ||= %w{debian windows}.freeze

property :lang, String,
  regex: [LOCALE_REGEX],
  validation_message: "The provided lang is not valid. It should be a non-empty string without any leading whitespace."

property :lc_env, Hash,
  default: {},
  coerce: proc { |h|
    if h.respond_to?(:keys)
      invalid_keys = h.keys - LC_VARIABLES
      unless invalid_keys.empty?
        error_msg = "Key of option lc_env must be equal to one of: \"#{LC_VARIABLES.join('", "')}\"!  You passed \"#{invalid_keys.join(", ")}\"."
        raise Chef::Exceptions::ValidationFailed, error_msg
      end
    end
    unless h.values.all? { |x| x =~ LOCALE_REGEX }
      error_msg = "Values of option lc_env should be non-empty string without any leading whitespace."
      raise Chef::Exceptions::ValidationFailed, error_msg
    end
    h
  }

def windows?
  false
end

load_current_value do
  if windows?
    lang get_system_locale_windows
  else
    begin
      old_content = ::File.read(LOCALE_CONF)
      locale_values = Hash[old_content.split("\n").map { |v| v.split("=") }]
      lang locale_values["LANG"]
    rescue Errno::ENOENT => e
      false
    end
  end
end

# Gets the System-locale setting for the current computer.
# @see https://docs.microsoft.com/en-us/powershell/module/international/get-winsystemlocale
# @return [String] the current value of the System-locale setting.
#
def get_system_locale_windows
  powershell_exec("Get-WinSystemLocale").result["Name"]
end

action :update do
  converge_if_changed do
    set_system_locale
  end
end

action_class do
  # Avoid running this resource on platforms that don't use /etc/locale.conf
  #
  def define_resource_requirements
    requirements.assert(:all_actions) do |a|
      a.assertion { LOCALE_PLATFORM_FAMILIES.include?(node[:platform_family]) }
      a.failure_message(Chef::Exceptions::ProviderNotFound, "The locale resource is not supported on platform family: #{node[:platform_family]}")
    end

    requirements.assert(:all_actions) do |a|
      # RHEL/CentOS type platforms don't have locale-gen
      a.assertion { shell_out("locale-gen") }
      a.failure_message(Chef::Exceptions::ProviderNotFound, "The locale resource requires the locale-gen tool")
    end
  end

  # Generates the localization files from templates using locale-gen.
  # @see http://manpages.ubuntu.com/manpages/cosmic/man8/locale-gen.8.html
  # @raise [Mixlib::ShellOut::ShellCommandFailed] not a supported language or locale
  #
  def generate_locales
    shell_out!("locale-gen #{unavailable_locales.join(" ")}", timeout: 1800)
  end

  # Sets the system locale for the current computer.
  #
  def set_system_locale
    if windows?
      # Sets the system locale for the current computer.
      # @see https://docs.microsoft.com/en-us/powershell/module/internationalcmdlets/set-winsystemlocale
      #
      response = powershell_exec("Set-WinSystemLocale -SystemLocale #{new_resource.lang}")
      raise response.errors.join(" ") if response.error?
    else
      generate_locales unless unavailable_locales.empty?
      update_locale
    end
  end

  # Updates system locale by appropriately writing them in /etc/locale.conf
  # @note This locale change won't affect the current run. At this time it is an exercise
  # left to the user to restart or reboot if the locale change is required at
  # later part of the client run.
  # @see https://wiki.archlinux.org/index.php/locale#Setting_the_system_locale
  #
  def update_locale
    file "Updating system locale" do
      path LOCALE_CONF
      content new_content
    end
  end

  # @return [Array<String>] Locales that user wants to set but are not available on
  #   the system. They are required to be generated.
  #
  def unavailable_locales
    @unavailable_locales ||= begin
      available = shell_out!("locale -a").stdout.split("\n")
      required = [new_resource.lang, new_resource.lc_env.values].flatten.compact.uniq
      required - available
    end
  end

  # @return [String] Contents that are required to be
  #   updated in /etc/locale.conf
  #
  def new_content
    @new_content ||= begin
      content = {}
      content = new_resource.lc_env.dup if new_resource.lc_env
      content["LANG"] = new_resource.lang if new_resource.lang
      content.sort.map { |t| t.join("=") }.join("\n") + "\n"
    end
  end
end

