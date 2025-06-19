fields @timestamp, @message, @logStream, @log
| filter @message not like /^(?<a>.*)$/
| sort @timestamp desc
| limit 10000
