import fs from 'node:fs/promises'
import crypto from 'node:crypto'

;(async () => {

// 

  await fs.mkdir('./4_logs')
    .catch(() => {})

  const ua_cand = [
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:137.0) Gecko/20100101 Firefox/137.0',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41',
    'Opera/9.80 (Macintosh; Intel Mac OS X; U; en) Presto/2.2.15 Version/10.00',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1',
    'PostmanRuntime/7.26.5'
  ]

  // total log‐lines
  const TOTAL_LOGS = 28 * 1000;

  // core metrics
  const GET_USER_COUNT      = 1_291;
  const POST_USER_TOP_COUNT =   682;
  const _302_A = 2_388; // 10.0.20.127
  const _302_B = 1_418; // 10.0.1.122
  const _302_C = 1_002; // 10.0.21.161
  const _302_O =   877; // “other” 302s

  // how many variety calls you want
  const VARIETY_COUNT = 3_000;

  // after core + 302 + variety, fill the rest with 200s
  const fixedCount = 
    GET_USER_COUNT +
    POST_USER_TOP_COUNT +
    _302_A + _302_B + _302_C + _302_O;
  const REMAINING = TOTAL_LOGS - fixedCount - VARIETY_COUNT;

  // the extra paths & IPs you wanted
  const extraPaths = ['/v1/cart','/v1/checkout','/v1/product','/v1/inventory'];
  const extraIps   = ['10.0.30.10','10.0.31.11','10.0.32.12','10.0.33.13'];

  function getRandom(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
  }

  const cand = [
    // 1) GET /v1/user → 1 291×
    ...Array(GET_USER_COUNT).fill(
      ['GET',  '/v1/user', '10.0.11.123', '200']
    ),

    // 2) POST /v1/user → 682×
    ...Array(POST_USER_TOP_COUNT).fill(
      ['POST', '/v1/user', '10.0.11.123', '200']
    ),

    // 3) the four 302 buckets
    ...Array(_302_A).fill(
      ['GET', '/v1/order', '10.0.20.127', '302']
    ),
    ...Array(_302_B).fill(
      ['GET', '/v1/order', '10.0.1.122', '302']
    ),
    ...Array(_302_C).fill(
      ['GET', '/v1/order', '10.0.21.161', '302']
    ),
    ...Array(_302_O).fill(
      ['GET', '/v1/order', '10.0.99.99', '302']
    ),

    // 4) your “variety” calls (200 / 404 / 500)
    ...Array(VARIETY_COUNT).fill().map(() => {
      const method = Math.random() > 0.5 ? 'GET' : 'POST';
      const path   = getRandom(extraPaths);
      const ip     = getRandom(extraIps);
      const r      = Math.random();
      const status = r < 0.8   ? '200'
                  : r < 0.9   ? '404'
                  :            '500';
      return [method, path, ip, status];
    }),

    // 5) the remaining 200s to hit exactly 28 000
    ...Array(REMAINING).fill(
      ['GET', '/v1/order', '10.0.100.100', '200']
    ),
  ];

  // now shuffle and write exactly 28 files of 1 000 lines:
  shuffle(cand);


  let date = Date.now()
  let conn_id = crypto.randomUUID().replace(/-/g, '')
  let ua = ua_cand[Math.floor(Math.random()*ua_cand.length)]
  let port = Math.floor(Math.random() * 40000) + 10000

  for (const i in Array(28).fill(1)) {
    const contents = []
    
    for (const j in Array(1000).fill(1)) {
      const cand_item = cand[parseInt(i)*1000+parseInt(j)]

      if (Math.random() > 0.7) {
        conn_id = crypto.randomUUID().replace(/-/g, '')
        ua = ua_cand[Math.floor(Math.random()*ua_cand.length)]
        port = Math.floor(Math.random() * 40000) + 10000
      }

      contents.push(
        `http ${new Date(date).toISOString().replace('Z', '')}${Math.floor(Math.random() * 1000).toString().padEnd(3, '0')}Z ` +
        `app/test-alb/60862c993db83936 ${cand_item[2]}:${port} - -1 -1 -1 ${cand_item[3]} - ${Math.floor(Math.random() * 1000)} ${Math.floor(Math.random() * 1000)} ` +
        `"${cand_item[0]} http://test-alb-798586997.ap-northeast-2.elb.amazonaws.com:80${cand_item[1]} HTTP/1.1" ` +
        `"${ua}" - - ` +
        `arn:aws:elasticloadbalancing:ap-northeast-2:000000000000:targetgroup/application/97f432f054de4194 ` + 
        `"Root=1-${crypto.randomUUID().replace(/-/g, '').slice(0, 8)}-${crypto.randomUUID().replace(/-/g, '').slice(8)}" "-" "-" 0 ` +
        `${new Date(date-Math.random() * 1000).toISOString().replace('Z', '')}${Math.floor(Math.random() * 1000).toString().padEnd(3, '0')}Z "forward" ` +
        `"-" "-" "-" "-" "-" "-" TID_${conn_id}`)

      date += Math.random() * 1000 * 10
    }

    await fs.writeFile(`./4_logs/elb_log_${parseInt(i)+1}.txt`, contents.join('\n'))
  }

// 

})()

function shuffle(array) {
  var m = array.length, t, i;
  while (m) {
    i = Math.floor(Math.random() * m--);
    t = array[m];
    array[m] = array[i];
    array[i] = t;
  }
}
