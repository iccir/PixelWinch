require "find"
require "fileutils"

@project = File.dirname(__FILE__)

task :strings do
    Dir.chdir(@project) do |f|
        tmp = "/tmp/StringsFiles"
        FileUtils.rm_rf(tmp)
        Dir.mkdir(tmp)
        `find -E . -regex '.*\.([hmc]|mm)' -not -path '*build*' -not -path '* StringsFiles*' -not -path '*.git*'  -not -path '*PLCrashReporter*'  -print0 | xargs -0 genstrings -u -noPositionalParameters -o  #{tmp}`

        FileUtils.cp(tmp + "/Localizable.strings", "#{@project}/Resources/English.lproj")
    end
end

