# Neo4j graph database and DBT dataflow

## Purpose/Goals

This project uses data from the following type of sources:

- Users
- Assets (ex: video, doc, excel, pdf, text, images,music, etc)
- Courses (a series of content with a common domain)

The idea would be to model the entities and their relations into a graph database. What is provided is a series of fictional customers, each of them with their own SQl dumps that collect information on each of the before mentioned entities.

The end goal would be to have a graph database where relationships and nodes are stored and searchable for analytical purposes.

The tool used for the project are:

- Neo4j: an open-source graph database technology.
- DBT: a framework to transform data from data warehouses/lakes.
- AWS Athena: a service to query files on S3 buckets.
- AWS Glue: an umbrela of services that deal with ETL ops on data.
- Terraform: a framework for infrastructure deployment.

## Graph data model

![image info](./recommender-graph-db-model.jpg)

### Main design

#### Terraform AWS deployment

The project begins with a series of data divided by three ficticious customers (hosted on `data/` folder):

- customer_1
- customer_2
- customer_3

Via Terraform, I create the initial infrastructure made as follow:

![image info](./recommender-graph-db-infra.jpg)

The deployment takes care of creating the correct resources and later upload the files onto the `landing S3 bucket`. The last step of the process will run one Glue Crawler for each customer to create some tables tat will be queried via AWS Athena.

Once the tables are generated inside the AWS Glue Catalog, it is possible to query the data via AWS Console or via third-party tool (ex: DBeaver).

#### DBT workflow

DBT is a framework that leveraged SQL to transformthe data from a source to a destination. In this project both source and destination are Athena databases.
This library can provide amny functionality largely covered on their website. For now I have created models that will cater for these functions:

- Metadata collections for the main entities (ex: Users, Assets, User Languages and Courses)
- Interaction data between different entities

#### Neo4j database

Neo4j is a graph database that can host many records along with its relations. It 's quite scalable and can provide a stable experience for such use case.
There are my ways to deploy a Neo4j instance, but the one chosen here is via Sandbox.
This is a free cloud deployment offered by Neo4j itself. It lasts for 3 days and can be extended once for 7 days.

Refer to this [address](https://sandbox.neo4j.com/) if willing to try.

### Data assumptions

### Initial data processing

## Alternative scenarios

1. _What if the data was increased by 100x?_
2. _What if the pipelines were run on a daily basis by 7am?_

3. _What if the database needed to be accessed by 100+ people?_

## How to run the project

### Prerequisites

Before running the project, the user must satisfy these requirements:

### Run the workflow

## Files in the repo

Important files in the repository are:
