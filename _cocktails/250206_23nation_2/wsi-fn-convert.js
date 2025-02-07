export const handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(Buffer.from(record.data, 'base64').toString())
    const time = new Date(data.timestamp)

    let processingtime = data.processingtime

    if (processingtime.endsWith('ms'))
      processingtime = parseFloat(data.processingtime.replace('ms', ''))

    else if (processingtime.endsWith('\u00b5s'))
      processingtime = parseFloat(data.processingtime.replace('\u00b5s', '')) / 1000

    else if (processingtime.endsWith('ns'))
      processingtime = parseFloat(data.processingtime.replace('ns', '')) / 1000 / 1000

    else if (processingtime.endsWith('s'))
      processingtime = parseFloat(data.processingtime.replace('s', '')) * 1000
    
    return {
      recordId: record.recordId,
      result: 'Ok',
      data: Buffer.from(JSON.stringify({
        clientip: data.clientip,
        year: time.getFullYear(),
        month: time.getMonth()+1,
        day: time.getDate(),
        hour: time.getHours(),
        minute: time.getMinutes(),
        second: time.getSeconds(),
        method: data.method,
        path: data.path,
        protocol: data.protocol,
        responsecode: data.responsecode,
        processingtime,
        useragent: data.useragent
      })).toString('base64'),
      metadata: {
        partitionKeys: {
          year: time.getFullYear().toString(),
          month: (time.getMonth()+1).toString(),
          day: time.getDate().toString()
        }
      }
    }
  });
  
  return { records: output };
};
