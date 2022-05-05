#!/usr/bin/env ruby

require 'find'


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


# sort arguments
def return_expanded_files(input_files, pattern)
    accepted_extension = [".adoc"]
    expanded_files = []

    input_files.each do |file|

        abort "#{File.basename( ($0), ".*" )}: Provided path does not exist: '#{file}'" if not File.exist?(file)

        if File.directory?(file)
            Find.find(file) do |path|
                unless expanded_files.include?(path)
                    expanded_files << path if path =~ /#{pattern}/
                end
            end

        elsif File.file?(file)
            if not accepted_extension.include? File.extname(file)
                puts "#{File.basename( ($0), ".*" )}: invalid file extension: #{file}"
                puts "Accepted file extensions: #{accepted_extension}"
                exit 1
            end
            unless expanded_files.include?(file)
                expanded_files << file
            end
        end
    end
    return expanded_files
end


def return_hyperlinks_dict(expanded_files)

    hyperlinks_dict = {}
    files_checked = []

    suppress_output {
        expanded_files.each do |file|
            doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true

            doc.find_by(context: :literal).each do |l|
                unless files_checked.include?(l.file)
                    files_checked << l.file
                end
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
    return hyperlinks_dict, files_checked
end
