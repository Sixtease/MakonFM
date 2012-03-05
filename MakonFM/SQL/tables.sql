DROP TABLE IF EXISTS versions;
DROP TABLE IF EXISTS submissions;

CREATE TABLE submissions (
    id serial PRIMARY KEY,
    filestem varchar(255) NOT NULL,
    sub_ts timestamp(0) WITH TIME ZONE NOT NULL DEFAULT now(),
    start_ts real NOT NULL CHECK (start_ts >= 0),
    end_ts real NOT NULL CHECK (end_ts > 0),
    transcription text NOT NULL,
    author text,
    matched_ok boolean NOT NULL,
    CHECK (start_ts < end_ts),
    UNIQUE (author, sub_ts)
);

CREATE TABLE versions (
    key varchar(255) PRIMARY KEY,
    value integer NOT NULL
);
