Facter.add("indexer_templates") do
  setcode do
    result = Dir.entries("/etc/logstash/conf.d")
    #Facter::Util::Resolution.exec('/bin/ls /etc/logstash/conf.d')
    puts result.join(",")
  end
end
