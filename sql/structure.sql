CREATE TABLE IF NOT EXISTS weather (
    station VARCHAR(12) NOT NULL,
    created TIMESTAMP WITH TIME ZONE DEFAULT now(),
    temperature_indoor NUMERIC NOT NULL,
    temperature_outdoor NUMERIC NOT NULL,
    dewpoint NUMERIC NOT NULL,
    humidity_indoor INTEGER NOT NULL,
    humidity_outdoor INTEGER NOT NULL,
    wind_speed NUMERIC NOT NULL,
    wind_dir NUMERIC NOT NULL,
    wind_direction VARCHAR(12) NOT NULL,
    wind_chill NUMERIC NOT NULL,
    rain_1h NUMERIC NOT NULL,
    rain_24h NUMERIC NOT NULL,
    rain_total NUMERIC NOT NULL,
    pressure NUMERIC NOT NULL,
    tendency VARCHAR(12) NOT NULL,
    forecast VARCHAR(12) NOT NULL
);

CREATE INDEX IF NOT EXISTS weather_created_index ON weather (created DESC);

CREATE TABLE IF NOT EXISTS room (
    room_id SERIAL PRIMARY KEY,
    label CHARACTER VARYING NOT NULL
);

CREATE TABLE IF NOT EXISTS temperature (
    created TIMESTAMP WITH TIME ZONE DEFAULT now(),
    room_id INTEGER REFERENCES room(room_id),
    temperature NUMERIC NOT NULL,
    PRIMARY KEY (created, room_id)
);

CREATE INDEX IF NOT EXISTS temperature_created_index ON weather (created DESC);

CREATE OR REPLACE FUNCTION copy_weather_temperature()
    RETURNS trigger AS
$BODY$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO temperature (created, room_id, temperature)
            VALUES(NEW.created, 2, NEW.temperature_indoor);
        INSERT INTO temperature (created, room_id, temperature)
            VALUES(NEW.created, 3, NEW.temperature_outdoor);

        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE temperature
            SET temperature = NEW.temperature_indoor
            WHERE room_id = 2 AND created = OLD.created;
        UPDATE temperature
            SET temperature = NEW.temperature_outdoor
            WHERE room_id = 3 AND created = OLD.created;

        return NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        DELETE FROM temperature
            WHERE (room_id = 2 OR room_id = 3) AND created = OLD.created;

        return OLD;
    END IF;

    RETURN null;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER IF EXISTS copy_weather_temperature ON weather;

CREATE TRIGGER copy_weather_temperature
BEFORE INSERT OR UPDATE OR DELETE
ON weather
FOR EACH ROW
    EXECUTE PROCEDURE copy_weather_temperature();
