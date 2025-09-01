DECLARE
    v_rows_loaded INTEGER DEFAULT 0;
BEGIN
    -- 1) Ensure staging table exists
    EXECUTE IMMEDIATE
        'CREATE TRANSIENT TABLE IF NOT EXISTS STG_' || TARGET_TABLE || ' LIKE ' || TARGET_TABLE;

    -- 2) Copy into staging with PATTERN argument
    EXECUTE IMMEDIATE
        'COPY INTO STG_' || TARGET_TABLE || '
           FROM @STG_SALES_POSSALESDAILY_' || ENV || '
           FILE_FORMAT = (FORMAT_NAME = ' || DB_NAME || '.' || SCHEMA_NAME || '.FF_SALES_POSSALESDAILY_' || ENV || ')
           PATTERN = ''' || PATTERN || '''
           MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
           ON_ERROR = ''ABORT_STATEMENT''
           PURGE = FALSE;';

    -- 3) Merge into target
    EXECUTE IMMEDIATE
        'MERGE INTO ' || TARGET_TABLE || ' AS T
         USING STG_' || TARGET_TABLE || ' AS S
         ON T.DATE = S.DATE
          AND T.STORE_ID = S.STORE_ID
         WHEN MATCHED THEN UPDATE SET
           T.SALES_AMT   = S.SALES_AMT,
           T.SALES_QTY   = S.SALES_QTY
         WHEN NOT MATCHED THEN INSERT (
           DATE, STORE_ID, SALES_AMT, SALES_QTY
         )
         VALUES (
           S.DATE, S.STORE_ID, S.SALES_AMT, S.SALES_QTY
         );';

    RETURN 'Loaded rows into ' || TARGET_TABLE;
END;
