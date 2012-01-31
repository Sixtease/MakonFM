--SET plperl.use_strict = true; --FIXME

DROP TRIGGER IF EXISTS version_increment ON submissions;
DROP FUNCTION IF EXISTS raise_version_tg();
DROP FUNCTION IF EXISTS raise_version(varchar(255));
DROP FUNCTION IF EXISTS init_version(varchar(255));

CREATE OR REPLACE FUNCTION init_version(IN vkey varchar(255)) RETURNS integer AS $BODY$
    INSERT INTO versions(key, value) VALUES ($1, 1);
    SELECT 0;
$BODY$ LANGUAGE SQL VOLATILE;

CREATE OR REPLACE FUNCTION inc_version(IN vkey varchar(255)) RETURNS integer AS $BODY$
    UPDATE versions SET value = 1 + (SELECT value FROM versions WHERE key = $1);
    SELECT 0;
$BODY$ LANGUAGE SQL VOLATILE;

CREATE OR REPLACE FUNCTION raise_version(IN vkey varchar(255)) RETURNS integer AS $BODY$
    SELECT CASE 
        WHEN count(*) = 0 THEN
            (SELECT init_version($1))
        ELSE
            (SELECT inc_version($1))
        END
    FROM versions WHERE key = $1;
    
    SELECT 0;
$BODY$ LANGUAGE SQL VOLATILE;

CREATE OR REPLACE FUNCTION raise_version_tg() RETURNS trigger AS $BODY$
    my $key = $_TD->{new}{filestem};
    spi_exec_query( qq{SELECT raise_version('$key');} );
    return
$BODY$ LANGUAGE plperl;

CREATE TRIGGER version_increment AFTER INSERT ON submissions FOR EACH ROW EXECUTE PROCEDURE raise_version_tg();
