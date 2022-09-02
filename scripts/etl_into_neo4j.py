from neo4j import GraphDatabase
import pandas as pd
import sys
import logging
import awswrangler as wr

# Setup logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)


class DBConnection:
    """Object to handle Neo4J database connection."""

    def __init__(self, uri, user, pwd):
        """
        Initialize database connection object.
        """
        self.uri = uri
        self.user = user
        self.pwd = pwd
        self.driver = None
        try:
            self.driver = GraphDatabase.driver(self.uri, auth=(self.user, self.pwd))
        except Exception as e:
            print("Failed to create the driver:", e)

    def close(self):
        """
        Close connection object.
        """
        if self.driver is not None:
            self.driver.close()

    def query(self, query, parameters=None, db=None):
        """
        Perform query on database.
        """
        assert self.driver is not None, "Driver not initialized!"
        session = None
        response = None
        try:
            session = (
                self.driver.session(database=db)
                if db is not None
                else self.driver.session()
            )
            response = list(session.run(query, parameters))
        except Exception as e:
            print("Query failed:", e)
        finally:
            if session is not None:
                session.close()
        return response


def _query_athena(db_name, table_name):
    """
    Generate pandas dataframe from query performed on Athena.

    :param db_name: Glue database name.
    :param table_name: Glue table name.
    :return df: pandas dataframe with query results.
    """
    df = wr.athena.read_sql_query(sql=f"SELECT * FROM {table_name}", database=db_name)
    # Neo4j does not handle timestamp datatype for nodes quite well..
    date_columns = df.select_dtypes(include=["datetime64"]).columns.tolist()
    df[date_columns] = df[date_columns].astype(str)
    return df


def import_data(conn, query, db_name, table_name, batch_size=None):
    """
    Import data from pandas dataframe into Neo4j

    :param conn: Neo4j driver.
    :param query: Cypher query statement.
    :param db_name: Glue database name.
    :param table_name: Glue table name.
    :param batch_size: can be any number for big datasets, just to avoid query timeout.
    """
    df = _query_athena(db_name, table_name)
    if batch_size is None:
        return conn.query(query, parameters={"rows": df.to_dict("records")})
    else:
        batch = 0
        while batch * batch_size < len(df):
            res = conn.query(
                query,
                parameters={
                    "rows": df[batch * batch_size : (batch + 1) * batch_size].to_dict(
                        "records"
                    )
                },
            )
            batch += 1
        return


def add_customers(conn):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    d = {
        "customer_id": ["c1", "c2", "c3"],
        "name": ["Customer_1", "Customer_2", "Customer_3"],
        "region_name": ["us-east-1", "eu-west-2", "us-west-3"],
        "size": ["mid", "mid", "small"],
        "category": ["pharma", "ecommerce", "advertising"],
    }
    df = pd.DataFrame(data=d)

    query = """UNWIND $rows AS row
    MERGE (c:Customer {customer_id: row.customer_id, name:row.name,region_name:row.region_name,size:row.size, category:row.category})
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def main():
    DB_URI = "bolt://3.231.149.237:7687"
    DB_USER = "neo4j"
    DB_PSW = "originator-president-touch"
    ATHENA_DB = "dbt_fgasta_dev"
    logger.info("Connect to database")
    try:
        conn = DBConnection(uri=DB_URI, user=DB_USER, pwd=DB_PSW)
    except:
        logger.error("Unable to connect to Neo4j Sandbox.")
        sys.exit(1)

    table_names = [
        "asset_content_history",
        "course_rating",
        "user_user_details",
        "user_user_language",
        "course_content_details",
        "asset_content_details",
        "course_content_history",
        "asset_rating",
    ]
    logger.info(f"Check if {ATHENA_DB} exists on Glue.")
    db_exists = ATHENA_DB in wr.catalog.databases().values
    if not db_exists:
        logger.warning(f"Glue database {ATHENA_DB} does not exists. Process stop!")
        sys.exit(1)
    logger.info(f"Check if all tables exist on Glue.")
    all_tables_exists = len(
        [
            c_tab
            for c_tab in wr.catalog.tables(database=ATHENA_DB)["Table"].values
            if c_tab in table_names
        ]
    ) == len(table_names)
    if not all_tables_exists:
        logger.warning(f"Not all necessary tables exists. Process stop!")
        sys.exit(1)

    nodes_queries_dict = {
        "user_user_details": """UNWIND $rows AS row
                                MERGE (u:User {user_id: row.user_id, is_manager: row.can_manage_subordinates, valid: row.valid, registration_date: row.registration_date, recency: row.recency, customer_name: row.customer_name})
                                RETURN count(*) as total""",
        "user_user_language": """UNWIND $rows AS row
                                 MERGE (ul:UserLanguage {lang_code: row.user_language})
                                 RETURN count(*) as total""",
        "course_content_details": """UNWIND $rows AS row
                                     MERGE (c:Course {course_id: row.item_id, create_date: row.create_date, recency: row.recency, name: row.name, category_id: row.category_id, lang_code: row.lang_code, status: row.status, customer_name: row.customer_name})
                                     RETURN count(*) as total""",
        "asset_content_details": """UNWIND $rows AS row
                                    MERGE (a:Asset {asset_id: row.item_id, creation_date: row.creation_date, content_type:row.content_type, recency: row.recency, customer_name: row.customer_name})
                                    RETURN count(*) as total""",
    }

    relations_queries_dict = {
        "asset_content_history": """UNWIND $rows AS row
                                    MATCH
                                        (u:User {user_id: row.user_id}),
                                        (a:Asset {asset_id: row.asset_id})
                                        MERGE (u)-[r:HAS_WATCHED {recency: row.recency}]->(a)
                                    RETURN count(*) as total""",
        "course_rating": """UNWIND $rows AS row
                            MATCH
                                (u:User {user_id: row.user_id}),
                                (c:Course{course_id: row.item_id})
                                MERGE (u)-[r:HAS_RATED {rating:row.rating}]->(c)
                            RETURN count(*) as total""",
        "user_user_details": """UNWIND $rows AS row
                                MATCH
                                    (u:User {user_id: row.user_id}),
                                    (c:Customer{customer_id: row.customer_name})
                                    MERGE (u)-[r:WORKS_AT]->(c)
                                RETURN count(*) as total""",
        "user_user_language": """UNWIND $rows AS row
                                    MATCH
                                        (u:User {user_id: row.user_id}),
                                        (ul:UserLanguage {lang_code: row.user_language})
                                        MERGE (u)-[r:SPEAKS]->(ul)
                                    RETURN count(*) as total""",
        "course_content_history": """UNWIND $rows AS row
                                        MATCH
                                            (u:User {user_id: row.user_id}),
                                            (c:course {course_id: row.course_id})
                                            MERGE (u)-[r:IS_ENROLLED {status: row.status, recency: row.recency}]->(c)
                                        RETURN count(*) as total""",
        "asset_rating": """UNWIND $rows AS row
                            MATCH
                                (u:User {user_id: row.user_id}),
                                (a:Asset{asset_id: row.item_id})
                                MERGE (u)-[r:HAS_RATED {rating:row.rating}]->(a)
                            RETURN count(*) as total""",
    }
    logger.info("Upload customers nodes..")
    add_customers(conn)
    for table_name in table_names:
        logger.info(f"Extracting and load nodes data from {table_name} into Neo4j.")
        node_query = nodes_queries_dict.get(table_name, None)
        if node_query is None:
            logger.info(f"No nodes from table {table_name}")
            continue
        else:
            import_data(conn, node_query, ATHENA_DB, table_name, batch_size=200)
    for table_name in table_names:
        logger.info(f"Extracting and load relations data from {table_name} into Neo4j.")
        relations_query = relations_queries_dict.get(table_name, None)
        if relations_query is None:
            logger.info(f"No relations from table {table_name}")
            continue
        else:
            import_data(conn, relations_query, ATHENA_DB, table_name, batch_size=200)

    return


if __name__ == "__main__":
    main()
