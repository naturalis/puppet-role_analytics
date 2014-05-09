Facter.add("indexer_templates") do
  setcode do
    dir = "/etc/logstash/conf.d"
    if File.directory?(dir)
      result = Dir.entries(dir)
      #Facter::Util::Resolution.exec('/bin/ls /etc/logstash/conf.d')
      puts result.join(",")
    else
      puts "none"
    end
  end
end
