-- Load data
LOAD DATA OVERWRITE `aurora_bay_data.aurora_bay_faqs`
(
    question STRING,
    answer STRING
)
FROM FILES (
    format = 'CSV',
    uris = ['gs://labs.roitraining.com/aurora-bay-faqs/aurora-bay-faqs.csv'],
    skip_leading_rows = 1
);

-- Verify Data is loaded
SELECT * FROM `aurora_bay_data.aurora_bay_faqs` LIMIT 1000;


-- 0. Create dataset if not available
CREATE SCHEMA IF NOT EXISTS aurora_bay_data;

-- PreReq: Need to create the Vertex AI connection and define Vertex AI User Role
-- 1. Create the remote embedding model
CREATE OR REPLACE MODEL
  `aurora_bay_data.embedding_model` REMOTE
WITH CONNECTION `projects/613865704440/locations/us-central1/connections/us-central1-vertex-conn` OPTIONS (ENDPOINT = 'text-embedding-004');

-- 2. Create a table with embeddings
CREATE OR REPLACE TABLE aurora_bay_data.faqs_with_embeddings AS
SELECT
  * EXCEPT(ml_generate_embedding_result),
  ml_generate_embedding_result AS q_embedding
FROM
  ML.GENERATE_EMBEDDING(
    MODEL `aurora_bay_data.embedding_model`,
    (SELECT *, question as content FROM aurora_bay_data.aurora_bay_faqs),
    STRUCT(TRUE as flatten_json_output)
  );

  -- Verify
SELECT question, q_embedding 
FROM aurora_bay_data.faqs_with_embeddings 
LIMIT 5;