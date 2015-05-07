# Remove older references to cf_cli
./removeBlob.sh autoscaler-master.zip 

# Modify the link if downloading from a different repo
wget https://github.com/cf-platform-eng/autoscaler/archive/master.zip -O autoscaler-master.zip
echo y | ./addBlob.sh autoscaler-master.zip autoscaler
