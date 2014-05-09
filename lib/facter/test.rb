Facter.add("test_fact") do
  setcode do
    Facter::Util::Resolution.exec('/bin/ls /etc/logstash/conf.d')
  end
end
