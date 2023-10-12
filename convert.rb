require './constants'
require 'tmpdir'
require 'json'
require 'digest'

def command(cmd)
  if DRY_RUN
    print cmd
  else
    print cmd
    system cmd
  end
end

def check(paths)
  paths.each {|path|
    print "checking #{path}... "
    command <<-EOS
pdal info #{path} > /dev/null
    EOS
    print "\n"
  }
end

def merge(dict, key, tmpdir, i)
  dst_path = "#{MID_DIR}/#{key}.laz"
  print "#{i} of #{dict.keys.size} (#{N_MODULES}): #{key}: #{dict[key].size} "
  #return if File.exist?(dst_path)
  #print "(#{dict[key].map{|v| File.basename(v)}.join(', ')})"
  print "\n"
  #check(dict[key])
  pipeline = dict[key].map{|v| {
    :type => "readers.las",
    :filename => v,
    :override_srs => "EPSG:#{SRS_IN}"
  }}
#  pipeline.push({
#    :type => 'filters.reprojection',
#    :out_srs => "EPSG:#{SRS_IN}"
#  })
  pipeline.push({
    :type => 'filters.sample',
    :radius => 1.5
  })
#  pipeline.push({
#    :type => 'filters.reprojection',
#    :out_srs => "EPSG:#{SRS_OUT}"
#  })
  pipeline.push({
    :type => 'writers.las',
    :a_srs => "EPSG:#{SRS_IN}",
    :filename => "#{dst_path}"
  })
  File.open("#{tmpdir}/pipeline.json", 'w') {|w|
    w.print JSON.dump(pipeline)
    $stderr.print JSON.pretty_generate(pipeline), "\n"
  }
  command <<-EOS
pdal pipeline #{tmpdir}/pipeline.json
  EOS
end

Dir.mktmpdir do |tmpdir|
  dict = Hash.new {|h, k| h[k] = []}
  paths = Dir.glob("#{SRC_DIR}/*.laz")
  paths.each {|path|
    key = Digest::MD5.hexdigest(path)[0..1]
    dict[key].push(path)
  }
  i = 0
  command "rm -r #{MID_DIR}; mkdir -p #{MID_DIR}"
  dict.keys.sort {|a, b| dict[a].size <=> dict[b].size}.each {|key|
    i += 1
    merge(dict, key, tmpdir, i)
    break if i == N_MODULES ##
  }
end

command <<-EOS
rm -r #{DST_DIR}
py3dtiles convert --force-srs-in --srs_in #{SRS_IN} --srs_out #{SRS_OUT} --out #{DST_DIR} #{MID_DIR}/*.laz
ipfs add --progress --recursive #{DST_DIR}
EOS
