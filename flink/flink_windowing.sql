%flink.ssql

SELECT window_start, window_end, SUM(`size`) AS total_size
FROM TABLE(TUMBLE(TABLE acclog, DESCRIPTOR(`time`), INTERVAL '15' SECOND))
GROUP BY window_start, window_end;

SELECT window_start, window_end, SUM(`size`) AS total_size
FROM TABLE(HOP(TABLE acclog, DESCRIPTOR(`time`), INTERVAL '15' SECOND, INTERVAL '30' SECOND))
GROUP BY window_start, window_end;

SELECT window_start, window_end, SUM(`size`) AS total_size
FROM TABLE(CUMULATE(TABLE acclog, DESCRIPTOR(`time`), INTERVAL '10' SECOND, INTERVAL '30' SECOND))
GROUP BY window_start, window_end;
