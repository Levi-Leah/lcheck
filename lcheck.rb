#!/usr/bin/env ruby

require 'optparse'
require 'asciidoctor'
require 'colorize'
require 'find'

ARGV << '-h' if ARGV.empty?
msg = "-m option must be used with one of the Standalone options: " + "-s".underline

 options = {}
# configuring the option parser
opt = OptionParser.new do |opts|
    opts.banner = "\n#{File.basename( ($0), ".*" )}(1)".upcase + "\n\nNAME".bold + "\n\t#{File.basename( ($0), ".*" )} - checks links in AsciiDoc source files." + "\n\nSYNOPSIS".bold + "\n\t#{File.basename( ($0), ".*" )} [OPTION]... FILE..." + "\n\nOPTIONS".bold

    opts.separator ""
    opts.separator "   Standalone options:".bold

    opts.on("-h", "--help", "Show this message") do
        puts opts
        exit 0
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
    opts.on("-m", "Check only master.adoc files.\n\t\t\t\t     #{msg}") do |m|
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


# check if dependent option is used w/o a standalone option
abort "#{msg}" if options[:m] && !options[:s]


# suppress AsiiDoctor output
# from https://gist.github.com/moertel/11091573
def suppress_output
  original_stderr = $stderr.clone
  original_stdout = $stdout.clone
  $stderr.reopen(File.new('/dev/null', 'w'))
  $stdout.reopen(File.new('/dev/null', 'w'))
  yield
ensure
  $stdout.reopen(original_stdout)
  $stderr.reopen(original_stderr)
end


accepted_extension = [".adoc"]
input_files = []

# TODO absolute paths so it doesn't loop through symlinks


# determine the pattern to search for
if options[:m]
    pattern = ".*master\.adoc$"
else
    pattern = ".*\.adoc$"
end


ARGV.each do |arg|
    abort "#{File.basename( ($0), ".*" )}: Provided path does not exist: '#{arg}'" if not File.exist?(arg)
    if File.directory?(arg)
        Find.find(arg) do |path|
            unless input_files.include?(path)
                input_files << path if path =~ /#{pattern}/
            end
        end

    elsif File.file?(arg)
        if not accepted_extension.include? File.extname(arg)
            puts "#{File.basename( ($0), ".*" )}: invalid file extension: #{arg}"
            puts "Accepted file extensions: #{accepted_extension}"
            exit 1
        end
        unless input_files.include?(arg)
            input_files << arg
        end
    end
end


# check for hyperlinks in literal blocks
# if only master.adocs are checked the output is individual .adoc files containing the match
if options[:s]
    puts "\nChecking #{ARGV} for hyperlinks in literal blocks."

    hyperlinks_dict = {}

    suppress_output {
        input_files.each do |file|
            doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true

            doc.find_by(context: :literal).each do |l|
                # if script is running on files with unresolved conditionals
                # it might resilt in literal blocks with no content
                # hence next
                if l.content.nil?
                    next
                end
                if l.content.match('<a href=')
                    if hyperlinks_dict.key?(l.file)
                        hyperlinks_dict[l.file] += [l.lineno]
                    else
                        hyperlinks_dict[l.file] = [l.lineno]
                    end
                end
            end
        end
    }


    hyperlinks_dict.each do|key,value|
    puts "\nFile:\t\t\t#{key}"
    puts"Start of the block:\t#{value}"
    end

    puts "\nStatistics:"
    puts "Input files checked: #{input_files.size}. Errors found: #{hyperlinks_dict.size}."
end
