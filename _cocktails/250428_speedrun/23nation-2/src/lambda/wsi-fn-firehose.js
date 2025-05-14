export const handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(Buffer.from(record.data, 'base64').toString())
    const time = new Date(data.timestamp)

    let processingtime = data.processingtime

    if (processingtime.endsWith('ms'))
      processingtime = parseFloat(processingtime.replace('ms', ''))

    else if (processingtime.endsWith('\u00b5s'))
      processingtime = parseFloat(processingtime.replace('\u00b5s', '')) * 1000

    else if (processingtime.endsWith('ns'))
      processingtime = parseFloat(processingtime.replace('ns', '')) * 1000 * 1000

    else
      processingtime = parseFloat(processingtime.replace('s', '')) / 1000

    return {
      recordId: record.recordId,
      result: 'Ok',
      data: Buffer.from(JSON.stringify({
        ...data,

        year: time.getFullYear().toString(),
        month: (time.getMonth()+1).toString(),
        day: time.getDate().toString(),
        hour: time.getHours().toString(),
        minute: time.getMinutes().toString(),
        second: time.getSeconds().toString(),

        processingtime
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
