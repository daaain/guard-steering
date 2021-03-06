# encoding: utf-8
require 'guard'
require 'guard/guard'
require 'guard/watcher'
require 'steering'
require 'fileutils'

module Guard
  class Steering < Guard
    # Initialize a Guard.
    # @param [Array<Guard::Watcher>] watchers the Guard file watchers
    # @param [Hash] options the custom Guard options
    def initialize(watchers = [], options = {})
      super
      @options = {
        :run_at_start => true,
        :output_folder => nil,
        :register_partials => false,
        :quiet => false
      }.update(options)
    end

    # Call once when Guard starts. Please override initialize method to init stuff.
    # @raise [:task_has_failed] when start has failed
    def start
      # create output folder (recursively) if it doesn't exist yet, but only if it's actually defined
      unless @options[:output_folder].nil?
        FileUtils.mkpath(@options[:output_folder]) unless File.directory?(@options[:output_folder])
      end
      
      UI.info("Guard::Steering has started watching your files with output folder set to '#{@output_folder}' (in case of 'nil' templates will be compiled to the folder where they are)") unless @options[:quiet]

      run_all if @options[:run_at_start]
    end

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
    # @raise [:task_has_failed] when stop has failed
    def stop
    end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    # @raise [:task_has_failed] when reload has failed
    def reload
    end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    # @raise [:task_has_failed] when run_all has failed
    def run_all
      targets = Watcher.match_files(self, Dir.glob("**/*.*"))
      run_on_changes targets
    end

    # Called on file(s) changes that the Guard watches.
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_changes has failed
    def run_on_changes(paths)
      paths.each do |path|
          # use output_folder or default back to watched file location
          run_steering(path, @options[:output_folder] || File.dirname(path))
      end
    end

    # Called on file(s) deletions that the Guard watches.
    # @param [Array<String>] paths the deleted files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    def run_on_removals(paths)
      paths.each do |path|
        output_folder = @options[:output_folder] || File.dirname(path)
        fileString = output_folder + "/" + File.basename(path) + ".js"
        File.delete(fileString) if File.exists?(fileString)
        UI.info "Guard::Steering deleted #{File.basename(path)}.js from #{output_folder}" unless @options[:quiet]
      end
    end
    
    def run_steering(path, output_folder)
      begin
        ::Steering.compile_to_file(path, output_folder + "/" + File.basename(path) + ".js", {:extension => '.handlebars', :partial => @options[:register_partials]})
        UI.info "Guard::Steering precompiled #{path} to #{output_folder}" unless @options[:quiet]
      rescue Exception => e
        UI.error "Guard::Steering precompilation failed: #{e}" unless @options[:quiet]
        false
      end
    end
  end
end
