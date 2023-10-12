require './constants'
require 'tmpdir'
Dir.glob("#{SRC_DIR}/*.laz") {|path|
  fn = File.basename(path)
  Dir.mktmpdir {|tmpdir|
    print "#{fn}: "
    print system <<-EOS
pdal translate #{path} #{tmpdir}/a.laz --writers.las.forward=all
    EOS
    print "\n"
  }
}

