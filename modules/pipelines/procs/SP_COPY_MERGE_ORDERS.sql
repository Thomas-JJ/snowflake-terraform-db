DECLARE
 
  v_load_id        STRING    DEFAULT UUID_STRING();
  v_started_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP();

  v_copy_qid       STRING;
  v_merge_qid      STRING;

  v_files          VARIANT;
  v_rows_copied    NUMBER    DEFAULT 0;
  v_copy_errors    NUMBER    DEFAULT 0;

  v_rows_merged    NUMBER    DEFAULT 0;
  v_status         STRING    DEFAULT 'STARTED';

  v_copy_sql STRING;

  -- handy fully-qualified names
  v_tbl_fq         STRING    DEFAULT DB_NAME || '.' || SCHEMA_NAME || '.' || TARGET_TABLE;
  v_stg_fq         STRING    DEFAULT DB_NAME || '.' || SCHEMA_NAME || '.' || 'STG_' || TARGET_TABLE;
  v_audit_fq       STRING    DEFAULT DB_NAME || '.UTILITIES.LOAD_AUDIT';
BEGIN 

  -- 0) Start audit row (use binds)
  EXECUTE IMMEDIATE
    'INSERT INTO ' || v_audit_fq || '
       (LOAD_ID, STARTED_AT, TABLE_NAME, STATUS)
     VALUES ('''|| v_load_id ||''','''|| v_started_at || ''',''' ||v_tbl_fq|| ''', ''STARTED'')';
  -- 1) COPY into staging (choose CONTINUE if you want PARTIAL_SUCCESS to be possible)

  v_copy_sql := 
    'COPY INTO ' || v_stg_fq || '
       FROM @' || DB_NAME || '.' || SCHEMA_NAME || '.' || STAGE_NAME || '
       FILE_FORMAT=(FORMAT_NAME=' || DB_NAME || '.' || SCHEMA_NAME || '.' || FILE_FORMAT_NAME || ')
       PATTERN = ''' || PATTERN || '''
       MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
       INCLUDE_METADATA=(SRC_FILENAME=METADATA$FILENAME, SRC_ROW_NUMBER=METADATA$FILE_ROW_NUMBER)
       ON_ERROR=''CONTINUE''';

  EXECUTE IMMEDIATE v_copy_sql;

  v_copy_qid := LAST_QUERY_ID();


-- 2) Tag staged rows with the batch id
  EXECUTE IMMEDIATE
    'UPDATE ' || v_stg_fq || ' SET LOAD_ID = '''|| v_load_id || ''';';

-- 3) Summarize COPY result into files/rows/errors (no EXECUTE IMMEDIATE needed)
SELECT
    COALESCE(ARRAY_AGG(OBJECT_CONSTRUCT(
      'file', t."file",
      'status', t."status",
      'rows_parsed', t."rows_parsed",
      'rows_loaded', t."rows_loaded",
      'errors_seen', t."errors_seen",
      'first_error', t."first_error",
      'first_error_line', t."first_error_line",
      'first_error_character', t."first_error_character"
    )), ARRAY_CONSTRUCT())
    ,COALESCE(SUM(t."rows_loaded"), 0),
    COALESCE(SUM(t."errors_seen"), 0)
  INTO :v_files, :v_rows_copied, :v_copy_errors
  FROM TABLE(RESULT_SCAN(:v_copy_qid)) AS t;
  
  EXECUTE IMMEDIATE
    'UPDATE ' || v_audit_fq || '
       SET files = '''|| v_files ||''', rows_copied = '|| v_rows_copied ||', status = ''COPIED''
     WHERE load_id = '''||v_load_id||''';';

  -- 4) MERGE (fully qualified)
  EXECUTE IMMEDIATE
    'MERGE INTO ' || v_tbl_fq || ' AS T
       USING ' || v_stg_fq || ' AS S
         ON T.ORDER_ID = S.ORDER_ID
     WHEN MATCHED THEN UPDATE SET
         T.AMOUNT         = S.AMOUNT,
         T.ORDER_DATE     = S.ORDER_DATE,
         T.SRC_FILENAME   = S.SRC_FILENAME,
         T.SRC_ROW_NUMBER = S.SRC_ROW_NUMBER,
         T.UPDATED_AT     = CURRENT_TIMESTAMP(),
         T.UPDATED_BY     = ''' || SPROC_NAME ||''',
         T.LOAD_ID        = S.LOAD_ID
     WHEN NOT MATCHED THEN INSERT
         (ORDER_ID, ORDER_DATE, AMOUNT, SRC_FILENAME, SRC_ROW_NUMBER, CREATED_AT, CREATED_BY, LOAD_ID)
       VALUES
         (S.ORDER_ID, S.ORDER_DATE, S.AMOUNT, S.SRC_FILENAME, S.SRC_ROW_NUMBER, CURRENT_TIMESTAMP(), ''' || SPROC_NAME ||''', S.LOAD_ID)';
         
  v_merge_qid := LAST_QUERY_ID();

    SELECT "number of rows updated" INTO :v_rows_merged 
    FROM TABLE(RESULT_SCAN(:v_merge_qid)) ;

  -- 5) Truncate staging (fully qualified)
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || v_stg_fq;


  EXECUTE IMMEDIATE
    'UPDATE ' || v_audit_fq || '
       SET finished_at = CURRENT_TIMESTAMP(),
           rows_merged = '||v_rows_merged ||',
           status      = CASE WHEN ' || v_rows_copied || ' =  0 AND ' || v_rows_merged || ' = 0 THEN ''NOOP''
                            WHEN ' || v_copy_errors || ' > 0 THEN ''PARTIAL_SUCCESS''
                            ELSE ''SUCCESS''
                            END
     WHERE load_id = '''|| v_load_id ||''';';

EXCEPTION
  WHEN OTHER THEN
    EXECUTE IMMEDIATE
      'UPDATE ' || v_audit_fq || '
         SET finished_at = CURRENT_TIMESTAMP(),
             status      = ''FAILED''
       WHERE load_id = '''||v_load_id||''';';
    RAISE;
END;