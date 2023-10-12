require 'tmpdir'
require './constants'

Dir.mktmpdir do |tmpdir| 
  list_path = "#{tmpdir}/#{LIST_FN}"
  system <<-EOS
curl -o #{list_path} #{LIST_URL}
  EOS
  File.foreach(list_path) {|l|
    url = l.strip
    fn = url.split('/')[-1]
    dst_path = "#{SRC_DIR}/#{fn}"
    if File.exist?(dst_path)
      $stderr.print <<-EOS
skip #{dst_path} because it exists.
      EOS
    else
      system <<-EOS
curl -C 0 -o #{tmpdir}/#{fn} #{url}
mv #{tmpdir}/#{fn} #{SRC_DIR}/#{fn}
      EOS
    end
  }
end

