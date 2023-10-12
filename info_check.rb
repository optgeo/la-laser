VERBOSE = false
Dir.glob("src/*.laz").each {|path|
  if VERBOSE
    print "checking #{path}\n"
  else
    print "."
  end
  system "pdal info --summary #{path} > /dev/null"
}

