export const handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(Buffer.from(record.data, 'base64').toString())
    const time = new Date(data.time)
    
    return {
      recordId: record.recordId,
      result: 'Ok',
      data: record.data,
      metadata: {
        partitionKeys: {
          year: time.getFullYear().toString(),
          month: (time.getMonth()+1).toString(),
          date: time.getDate().toString(),
          hour: time.getHours().toString(),
          minute: time.getMinutes().toString()
        }
      }
    }
  });
  
  return { records: output };
};
