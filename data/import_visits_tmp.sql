BEGIN;

INSERT INTO :moduleSchema.:visitsTmpTable
    (id_visit_meshe, site_code, date_min, date_max, meshe_code, presence)
VALUES (
    :visitId,
    :siteCode,
    :'dateStart',
    :'dateEnd',
    :'mesheCode',
    :'presence'
) ;

COMMIT;
