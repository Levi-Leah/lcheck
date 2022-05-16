#!/usr/bin/env ruby

require 'optparse'
require 'asciidoctor'
require 'colorize'
require 'find'

require_relative 'lcheck_checks'

script_name = File.basename( ($0), ".*" )

# TODO exit codes
# TODO absolute paths so it doesn't loop through symlinks?
# TODO output in relative paths

ARGV << '-h' if ARGV.empty?
master_index_msg = "--master and --index options must be used with one of the Standalone options: --hyperlinks, --attributes\n\n"
versus_msg = "--number and --pattern options must be used with the Standalone options: --versus\n\n"

 options = {}
# configuring the option parser
opt = OptionParser.new do |opts|
    opts.banner = "\n#{script_name}(1)".upcase + "\n\nNAME".bold + "\n\t#{script_name} - checks links in AsciiDoc source files." + "\n\nSYNOPSIS".bold + "\n\t#{script_name} [OPTION]... FILE-PATH..." + "\n\nDESCRIPTION".bold + "\n\tThe #{script_name}(1) command checks if asciidoctor files(s) contain broken links, unresolved attributes, hyperlinks in literal blocks, or if the links do not match the provided link pattern.\n\tFILE-PATH can be any file with .adoc extension or a directory containing file(s) with .adoc extension." + "\n\nOPTIONS".bold

    opts.separator ""
    opts.separator "   Standalone options:".bold

    opts.on("-h", "--help", "Prints help message.") do
        puts opts
        exit 0
    end

    options[:l] = false
    opts.on('-l', "--links", "Check for broken links.") do |l|
        if ARGV.empty?
            puts "#{script_name}: No argumets provided."
            puts opts
            exit 0
        end
        options[:l] = true
    end

    options[:a] = false
    opts.on("-a", "--attributes" ,"Check for unresolved attributes.") do |a|
        if ARGV.empty?
            puts "#{script_name}: No argumets provided."
            puts opts
            exit 0
        end
        options[:a] = true
    end

    options[:s] = false
    opts.on("-s", "--hyperlinks", "Check for hyperlinks in literal blocks.") do |s|
        if ARGV.empty?
            puts "#{script_name}: No argumets provided."
            puts opts
            exit 0
        end
        options[:s] = true
    end

    options[:vs] = false
    opts.on("-vs", "--versus", "Check for hyperlinks in literal blocks. --versus option must be used together with Dependently operating options: --pattern") do |vs|
        if ARGV.empty?
            puts "#{script_name}: No argumets provided."
            puts opts
            exit 0
        end
        options[:vs] = true
    end

    opts.separator ""
    opts.separator "   Dependently operating options:".bold

    options[:m] = false
    opts.on("-m", "--master", "Forces Standalone options to only check master.adoc files.\n\t\t\t\t     #{master_index_msg}") do |m|
        options[:m] = true
    end

    options[:i] = false
    opts.on("-i", "--index", "Forces Standalone options to only check index.adoc files.\n\t\t\t\t     #{master_index_msg}") do |i|
        options[:i] = true
    end

    options[:p] = []
    opts.on("-p", "--pattern PATTERN", "Sets product URL pattern to check links against.\n\t\t\t\t     #{versus_msg}\t\t\t\t     Example: Product URL pattern for link " + "https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8".underline + " is " + "red_hat_enterprise_linux/8".bold, String) do |p|
        options[:p] = p
    end

end

# handle exceptions
begin
    opt.parse! ARGV
rescue OptionParser::InvalidOption => e
    STDERR.puts "#{script_name}: Invalid option: #{e}"
    puts opt.help
    exit 1
rescue OptionParser::InvalidArgument => e
    STDERR.puts "#{script_name}: Invalid argument: #{e}"
    puts opt.help
    exit 1
rescue OptionParser::MissingArgument => e
    STDERR.puts "#{script_name}: Invalid argument: #{e}"
    puts opt.help
    exit 1
end


args = opt.parse!

# exit if no options supplied
if options.values.all?(false)
    puts "#{script_name}: No options provided."
    puts opt.help
    exit 1
end


# check if dependent option is used w/o a standalone option
# determine the pattern to search for
if options[:vs] == true
    unless not options[:p].empty?
        puts "#{script_name}: #{versus_msg}"
        puts opt.help
        exit 1
    end
end

if options[:m] == true
    unless options.except(:m, :i).values.any?(true)
        puts "#{script_name}: #{master_index_msg}"
        puts opt.help
        exit 1
    end
    pattern = "master\.adoc$"
elsif options[:i] == true
    unless options.except(:m, :i).values.any?(true)
        puts "#{script_name}: #{master_index_msg}"
        puts opt.help
        exit 1
    end
    pattern = "index\.adoc$"
else
    pattern = ".*\.adoc$"
end


# sort arguments
sorted_arguments = return_expanded_files(ARGV, pattern)

abort "#{script_name}: #{ARGV} can not be expanded based on specifiyed options." if sorted_arguments.size == 0


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


if options[:vs]
    link_pattern = options[:p]

    puts "\nChecking if URLs in #{ARGV} all contain `#{link_pattern}` pattern."
    check_link_pattern(link_pattern)
end
