CREATE OR REPLACE SNOWFLAKE.ML.FORECAST FGANALYTICS_DEV.SALES.SALES_FORECAST
(
    INPUT_DATA => TABLE(FGANALYTICS_DEV.SALES.SALES_FOR_FORECAST_V)
  , TIMESTAMP_COLNAME => 'TIMESTAMP'
  , TARGET_COLNAME    => 'SALES_AMOUNT'
  , SERIES_COLNAME    => 'LOCATION'
  , CONFIG_OBJECT     => {
        'frequency'                 : '1 day'
      , 'method'                    : 'fast'
      , 'aggregation_numeric'       : 'SUM'
      , 'aggregation_categorical'   : 'FIRST'
      , 'lower_bound'               : 0.0
      , 'on_error'                  : 'SKIP'
      , 'evaluate'                  : true
      , 'evaluation_config'         : {
            'n_splits'              : 3
          , 'test_size'             : 30
          , 'gap'                   : 5
          , 'prediction_interval'   : 0.9
        }
    }
)
