const mysql = require('mysql2/promise')

;(async() => {
  const conn = await mysql.createConnection(process.argv[2])

  setInterval(async () => {
    console.log(await conn.query('SELECT 1;'))
  }, 100)
})()
