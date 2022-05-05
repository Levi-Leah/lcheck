#!/usr/bin/env ruby

require 'find'

input_files = ['/home/levi/rhel-8-docs/']
pattern = ".*master\.adoc$"

# sort arguments
def method_name(input_files, pattern)
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


c = method_name(input_files, pattern)
puts c.inspect
