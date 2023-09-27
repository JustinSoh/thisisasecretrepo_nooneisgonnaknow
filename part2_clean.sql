DROP TRIGGER IF EXISTS check_question_validity ON answer;
DROP FUNCTION IF EXISTS validate_question() CASCADE;

DROP TRIGGER IF EXISTS update_points ON question_quiz;
DROP FUNCTION IF EXISTS update_quiz_total_points() CASCADE;

DROP TRIGGER IF EXISTS same_question_in_quiz ON question_quiz;
DROP FUNCTION IF EXISTS check_if_same_question_in_quiz() CASCADE;

DROP TRIGGER IF EXISTS same_position_in_quiz ON question_quiz;
DROP FUNCTION IF EXISTS check_unique_position_in_quiz() CASCADE;


DROP TRIGGER IF EXISTS update_points_delete ON question_quiz;
DROP FUNCTION IF EXISTS update_quiz_total_points_delete() CASCADE;

DROP TABLE IF EXISTS question_quiz;
DROP TABLE IF EXISTS tag_question;

DROP TABLE IF EXISTS student CASCADE;
DROP TABLE IF EXISTS educator CASCADE;
DROP TABLE IF EXISTS answer CASCADE; 
DROP TABLE IF EXISTS question CASCADE;
DROP TABLE IF EXISTS tag; 
DROP TABLE IF EXISTS quiz;

DROP TYPE IF EXISTS question_type; 
DROP TYPE IF EXISTS status_type; 