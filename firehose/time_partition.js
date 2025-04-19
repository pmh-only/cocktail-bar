export const handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(Buffer.from(record.data, 'base64').toString())
    const time = new Date(data.time)
    
    return {
      recordId: record.recordId,
      result: 'Ok',
      data: record.data,
      // data: Buffer.from(JSON.stringify({
      //   year: time.getFullYear().toString(),
      //   month: (time.getMonth()+1).toString(),
      //   day: time.getDate().toString(),
      //   hour: time.getHours().toString(),
      //   minute: time.getMinutes().toString(),
      //   second: time.getSeconds().toString(),

      //   path: data.path,
      //   method: data.method,
      //   statuscode: data.status_code,
      //   responsetime: data.latency
      // })).toString('base64'),
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
