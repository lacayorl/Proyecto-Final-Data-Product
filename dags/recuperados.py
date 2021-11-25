import pandas as pd
from airflow import DAG
from airflow.contrib.hooks.fs_hook import FSHook
from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.hooks.mysql_hook import MySqlHook
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago

COLUMNS = {
    "province_state": "province_state",
    "country": "country",
    "latitud": "lat",
    "longitud": "lon",
    "fecha": "fecha",
    "valor": "valor"
}

DATE_COLUMNS = ["ORDERDATE"]

dag = DAG('RECUPERADOS', description='Dag para melt recuperados siuu',
          default_args={
              'owner': 'McCloskey',
              'depends_on_past': False,
              'max_active_runs': 1,
              'start_date': days_ago(5)
          },
          schedule_interval='0 1 * * *',
          catchup=False)


def date_func(**kwargs):
    execution_date = kwargs['execution_date']
    print(execution_date)


def melt_data(**kwargs):
    filepath = f"{FSHook('fs_default_test').get_path()}/time_series_covid19_recovered_global.csv"
    source = MySqlHook('mydb').get_sqlalchemy_engine()
    dfr = (pd.read_csv(filepath))
    nombres = list(dfr.columns)
    fechas = nombres[5:len(nombres)]
    dfr = pd.melt(dfr, id_vars=nombres[0:4], value_vars=fechas, var_name="fecha")
    dfr.columns = ['province_state', 'country', 'latitud', 'longitud', 'fecha', 'valor']
    dfr['fecha'] = pd.to_datetime(dfr['fecha'])

    with source.begin() as connection:
        dfr.to_sql('recuperados', schema='test', con=connection, if_exists='append',chunksize=3000, index=False)


fr = PythonOperator(
    task_id='inicio_dag',
    dag=dag,
    python_callable= date_func,
    provide_context=True,
    op_kwargs={
    }
)

sensor_task_r = FileSensor(task_id="check_recovered_file",
                           dag=dag,
                           poke_interval=10,
                           fs_conn_id="fs_default_test",
                           filepath="time_series_covid19_recovered_global.csv",
                           timeout=100)

melt_data_operator_r = PythonOperator(
    task_id='process_data_operator',
    dag=dag,
    python_callable=melt_data,
    provide_context=True,
    op_kwargs={
    }
)

fr >> sensor_task_r >> melt_data_operator_r