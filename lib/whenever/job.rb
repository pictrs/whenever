require 'shellwords'

module Whenever
  class Job
    attr_reader :at, :roles, :mailto, :options

    def initialize(options = {})
      @options = options
      @at                               = options.delete(:at)
      @template                         = options.delete(:template)
      @mailto                           = options.fetch(:mailto, :default_mailto)
      @job_template                     = options.delete(:job_template) || ":job"
      @roles                            = Array(options.delete(:roles))
      @options[:output]                 = options.has_key?(:output) ? Whenever::Output::Redirection.new(options[:output]).to_s : ''
      @options[:environment_variable] ||= "RAILS_ENV"
      @options[:environment]          ||= :production
      @options[:path]                   = Shellwords.shellescape(@options[:path] || Whenever.path)
    end

    def output
      job = process_template(@template, @options)
      out = process_template(@job_template, @options.merge(:job => job))
      out.gsub(/%/, '\%')
    end

    def has_role?(role)
      roles.empty? || roles.include?(role)
    end

  protected

    def process_template(template, options)
      template.gsub(/:\w+/) do |key|
        before_and_after = [$`[-1..-1], $'[0..0]]
        option = options[key.sub(':', '').to_sym] || key

        if @options[:runner_exception_notification] && options[:job_type_name]==:runner  && key == ':task' 
          option = 'begin; ' + option + '; rescue => e;   ExceptionNotifier.notify_exception(e); raise e; end'
        end

        if before_and_after.all? { |c| c == "'" }
          escape_single_quotes(option)
        elsif before_and_after.all? { |c| c == '"' }
          escape_double_quotes(option)
        else
          option
        end
      end.gsub(/\s+/m, " ").strip
    end

    def escape_single_quotes(str)
      str.gsub(/'/) { "'\\''" }
    end

    def escape_double_quotes(str)
      str.gsub(/"/) { '\"' }
    end
  end
end
