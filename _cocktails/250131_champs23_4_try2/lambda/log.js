export const handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(Buffer.from(record.data, 'base64').toString())
    const time = new Date(data.time)
    
    console.log(JSON.stringify(data))

    return {
      recordId: record.recordId,
      result: 'Ok',
      data: Buffer.from(JSON.stringify({
        year: time.getFullYear().toString(),
        month: (time.getMonth()+1).toString(),
        day: time.getDate().toString(),
        hour: time.getHours().toString(),
        minute: time.getMinutes().toString(),
        second: time.getSeconds().toString(),
        path: data.path,
        method: data.method,
        statuscode: data.statuscode,
        responsetime: data.responsetime
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
