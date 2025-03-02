iwr -Method Post http://myapp-297449287.ap-northeast-2.elb.amazonaws.com/stress/cpu -Body '{"cpu_percent": "RANDOM:10:50", "maintain_second": 30, "async": true}'
