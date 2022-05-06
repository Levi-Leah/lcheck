#!/usr/bin/env ruby

require 'find'


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

    if hyperlinks_dict
        hyperlinks_dict.each do|key,value|
            puts "\nFile:\t\t\t#{key}"
            puts"Start of the block:\t#{value}"
        end

        puts "\nStatistics:"
        puts "Input files: #{@expanded_files.size}. Errors found: #{hyperlinks_dict.size}. Files checked: #{files_checked.size}."
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
        doc.find_by(context: :document).each do |a|
            unless files_checked.include?(a.file)
                files_checked << a.file
            end

            unresolved_attribute = a.content.scan(Asciidoctor::AttributeReferenceRx)

            if unresolved_attribute
                if attributes_dict.key?(a.file)
                    if not unresolved_attribute.nil? || unresolved_attribute.empty?
                        attributes_dict[a.file] += unresolved_attribute.compact
                    end
                else
                    if not unresolved_attribute.nil? || unresolved_attribute.empty?
                        attributes_dict[a.file] = unresolved_attribute.compact
                    end
                end
            end
        end
    end

    if attributes_dict
        attributes_dict.each do|key,value|
            puts "\nFile:\t\t\t#{key}"
            puts "Matching string:\t#{value.map { |list| list.select { |item| not item.nil? } }}"
        end

        puts "\nStatistics:"
        puts "Input files: #{@expanded_files.size}. Files checked: #{files_checked.size}. Errors found: #{attributes_dict.size}."
        exit 1
    end

end
