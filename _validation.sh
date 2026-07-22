# /tmp/mpdev verify --deployer=us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0 \
#     --parameters='{"namespace":"byol-verify","name":"byol-test","license.licenseKey":"47d1d915b47fd60e949c3854a0a88e0291a7523908e7e0c21c9720c5e2d088ac","license.licenseSecret":"my-test-secret","reportingSecret":"test-secret"}'

/tmp/mpdev verify --deployer=us-docker.pkg.dev/searce-cloud-products/gcp-mp-poc-k8s/app/deployer:1.0 \
    --parameters='{"namespace":"byol-verify","name":"byol-test","licenseKey":"47d1d915b47fd60e949c3854a0a88e0291a7523908e7e0c21c9720c5e2d088ac","licenseSecret":"my-test-secret","reportingSecret":"test-secret"}'