// Load asset_content_details
LOAD CSV WITH HEADERS FROM 's3://recommender-graph-db-dev/neo4j_input/asset_content_details/f237ef51-5bd4-4482-b31b-7ce44b098db4.csv' AS row
MERGE (asset:Asset {id: row.item_id, content_type: row.content_type, recency: row.recency})
  ON CREATE SET assert.customer_name = row.customer_name;

// Load course_content_details
LOAD CSV WITH HEADERS FROM 's3://recommender-graph-db-dev/neo4j_input/course_content_details/a66c0de9-aaee-485d-8ae3-6d3dc4248e8f.csv' AS row
MERGE (course:Course {id: row.item_id, name: row.name, category_id:row.category_id, lang_code: row.lang_code, difficult: row.difficult, status : row.status, recency: row.recency})
  ON CREATE SET course.customer_name = row.customer_name;


// Load course_coursepath
LOAD CSV WITH HEADERS FROM 's3://recommender-graph-db-dev/neo4j_input/course_coursepath/b28ce3e5-8e47-4b16-99e1-82af098f5c95.csv' AS row
MERGE (course_path:CoursePath {id: row.item_id, path_id: row.path_id})
  ON CREATE SET course_path.customer_name = row.customer_name;

// Load user_user_details
LOAD CSV WITH HEADERS FROM 's3://recommender-graph-db-dev/neo4j_input/user_user_details/86c625da-b14f-470f-a60d-3b504df8e1bb.csv' AS row
MERGE (user:User {id: row.user_id, is_manager: row.can_manage_subordinates, valid:row.valid, registration_date: row.registration_date})
  ON CREATE SET user.customer_name = row.customer_name;

// Load user_user_group
LOAD CSV WITH HEADERS FROM 's3://recommender-graph-db-dev/neo4j_input/user_user_groups/523b0ef3-52e7-4ff8-93d8-b410df4b1045.csv' AS row
MERGE (user_group:UserGroup {user_id: row.user_id, id:row.group_id)
  ON CREATE SET user_group.customer_name = row.customer_name;

// Load user_user_language
LOAD CSV WITH HEADERS FROM 's3://recommender-graph-db-dev/neo4j_input/user_user_language/9458561b-f4f2-4e15-b776-73891d329442.csv' AS row
MERGE (user_lang:UserLang {user_id: row.user_id, language: row.user_language)
  ON CREATE SET user_lang.customer_name = row.customer_name;

// Crete customer nodes
//TO-DO

// Create indexes
CREATE INDEX asset_id FOR (a: Asset) on (a.id);
CREATE INDEX course_id FOR (c: Course) on (c.id);
CREATE INDEX user_id FOR (u: User) on (u.id);
CREATE INDEX user_group_id FOR (ug: UserGroup) on (ug.id);
CREATE INDEX course_path_id FOR (cp: CoursePath) on (cp.id);

// Load relationships user-course

// Load relationships user-asset

// Load relationships course-course_path

// Load relationships user-user_language

// Load relationships user-user_group