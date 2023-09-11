curl https://vstsagentpackage.azureedge.net/agent/3.220.0/vsts-agent-linux-x64-3.220.0.tar.gz -o vsts-agent-linux-x64-3.220.0.tar.gz
mkdir myagent && cd myagent
tar zxvf ../vsts-agent-linux-x64-3.220.0.tar.gz

./config.sh
  entrer url ORG devops
  entrer pat
  entrer personal token pour auth agent -imglnz4ofna62ap4z6gbzzg7xmr6i7hz7mk6cilydjz7pgq455ja

./run.sh