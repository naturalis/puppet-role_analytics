Facter.add("indexer_templates", :timeout => 10) do
  setcode do
    dir = "/etc/logstash/conf.d"
    if File.directory?(dir)
      filters = Dir.entries(dir)
      filters.reject! {|x| x == "." || x == ".."}
      #Facter::Util::Resolution.exec('/bin/ls /etc/logstash/conf.d')
      filters.join(",")
    else
      "none"
    end
  end
end
