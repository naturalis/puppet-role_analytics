Facter.add("indexer_templates") do
  setcode do
    dir = "/etc/logstash/conf.d"
    if File.directory?(dir)
      filters = Dir.entries(dir)
      filters.reject! {|x| x == "."|".." }
      #filters.reject! {|x| x == ".." ||  }
      #Facter::Util::Resolution.exec('/bin/ls /etc/logstash/conf.d')
      puts filters.join(",")
    else
      puts "none"
    end
  end
end
