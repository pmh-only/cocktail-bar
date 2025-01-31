export const handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(Buffer.from(record.data, 'base64').toString())
    const time = new Date(data.dynamodb.ApproximateCreationDateTime / 1000)
    
    console.log(JSON.stringify(data))

    if (data.eventName !== "INSERT") {
      return {
        recordId: record.recordId,
        result: 'Dropped'
      } 
    }
      
    return {
      recordId: record.recordId,
      result: 'Ok',
      data: Buffer.from(JSON.stringify({
        id: data.dynamodb.NewImage.id.S,
        rating: parseFloat(data.dynamodb.NewImage.rating.S),
        productid: data.dynamodb.NewImage.product.M.id.S,
        productcategory: data.dynamodb.NewImage.product.M.category.S,
        authorid: data.dynamodb.NewImage.author.M.id.S,
        authorage: new Date().getFullYear() - new Date(data.dynamodb.NewImage.author.M.birthday.S).getFullYear() + 1,
        authorgender: data.dynamodb.NewImage.author.M.gender.S === "m" ? 0 : 1
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
