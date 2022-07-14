#!/usr/bin/env ruby

require 'find'
require 'faraday'
require 'thread'


# expands argument list and returns a list of files to be checked
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
    #Parses the file for links; excludes pseudo links
        #e.g. xrefs
    #Creates a hash with links as keys and file paths as values
        #e.g. hash = {'www.example.com'=>['path/to/file1.adoc', 'path/to/file2.adoc']}
    #Runs link checker and prints the results.
    files_checked = []
    links_dict = {}

    @expanded_files.each do |file|
        Asciidoctor::LoggerManager.logger.level = :fatal
        doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true
        doc.find_by(context: :paragraph).each do |l|
            realpath = File.realpath(l.file)

            unless files_checked.include?(realpath)
                files_checked << realpath
            end

            links = l.content.scan(/(?<=href\=")[^\s]*(?=">)|(?<=href\=")[^\s]*(?=" class="bare")/)

            if not links.empty?
                links.each do |link|
                    next if link.start_with?( '#', '/', 'tab.', 'file', 'mailto', 'ftp://') or link.downcase.include?('example') or link.downcase.include?('tools.ietf.org') or link.empty? or link == 'ftp.gnome.org'
                    if not links_dict.key?(link)
                        links_dict[link] = [l.file]
                    else
                        if not links_dict[link].include?(l.file)
                            links_dict[link].push(l.file)
                        end
                    end
                end
            end
        end
    end

    broken_links = queue_broken_links(links_dict)

    puts "\nStatistics:"
    puts "Input files: #{@expanded_files.size}. Files checked: #{files_checked.size}. Errors found: #{broken_links}."
    exit 1

end


def queue_broken_links(links_dict)
    # takes in the link: path hash
        # #e.g. hash = {'www.example.com'=>['path/to/file1.adoc', 'path/to/file2.adoc']}
    # Runs link check on the hash keys
    # Returns the list of broken links (for statistics)
    # Handles exceptions
    broken_links = 0

    semaphore = Queue.new
    10.times { semaphore.push(1) }

    threads = []

    links_dict.each do |link,files|
        threads << Thread.new do
            semaphore.pop

            encoded_link = CGI.escape(link)

            conn = Faraday.new(url: encoded_link) do |faraday|
                faraday.response :raise_error
            end

            begin
                conn.get(link)
            rescue URI::BadURIError
                broken_links += 1
                puts "\nFile: #{files}"
                puts "Link: #{link}"
                puts "Response code: Bad URI"
            rescue URI::InvalidURIError
                broken_links += 1
                puts "\nFile: #{files}"
                puts "Link: #{link}"
                puts "Response code: Invalid URL"
            rescue Faraday::Error => e
                broken_links += 1
                puts "\nFile: #{files}"
                puts "Link: #{link}"
                puts "Response code: #{e.response[:status]}"
            end
            semaphore.push(1) # Release token
        end
    end

    threads.each(&:join)

    return broken_links
end



def check_link_pattern(link_pattern)
    files_checked = []
    links_dict = {}

    subpattern = link_pattern[/[^\/]+/]

    @expanded_files.each do |file|
        Asciidoctor::LoggerManager.logger.level = :fatal
        doc = Asciidoctor.convert_file file, safe: :safe, catalog_assets: true, sourcemap: true
        doc.find_by(context: :paragraph).each do |l|
            realpath = File.realpath(l.file)

            unless files_checked.include?(realpath)
                files_checked << realpath
            end


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

    wrong_links_dict = {}
    wrong_pattern_links_count = 0

    links_dict.each do |key,value|
        for link in value
            if link.include?(subpattern) and not link.include?(link_pattern)
                if wrong_links_dict.key?(key)
                    wrong_pattern_links_count +=1
                    wrong_links_dict[key] += link
                else
                    wrong_pattern_links_count +=1
                    wrong_links_dict[key] = link
                end
            end
        end
    end

    if wrong_links_dict
        wrong_links_dict.each do|key,value|
            puts "\nFile path:\t\t#{key}"
            puts "Wrong pattern link:\t#{value}"
        end
    end

    puts "\nStatistics:"
    puts "Input files: #{@expanded_files.size}. Files checked: #{files_checked.size}. Errors found: #{wrong_pattern_links_count}."
    exit 1
end
