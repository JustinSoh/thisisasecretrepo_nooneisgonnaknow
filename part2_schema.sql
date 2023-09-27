/* 
CREATE in the following order 
1. student 
2. educator 
3. question_type and status_type 
4. question 
5. answer 
6. validate_question() and trigger function check_question_validity 
7. tag 
8. tag_question
9. quiz 
10. question_quiz 
10.5 quiz_is_available 
11. check_if_same_position_in_quiz() and check_if_same_question_in_quiz() + trigger function 
12. update_points and update_points_delete
13. group  
15. group_quiz 
16. group_student


7. group 
8. submission

10. answer_submission
11. group_quiz
12. group_student 
13. question_quiz
*/

CREATE TABLE IF NOT EXISTS student (
	student_nr VARCHAR(10) PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	email VARCHAR(256) UNIQUE,
	last_active TIME
);



CREATE TABLE IF NOT EXISTS educator (
	staff_nr VARCHAR (5) PRIMARY KEY,
	first_name VARCHAR (50) NOT NULL, 
	last_name VARCHAR (50) NOT NULL, 
	email VARCHAR ( 256 ) UNIQUE NOT NULL,
	last_login TIMESTAMP 
);



CREATE TYPE question_type AS ENUM ('MCQ', 'MRQ');
CREATE TYPE status_type AS ENUM ('Public', 'Private');


CREATE TABLE IF NOT EXISTS question (
	question_id SERIAL PRIMARY KEY,
	statement TEXT NOT NULL,
	description TEXT,
	type question_type NOT NULL,
	status status_type NOT NULL,
    valid BOOLEAN NOT NULL DEFAULT FALSE,
    staff_nr VARCHAR(5) REFERENCES educator(staff_nr) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS answer (
	answer_id SERIAL PRIMARY KEY,
	content VARCHAR(256),
	position INTEGER NOT NULL CHECK(position > 0),
	correct BOOLEAN NOT NULL,
	question_id SERIAL REFERENCES question(question_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION validate_question()
RETURNS TRIGGER AS $$
DECLARE
    answer_count INT;
    correct_count INT;
    question_type question_type;
BEGIN
    -- Count the total number of answers for the question
    SELECT COUNT(*) INTO answer_count
    FROM answer
    WHERE question_id = NEW.question_id;

    -- Count the number of correct answers for the question
    SELECT COUNT(*) INTO correct_count
    FROM answer
    WHERE question_id = NEW.question_id AND correct = TRUE;

    SELECT type INTO question_type
    FROM question
    WHERE question_id = NEW.question_id;

    -- Check if it's an MCQ or MRQ
   IF question_type = 'MCQ' THEN
        -- MCQ validation: Exactly one correct answer required
        IF answer_count >= 2 AND correct_count = 1 THEN
            UPDATE question SET valid = TRUE WHERE question_id = NEW.question_id;
            -- NEW.valid := TRUE;
        ELSE
            UPDATE question SET valid = FALSE WHERE question_id = NEW.question_id;

        END IF;
    ELSIF question_type = 'MRQ' THEN
        -- MRQ validation: At least two answers required, at least one must be correct
        IF answer_count >= 2 AND correct_count >= 1 THEN
            UPDATE question SET valid = TRUE WHERE question_id = NEW.question_id;
            -- NEW.valid := TRUE;
        ELSE
            UPDATE question SET valid = FALSE WHERE question_id = NEW.question_id;

        END IF;
    ELSE
        -- Invalid question type
        UPDATE question SET valid = FALSE WHERE question_id = NEW.question_id;

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_question_validity 
AFTER INSERT OR UPDATE ON answer 
FOR EACH ROW
EXECUTE FUNCTION validate_question();

CREATE TABLE IF NOT EXISTS tag (
	text TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS tag_question(
    text TEXT REFERENCES tag(text) ON DELETE CASCADE ON UPDATE CASCADE,
    question_id SERIAL REFERENCES question(question_id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (text, question_id)
);


CREATE TABLE IF NOT EXISTS quiz (
	quiz_id SERIAL PRIMARY KEY,
	name TEXT NOT NULL,
	no_attempts INTEGER NOT NULL DEFAULT 1,
	total_points INTEGER NOT NULL DEFAULT 0,
	mandatory BOOLEAN,
    status status_type, 
	time_limit INTERVAL DEFAULT '1000 years', /* as there is no time limit by default */
	avail_from TIMESTAMP NOT NULL DEFAULT NOW(), /* by default the quiz should be available from NOW() unless specified (assumption) */
	avail_to TIMESTAMP DEFAULT 'infinity', /* by default, the quiz is available forever*/
	published BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT check_published_available CHECK (NOT published OR  ((avail_from <= NOW()) AND (NOW() <= avail_to))), /* checks to make sure that the quiz is published only if the avail_to is below the current time */ 
    available BOOLEAN,
    staff_nr VARCHAR(5) REFERENCES educator(staff_nr) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS question_quiz (
    mandatory BOOLEAN NOT NULL,
	position  INTEGER NOT NULL,
	points INTEGER NOT NULL, 
    question_id SERIAL REFERENCES question(question_id) ON DELETE CASCADE ON UPDATE CASCADE, 
    quiz_id SERIAL REFERENCES quiz(quiz_id) ON DELETE CASCADE ON UPDATE CASCADE, 
    PRIMARY KEY (quiz_id, question_id)

);

-- CREATE OR REPLACE FUNCTION update_quiz_availability() RETURNS TRIGGER AS $$ 
-- DECLARE
--     published BOOLEAN 
--     question_count INT
-- BEGIN 
--     SELECT published INTO published FROM quiz q where q.quiz_id = NEW.quiz_id ;
--     SELECT COUNT(*) FROM question q where q.question_id 
-- END; 
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER update_quiz_available
-- AFTER INSERT OR UPDATE ON question_quiz 
-- FOR EACH ROW 
-- EXECUTE FUNCTION update_quiz_availability();

CREATE OR REPLACE FUNCTION check_if_same_question_in_quiz() RETURNS TRIGGER AS $$
BEGIN 
    IF EXISTS (
        SELECT 1
        FROM question_quiz qq
        WHERE NEW.question_id = qq.question_id 
        AND NEW.quiz_id = qq.quiz_id) 
    THEN
        RAISE EXCEPTION 'Question already referenced in Quiz'; 
	END IF;
    RETURN NEW;
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER same_question_in_quiz
BEFORE INSERT OR UPDATE ON question_quiz 
FOR EACH ROW 
EXECUTE FUNCTION check_if_same_question_in_quiz();


/* The following trigger is used to ensure that two same question cannot be in the same quiz with a different position */
CREATE OR REPLACE FUNCTION check_unique_position_in_quiz() RETURNS TRIGGER AS $$
BEGIN
    -- Check if another question in the same quiz has the same position
    IF EXISTS (
        SELECT 1
        FROM question_quiz qq
        WHERE NEW.quiz_id = qq.quiz_id
          AND NEW.position = qq.position
          AND NEW.question_id <> qq.question_id -- Exclude the current question
    ) THEN
        RAISE EXCEPTION 'Two different questions cannot have the same position in a quiz.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER same_position_in_quiz
BEFORE INSERT OR UPDATE ON question_quiz 
FOR EACH ROW 
EXECUTE FUNCTION check_unique_position_in_quiz();


/*Testing in progress*/

CREATE OR REPLACE FUNCTION update_quiz_total_points() RETURNS TRIGGER AS $$
DECLARE
    quiz_exists BOOLEAN;
BEGIN
    -- Check if the quiz_id exists in the quiz table
    SELECT EXISTS(SELECT 1 FROM quiz WHERE quiz_id = NEW.quiz_id) INTO quiz_exists;

    IF quiz_exists THEN
        -- Update the total_points
        UPDATE quiz 
        SET total_points = (
            SELECT SUM(qq.points)
            FROM question_quiz qq
            WHERE NEW.quiz_id = qq.quiz_id
        )
        WHERE quiz_id = NEW.quiz_id;
 
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_quiz_total_points_delete() RETURNS TRIGGER AS $$
DECLARE
    quiz_exists BOOLEAN;
BEGIN
    -- Check if the quiz_id exists in the quiz table
    SELECT EXISTS(SELECT 1 FROM quiz WHERE quiz_id = OLD.quiz_id) INTO quiz_exists;

    IF quiz_exists THEN
        -- Update the total_points
        UPDATE quiz 
        SET total_points = (
            SELECT ((CASE WHEN SUM(qq.points) IS NULL THEN 0 ELSE SUM(qq.points) END))
            FROM question_quiz qq
            WHERE OLD.quiz_id = qq.quiz_id
        )
        WHERE quiz_id = OLD.quiz_id;
   
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_points
AFTER INSERT OR UPDATE ON question_quiz
FOR EACH ROW
EXECUTE FUNCTION update_quiz_total_points();

CREATE TRIGGER update_points_delete
AFTER DELETE ON question_quiz
FOR EACH ROW
EXECUTE FUNCTION update_quiz_total_points_delete();


/* yet to be implemented yet */ 

CREATE TABLE IF NOT EXISTS group(
	code SERIAL PRIMARY KEY, 
	name UNIQUE NOT NULL, 
	description VARCHAR ( 256 )
);

CREATE TABLE IF NOT EXISTS group_quiz(
    quiz_id SERIAL REFERENCES quiz(quiz_id) ON DELETE CASACADE ON UPDATE CASCADE
    code SERIAL REFERENCES group(code) ON DELETE CASCADE ON UPDATE CASACADE 
    PRIMARY KEY(quiz_id, code)
)


