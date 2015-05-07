# Download the latest Linux 64 bit CF CLI binary from https://github.com/cloudfoundry/cli/releases
# Edit the link as newer releases are published

# Remove older references to cf_cli
./removeBlob.sh autoscaler-master.zip 
wget https://github.com/cf-platform-eng/autoscaler/archive/master.zip -O autoscaler-master.zip
echo y | ./addBlob.sh autoscaler-master.zip autoscaler
