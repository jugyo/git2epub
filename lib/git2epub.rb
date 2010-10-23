require 'bundler/setup'
Bundler.require :default

require 'mime/types'
require 'tmpdir'
require 'fileutils'

module Git2Epub
  class << self
    def run(git_url, epub_file = nil)
      dir = git_clone(git_url)

      epub = EeePub::Easy.new do
        title       git_url
        creator     `whoami`
        identifier  git_url, :scheme => 'URL'
        uid         git_url
      end

      add_contents(epub, dir, git_url)

      epub_file = File.basename(git_url) + '.epub' unless epub_file
      puts "\e[32m => #{epub_file}\e[0m"
      epub.save(epub_file)
    end

    def git_clone(git_url)
      dir = File.join(Dir.tmpdir, 'git2epub', File.basename(git_url))
      FileUtils.rm_rf dir
      FileUtils.mkdir_p dir
      system 'git', 'clone', git_url, dir
      dir
    end

    def add_contents(epub, dir, git_url)
      contents = Dir[File.join(dir, '**', '*')].
          select { |f| File.file?(f) && MIME::Types.of(f).first.ascii? rescue false }

      epub.sections << ['Index', render('index.haml', :git_url => git_url, :contents => contents, :dir => dir)]

      contents.each do |content|
        label = content.sub(File.join(dir, '/'), '')
        epub.sections << [label, render('section.haml', :label => label, :content => content)]
        puts "\e[35m#{label}\e[0m"
      end
    end

    def render(template_name, locals)
      Tilt.new(template(template_name), :escape_html => true).render(self, locals)
    end

    def template(name)
      File.join(File.dirname(__FILE__), 'templates', name)
    end
  end
end
