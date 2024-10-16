from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.http.operators.http import HttpOperator
from airflow.providers.amazon.aws.transfers.local_to_s3 import LocalFilesystemToS3Operator

from datetime import datetime

# ---

dag = DAG(
  "simple_http_dag",
  default_args={"retries": 2},
  tags=["aaa"],
  start_date=datetime(2021, 1, 1),
  schedule="* * * * *",
  catchup=False,
)

# ---

task_fetch_lorem_ipsum = HttpOperator(
  http_conn_id="lorem_ipsum_api",
  task_id="task_fetch_lorem_ipsum",
  endpoint="/api/plaintext",
  method="GET",
  log_response=True,
  dag=dag
)

def _task_save_lorem_ipsum(ti):
  lorem_ipsum = ti.xcom_pull(task_ids='task_fetch_lorem_ipsum')

  file = open("temp-lorem.txt", "w")
  file.write(lorem_ipsum)
  file.close()

task_save_lorem_ipsum = PythonOperator(
  task_id="task_save_lorem_ipsum",
  python_callable=_task_save_lorem_ipsum,
  dag=dag
)

task_transfer_to_s3 = LocalFilesystemToS3Operator(
  task_id="task_transfer_to_s3",
  filename="temp-lorem.txt",
  dest_key=f"lorem/{datetime.now().strftime('%Y-%m-%dT%H:%M:%S')}-lorem.txt",
  dest_bucket="0iojioserjiorsegjoiesrjiosger"
)

# ---

(
  task_fetch_lorem_ipsum >>
  task_save_lorem_ipsum >>
  task_transfer_to_s3
)
