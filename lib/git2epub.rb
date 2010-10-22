require 'bundler/setup'
Bundler.require :default

require 'cgi'
require 'mime/types'
require 'tmpdir'
require 'fileutils'

module Git2Epub

  def self.run(git_url, epub_file = nil)
    dir = git_clone(git_url)

    epub = EeePub::Easy.new do
      title       git_url
      creator     `whoami`
      identifier  git_url, :scheme => 'URL'
      uid         git_url
    end

    add_contents(epub, dir, git_url)

    unless epub_file
      epub_file = git_url.match(/:(.*)/)[1].gsub('/', '-') + '.epub'
    end
    puts "\e[32m => #{epub_file}\e[0m"
    epub.save(epub_file)
  end

  def self.git_clone(git_url)
    dir = File.join(Dir.tmpdir, 'git2epub', File.basename(git_url))
    FileUtils.rm_rf dir
    FileUtils.mkdir_p dir
    system 'git', 'clone', git_url, dir
    dir
  end

  def self.add_contents(epub, dir, git_url)
    contents = Dir[File.join(dir, '**', '*')].
        select { |f| File.file?(f) && MIME::Types.of(f).first.ascii? rescue false }

    lis = []
    contents.each_with_index do |content, index|
      label = content.sub(File.join(dir, '/'), '')
      lis << "<li><a href='section_#{index + 1}.html'>#{label}</a></li>"
    end

    epub.sections << ['Index', <<-HTML]
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja">
  <head>
    <title>#{git_url}</title>
  </head>
  <body>
    <h1>#{git_url}</h1>
    <ul>
      #{lis.join("\n")}
    </ul>
  </body>
</html>
    HTML

    contents.each do |content|
      label = content.sub(File.join(dir, '/'), '')

      puts "\e[35m#{label}\e[0m"

      epub.sections << [label, <<-HTML]
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja">
  <head>
    <title>#{label}</title>
    <style>
      body {font-size: 76%;}
    </style>
  </head>
  <body>
    <h1>#{label}</h1>
    <pre><code>
#{CGI.escapeHTML(File.read(content))}
    </code></pre>
  </body>
</html>
      HTML
    end
  end
end
