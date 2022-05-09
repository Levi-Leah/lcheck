#!/usr/bin/env ruby

require 'optparse'
require 'asciidoctor'
require 'colorize'
require 'find'

require_relative 'lcheck_checks'

# TODO exit codes
# TODO absolute paths so it doesn't loop through symlinks?
# TODO output in relative paths

ARGV << '-h' if ARGV.empty?
msg = "-m option must be used with one of the Standalone options: " + "-s, -a"

 options = {}
# configuring the option parser
opt = OptionParser.new do |opts|
    opts.banner = "\n#{File.basename( ($0), ".*" )}(1)".upcase + "\n\nNAME".bold + "\n\t#{File.basename( ($0), ".*" )} - checks links in AsciiDoc source files." + "\n\nSYNOPSIS".bold + "\n\t#{File.basename( ($0), ".*" )} [OPTION]... FILE..." + "\n\nOPTIONS".bold

    opts.separator ""
    opts.separator "   Standalone options:".bold

    opts.on("-h", "--help", "Prints help message.") do
        puts opts
        exit 0
    end

    options[:l] = false
    opts.on('-l', "Check broken links.") do |l|
        if ARGV.empty?
            puts "#{File.basename( ($0), ".*" )}: No argumets provided."
            puts opts
        end
        options[:l] = true
    end

    options[:a] = false
    opts.on("-a", "Check for unresolved attributes.") do |a|
        if ARGV.empty?
            puts "#{File.basename( ($0), ".*" )}: No argumets provided."
            puts opts
        end
        options[:a] = true
    end

    options[:s] = false
    opts.on("-s", "Check for hyperlinks in literal blocks.") do |s|
        if ARGV.empty?
            puts "#{File.basename( ($0), ".*" )}: No argumets provided."
            puts opts
        end
        options[:s] = true
    end

    opts.separator ""
    opts.separator "   Dependently operating options:".bold

    options[:m] = false
    opts.on("-m", "Forces Standalone options to only check master.adoc files.\n\t\t\t\t     #{msg}") do |m|
        options[:m] = true
    end

end

# handle exceptions
begin
    opt.parse! ARGV
rescue OptionParser::InvalidOption => e
    STDERR.puts "#{File.basename( ($0), ".*" )}: Invalid option: #{e}"
    puts opt.help
    exit 1
end


args = opt.parse!

# exit if no options supplied
if options.values.all?(false)
    puts "#{File.basename( ($0), ".*" )}: No options provided."
    puts opt.help
    exit 1
end


# check if dependent option is used w/o a standalone option
# determine the pattern to search for
if options[:m] == true
    abort "#{msg}" unless options.except(:m).values.any?(true)
    pattern = ".*master\.adoc$"
else
    pattern = ".*\.adoc$"
end


# sort arguments
return_expanded_files(ARGV, pattern)


# check for hyperlinks in literal blocks
# if only master.adocs are checked the output is individual .adoc files containing the match
if options[:s]
    puts "\nChecking #{ARGV} for hyperlinks in literal blocks."
    get_hyperlink_errors()
end

# check for unresolved attributes
if options[:a]
    puts "\nChecking #{ARGV} for unresolved attributes."
    get_attributes_errors()
end

if options[:l]
    puts "\nChecking #{ARGV} for broken links."
    return_broken_links()
end
