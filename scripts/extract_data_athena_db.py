from site import execusercustomize
import boto3
import sys
import logging

# Setup logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)


def is_db_available(db_name):
    """
    Check if the Athena database is available or not.

    :param db_name: Athena database name.
    :return flag: true for existence, false otherwise.
    """
    glue = boto3.client("glue")
    try:
        glue.get_database(Name=db_name)
        return True
    except Exception as e:
        logger.error(f"Database not found on Glue: {e}")
        return False


def are_tables_available(db_name, table_names):
    """
    Check if Glue tabes are available inside database. If even one is missing, throw an error.

    :param db_name: Athena database name.
    :param table_names: names pf Glue tables to check.
    :return flag: true for existence, false otherwise.
    """
    glue = boto3.client("glue")
    for table_name in table_names:
        try:
            glue.get_table(DatabaseName=db_name, Name=table_name)
        except:
            logger.error(f"{table_name} is missing from Glue Catalog.")
            return False
    return True
    all_tables = glue.get_table


def execute_query(landing_bucketname, db_name, table_name, limit=None):
    """
    Run SQL query on Athena. Limit parameter is optional.

    :param landing_bucketname: name of S3 bucket where data should be placed.
    :param db_name: name of the Athena database.
    :param table_name: name of Glue table.
    """
    athena = boto3.client("athena")
    queryStart = athena.start_query_execution(
        QueryString=f'SELECT  * FROM {db_name}.{table_name}{"" if limit is None else " limit "+str(limit)}',
        QueryExecutionContext={"Database": f"{db_name}"},
        ResultConfiguration={
            "OutputLocation": f"s3://{landing_bucketname}/neo4j_input/{table_name}"
        },
    )
    return


def main():
    """
    Main steps for dta extraction from Athena database.
    """
    logger.info("Extract data from Athena database as CSV files.")
    db_name = "dbt_fgasta_dev"
    table_names = [
        "asset_content_history",
        "course_rating",
        "user_user_details",
        "user_user_groups",
        "asset_invitations",
        "user_user_language",
        "int_asset_content_history",
        "int_course_content_history",
        "course_coursepath",
        "course_content_details",
        "asset_content_details",
        "course_content_history",
        "asset_rating",
    ]
    landing_bucketname = "recommender-graph-db-dev"
    logger.info(f"Check if {db_name} exists on Glue.")
    db_exists = is_db_available(db_name)
    if not db_exists:
        logger.warning(f"Glue database {db_name} does not exists. Process stop!")
        sys.exit(1)
    logger.info(f"Check if all tables exist on Glue.")
    all_tables_exists = are_tables_available(db_name, table_names)
    if not all_tables_exists:
        logger.warning(f"Not all necessary tables exists. Process stop!")
        sys.exit(1)

    for table_name in table_names:
        logger.info(f"Extracting data from {table_name}.")
        try:
            execute_query(landing_bucketname, db_name, table_name)
        except Exception as e:
            logger.error(f"Unable to process data on {table_name}: {e}")
            sys.exit(1)
    return


if __name__ == "__main__":
    main()
