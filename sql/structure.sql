CREATE TABLE IF NOT EXISTS weather (
    station VARCHAR(12) NOT NULL,
    created timestamp without time zone DEFAULT now() PRIMARY KEY,
    temperature_indoor VARCHAR(12) NOT NULL,
    temperature_outdoor VARCHAR(12) NOT NULL,
    dewpoint VARCHAR(12) NOT NULL,
    humidity_indoor VARCHAR(12) NOT NULL,
    humidity_outdoor VARCHAR(12) NOT NULL,
    wind_all VARCHAR(12) NOT NULL,
    winddir VARCHAR(12) NOT NULL,
    directions VARCHAR(12) NOT NULL,
    windchill VARCHAR(12) NOT NULL,
    rain_1h VARCHAR(12) NOT NULL,
    rain_24h VARCHAR(12) NOT NULL,
    rain_total VARCHAR(12) NOT NULL,
    rel_pressure VARCHAR(12) NOT NULL,
    tendency VARCHAR(12) NOT NULL,
    forecast VARCHAR(12) NOT NULL
);

CREATE TABLE IF NOT EXISTS room (
    room_id SERIAL PRIMARY KEY,
    label CHARACTER VARYING NOT NULL
);

CREATE TABLE IF NOT EXISTS temperature (
    created TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    room_id INTEGER NOT NULL REFERENCES room,
    temperature NUMERIC NOT NULL,
    PRIMARY KEY(created, room_id)
);

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

CREATE TRIGGER copy_weather_temperature
BEFORE INSERT OR UPDATE OR DELETE
ON weather
FOR EACH ROW
    EXECUTE PROCEDURE copy_weather_temperature();
