DROP TABLE IF EXISTS prondict;
DROP TABLE IF EXISTS versions;
DROP TABLE IF EXISTS sub_info;
DROP TABLE IF EXISTS submissions;

CREATE TABLE submissions (
    id serial PRIMARY KEY,
    filestem varchar(255) NOT NULL,
    sub_ts timestamp(0) WITH TIME ZONE NOT NULL DEFAULT now(),
    start_ts real NOT NULL CHECK (start_ts >= 0),
    end_ts real NOT NULL CHECK (end_ts > 0),
    transcription text NOT NULL,
    matched_ok boolean NOT NULL,
    CHECK (start_ts < end_ts)
);

CREATE TABLE sub_info (
    id serial PRIMARY KEY,
    submission integer references submissions(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(31) NOT NULL,
    value text NOT NULL DEFAULT '',
    CONSTRAINT submission_has_max_1_field_of_a_name UNIQUE(
        submission, name
    )
);

CREATE TABLE versions (
    key varchar(255) PRIMARY KEY,
    value integer NOT NULL
);

CREATE TABLE dict (
    id serial PRIMARY KEY,
    form varchar(63) NOT NULL,
    pron text NOT NULL,
    UNIQUE(form, pron)
);
