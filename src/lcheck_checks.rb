#!/usr/bin/env ruby

require 'find'
require 'faraday'


module Regex
    CG_BLANK = '\p{Blank}'
    CC_ALL = '.'
    CustomRx = %r((^|link:|#{CG_BLANK}|&lt;|[>\(\)\[\];"'])(\\?(?:https?|file|ftp|irc)://[^\s\[\]<]*([^\s.,\[\]<]))(?:\[(|#{CC_ALL}*?[^\\])\])?)m
end

# TODO solve double reporting of unresolved attributes in assemblies + modules


# sort arguments
def return_expanded_files(input_files, pattern)
    accepted_extension = [".adoc"]
    @expanded_files = []

    input_files.each do |file|

        abort "#{File.basename( ($0), ".*" )}: Provided path does not exist: '#{file}'" if not File.exist?(file)

        if File.directory?(file)
            Find.find(file) do |path|
                unless @expanded_files.include?(path)
                    @expanded_files << path if path =~ /#{pattern}/
                end
            end

        elsif File.file?(file)
            if not accepted_extension.include? File.extname(file)
                puts "#{File.basename( ($0), ".*" )}: invalid file extension: #{file}"
                puts "Accepted file extensions: #{accepted_extension}"
                exit 1
            end
            unless @expanded_files.include?(file)
                @expanded_files << file
            end
        end
    end
    return @expanded_files
end


def get_hyperlink_errors()

    hyperlinks_dict = {}
    files_checked = []

    @expanded_files.each do |file|
        Asciidoctor::LoggerManager.logger.level = :fatal
        doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true

        doc.find_by(context: :literal).each do |l|
            realpath = File.realpath(l.file)

            unless files_checked.include?(realpath)
                files_checked << realpath
            end
            # if script is running on files with unresolved conditionals
            # it might result in literal blocks with no content
            # hence next
            if l.content.nil?
                next
            end
            if l.content.match('<a href=')
                if hyperlinks_dict.key?(realpath)
                    hyperlinks_dict[realpath] += [l.lineno]
                else
                    hyperlinks_dict[realpath] = [l.lineno]
                end
            end
        end
    end

    if hyperlinks_dict
        hyperlinks_dict.each do|key,value|
            value = value & value
            puts "\nFile path:\t\t#{key}"
            puts"Block starts on line:\t#{value}"
        end

        puts "\nStatistics:"
        puts "Input files: #{@expanded_files.size}. Files checked: #{files_checked.size}. Errors found: #{hyperlinks_dict.size}."
        exit 1
    end
end

# TODO
def get_attributes_errors()

    attributes_dict = {}
    files_checked = []

    @expanded_files.each do |file|
        Asciidoctor::LoggerManager.logger.level = :fatal
        doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true
        doc.find_by(context: :section).each do |a|

            realpath = File.realpath(a.file)

            unless files_checked.include?(realpath)
                files_checked << realpath
            end

            unresolved_attribute = a.content.scan(Asciidoctor::AttributeReferenceRx)

            if unresolved_attribute
                if attributes_dict.key?(realpath)
                    if not unresolved_attribute.empty?
                        attributes_dict[realpath] += unresolved_attribute
                    end
                else
                    if not unresolved_attribute.empty?
                        attributes_dict[realpath] = unresolved_attribute
                    end
                end
            end
        end
    end

    if attributes_dict
        attributes_dict.each do|key,value|
            all_values = value.map { |list| list.select { |item| not item.nil? } }
            unique_values = all_values & all_values
            puts "\nFile path:\t\t#{key}"
            puts "Unresolved attributes:\t#{unique_values}"
            puts "\nNOTE: unresolved attributes are reported at both assembly and module level."
        end

        puts "\nStatistics:"
        puts "Input files: #{@expanded_files.size}. Files checked: #{files_checked.size}. Errors found: #{attributes_dict.size}."
        exit 1
    end

end


def return_broken_links()
    puts "\nreturn_broken_links START"
    files_checked = []
    links_dict = {}
    broken_links = []

    @expanded_files.each do |file|
        Asciidoctor::LoggerManager.logger.level = :fatal
        doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true
        doc.find_by(context: :paragraph).each do |l|
            realpath = File.realpath(l.file)

            unless files_checked.include?(realpath)
                files_checked << realpath
            end

            #links = l.content.scan(Asciidoctor::InlineLinkRx)

            links = l.content.scan(/(?<=href\=")[^\s]*(?=">)|(?<=href\=")[^\s]*(?=" class="bare")/)

            if links
                if links_dict.key?(l.file)
                    if not links.empty?
                        links_dict[l.file] += links
                    end
                else
                    if not links.empty?
                        links_dict[l.file] = links
                    end
                end
            end
        end
    end

    puts "\nlink checking START"

    links_dict.each do |key,value|
        #puts "\nFILE:#{key}"
        #puts "\t#{value}"
        for link in value do

            if link.start_with?( '#', '/', 'tab.') or link.downcase.include?('example') or link.downcase.include?('tools.ietf.org')
                next
            end

            encoded_link = CGI.escape(link)

            conn = Faraday.new(url: encoded_link) do |faraday|
                faraday.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
            end

            begin
                conn.get(link)
            rescue URI::BadURIError
                puts "\nFile: #{key}"
                puts "Link: #{link}"
                puts "Response code: Bad URI"
            rescue URI::InvalidURIError
                puts "\nFile: #{key}"
                puts "Link: #{link}"
                puts "Response code: Invalid URL"
            rescue Faraday::Error => e
                puts "\nFile: #{key}"
                puts "Link: #{link}"
                puts "Response code: #{e.response[:status]}"
            end
        end
    end

    puts "\nStatistics:"
    puts "Input files: #{@expanded_files.size}. Files checked: #{files_checked.size}. Errors found: #{broken_links.size}."
    exit 1

end
