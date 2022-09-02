from neo4j import GraphDatabase
import pandas as pd
import sys
import logging
import time
import os
import glob

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


# def insert_data(conn, query, rows, batch_size=10000):
#     """
#     Function to handle the updating the Neo4j database in batch mode.
#     """

#     total = 0
#     batch = 0
#     start = time.time()
#     result = None

#     while batch * batch_size < len(rows):

#         res = conn.query(
#             query,
#             parameters={
#                 "rows": rows[batch * batch_size : (batch + 1) * batch_size].to_dict(
#                     "records"
#                 )
#             },
#         )
#         total += res[0]["total"]
#         batch += 1
#         result = {"total": total, "batches": batch, "time": time.time() - start}
#         print(result)

#     return result


def add_assets(conn, assets_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(assets_file)
    query = """UNWIND $rows AS row
    MERGE (a:Asset {asset_id: row.item_id, creation_date: row.creation_date, content_type:row.content_type, recency: row.recency, customer_name: row.customer_name})
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def add_courses(conn, courses_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(courses_file)
    query = """UNWIND $rows AS row
    MERGE (c:Course {course_id: row.item_id, create_date: row.create_date, recency: row.recency, name: row.name, category_id: row.category_id, lang_code: row.lang_code, status: row.status, customer_name: row.customer_name})
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def add_users(conn, users_file, batch_size=100):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(users_file)
    query = """UNWIND $rows AS row
    MERGE (u:User {user_id: row.user_id, is_manager: row.can_manage_subordinates, valid: row.valid, registration_date: row.registration_date, recency: row.recency, customer_name: row.customer_name})
    RETURN count(*) as total
    """
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


def add_user_languages(conn, user_languages_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(user_languages_file).drop_duplicates(["user_language"])
    query = """UNWIND $rows AS row
    MERGE (ul:UserLanguage {lang_code: row.user_language})
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


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


def add_user_asset_relations(conn, user_asset_relations_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(user_asset_relations_file)
    query = """UNWIND $rows AS row
    MATCH
        (u:User {user_id: row.user_id}),
        (a:Asset {asset_id: row.asset_id})
        MERGE (u)-[r:HAS_WATCHED {recency: row.recency}]->(a)
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def add_user_course_relations(conn, user_course_relations_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(user_course_relations_file)
    query = """UNWIND $rows AS row
    MATCH
        (u:User {user_id: row.user_id}),
        (c:course {course_id: row.course_id})
        MERGE (u)-[r:IS_ENROLLED {status: row.status, recency: row.recency}]->(c)
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def add_user_language_relations(conn, user_language_file, batch_size=100):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(user_language_file)
    query = """UNWIND $rows AS row
    MATCH
        (u:User {user_id: row.user_id}),
        (ul:UserLanguage {lang_code: row.user_language})
        MERGE (u)-[r:SPEAKS]->(ul)
    RETURN count(*) as total
    """
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


def add_user_customer_relations(conn, user_file, batch_size=100):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(user_file)
    query = """UNWIND $rows AS row
    MATCH
        (u:User {user_id: row.user_id}),
        (c:Customer{customer_id: row.customer_name})
        MERGE (u)-[r:WORKS_AT]->(c)
    RETURN count(*) as total
    """
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


def add_asset_rating_relations(conn, asset_rating_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(asset_rating_file)
    query = """UNWIND $rows AS row
    MATCH
        (u:User {user_id: row.user_id}),
        (a:Asset{asset_id: row.item_id})
        MERGE (u)-[r:HAS_RATED {rating:row.rating}]->(a)
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def add_course_rating_relations(conn, course_rating_file):
    """
    Prepare dataframe to be loaded into Neo4j.
    """
    df = pd.read_csv(course_rating_file)
    query = """UNWIND $rows AS row
    MATCH
        (u:User {user_id: row.user_id}),
        (c:Course{course_id: row.item_id})
        MERGE (u)-[r:HAS_RATED {rating:row.rating}]->(c)
    RETURN count(*) as total
    """

    return conn.query(query, parameters={"rows": df.to_dict("records")})


def main():
    DB_URI = "bolt://3.231.149.237:7687"
    DB_USER = "neo4j"
    DB_PSW = "originator-president-touch"
    logger.info("Connect to database")
    try:
        conn = DBConnection(uri=DB_URI, user=DB_USER, pwd=DB_PSW)
    except:
        logger.error("Unable to connect to Neo4j Sandbox.")
        sys.exit(1)

    data_files = {
        "asset_data": "data/neo4j_input/asset_content_details/1179b1ea-14dc-4b47-83b0-0ccc31beefaa.csv",
        "course_data": "data/neo4j_input/course_content_details/1cc58793-c323-436d-93be-0300cf210963.csv",
        "user_data": "data/neo4j_input/user_user_details/0e68afe5-6828-4774-8974-dfa51d539b51.csv",
        "user_language_data": "data/neo4j_input/user_user_language/4b2df06b-f7ed-4748-b717-a4eda1ef9f0d.csv",
        "user_course_relations": "data/neo4j_input/course_content_history/975b07ab-d9a6-4bc9-917d-ecec6d39fb34.csv",
        "user_asset_relations": "data/neo4j_input/asset_content_history/2c46fd0e-559a-4478-b8b0-396788d009dd.csv",
        "asset_rating_relations": "data/neo4j_input/asset_rating/99f7b516-b143-49dd-b36b-62c531a9f5ae.csv",
        "course_rating_relations": "data/neo4j_input/course_rating/b5bed68c-c9d5-4a48-a0e7-4f8cee2902d8.csv",
    }

    logger.info("Upload assets nodes..")
    add_assets(conn, data_files["asset_data"])

    logger.info("Upload courses nodes..")
    add_courses(conn, data_files["course_data"])

    logger.info("Upload users nodes..")
    add_users(conn, data_files["user_data"])

    logger.info("Upload user languages nodes..")
    add_user_languages(conn, data_files["user_language_data"])

    logger.info("Upload customers nodes..")
    add_customers(conn)

    logger.info("Create user -> asset relations..")
    add_user_asset_relations(conn, data_files["user_asset_relations"])

    logger.info("Create user -> course relations..")
    add_user_course_relations(conn, data_files["user_course_relations"])

    logger.info("Create user -> language relations..")
    add_user_language_relations(conn, data_files["user_language_data"])

    logger.info("Create user -> customer relations..")
    add_user_customer_relations(conn, data_files["user_data"])

    logger.info("Create user -> asset rating relations..")
    add_asset_rating_relations(conn, data_files["asset_rating_relations"])

    logger.info("Create user -> course rating relations..")
    add_course_rating_relations(conn, data_files["course_rating_relations"])

    return


if __name__ == "__main__":
    main()
