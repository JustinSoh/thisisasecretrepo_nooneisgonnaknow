/* create some fake educator */

INSERT INTO educator(staff_nr, first_name, last_name, email) VALUES('A1234', 'Mati', 'Tong', 'test@email.com');

INSERT INTO question(statement, description, type, status,  staff_nr) VALUES('test mcq question', 'blah', 'MCQ', 'Public',  'A1234');
INSERT INTO question(statement, description, type, status,  staff_nr) VALUES('test mrq question', 'blah', 'MRQ', 'Public',  'A1234');
SELECT * from question; 
/* they should both be invalid */

INSERT INTO answer(content, position, correct, question_id) VALUES('option 1', 1, True, '1');
INSERT INTO answer(content, position, correct, question_id) VALUES('option 2', 2, False, '1');
INSERT INTO answer(content, position, correct, question_id) VALUES('option 1', 1, True, '2');
-- /* mcq should become valid but mrq should still be invalid */
SELECT * from question;


INSERT INTO answer(content, position, correct, question_id) VALUES('option 3', 3, False, '2');
INSERT INTO answer(content, position, correct, question_id) VALUES('option 2', 2, False, '2');
INSERT INTO answer(content, position, correct, question_id) VALUES('option 4', 4, True, '2');
-- /* both should become valid */
SELECT * from question;


/* part 2 - test to see if the tag_question works */ 
INSERT INTO tag(text) VALUES ('DBMS');
INSERT INTO tag(text) VALUES ('OS');
INSERT INTO tag(text) VALUES ('Digital Forensics');


INSERT INTO tag_question(text, question_id) VALUES ('DBMS', 1);
INSERT INTO tag_question(text, question_id) VALUES ('OS', 1);
INSERT INTO tag_question(text, question_id) VALUES ('Digital Forensics', 2);

/* verify at this point that tag_question has question_id 1 having tags DBMS and OS while question_id 2 has Digital Forensics as a tag */
SELECT * from tag_question tq, question q 
where q.question_id = tq.question_id;


/* this should fail as the end date < start date */
-- INSERT INTO quiz(name, total_points, mandatory, status, avail_from, avail_to, published, available, staff_nr) VALUES ('quiz 1' , 10, TRUE, 'Public', NOW(), NOW()- INTERVAL '1 day', True, True, 'A1234');

/* this should pass as the end date > start date */
INSERT INTO quiz(name, mandatory, status, avail_from, avail_to, published, available, staff_nr) VALUES ('quiz 1' , TRUE, 'Public', NOW(), NOW()+ INTERVAL '1 day', True, True, 'A1234');

/* test to see if two quizzes can have the same name - it should work */
INSERT INTO quiz(name,  mandatory, status, avail_from, avail_to, published, available, staff_nr) VALUES ('quiz' , TRUE, 'Public', NOW(), NOW()+ INTERVAL '1 day', True, True, 'A1234');
INSERT INTO quiz(name,  mandatory, status, avail_from, avail_to, published, available, staff_nr) VALUES ('quiz' , TRUE, 'Public', NOW(), NOW()+ INTERVAL '1 day', True, True, 'A1234');

INSERT INTO question_quiz(mandatory, position, question_id, quiz_id, points) VALUES (TRUE, 1, 1 , 1, 3);

/* This will fail as they have the same position in the same quiz */ 
-- INSERT INTO question_quiz(mandatory, position, question_id, quiz_id) VALUES (TRUE, 1, 2 , 1);

/* This should work as they are now of different position */
INSERT INTO question_quiz(mandatory, position, question_id, quiz_id, points) VALUES (TRUE, 2, 2 , 2, 4);

/* This should result in an insertion error as question id and quiz id already exists */ 
-- INSERT INTO question_quiz(mandatory, position, question_id, quiz_id) VALUES (TRUE, 3, 1 , 1);

/* Test the summing up of points - quiz id 1 should have 7 points and quiz id 2 should hace*/
INSERT INTO question_quiz(mandatory, position, question_id, quiz_id, points) VALUES (TRUE, 2, 2 ,1, 4);



/* test the deletion wing of the update points. quiz id 1 should have 0 points here*/
-- DELETE FROM question_quiz where question_id = 2 AND quiz_id = 1;
-- DELETE FROM question_quiz where question_id = 1 AND quiz_id = 1;
-- /* reset back to original */
-- INSERT INTO question_quiz(mandatory, position, question_id, quiz_id, points) VALUES (TRUE, 1, 1 , 1, 3);
-- INSERT INTO question_quiz(mandatory, position, question_id, quiz_id, points) VALUES (TRUE, 2, 2 ,1, 4);


-- quiz_id SERIAL PRIMARY KEY,
-- 	name TEXT NOT NULL,
-- 	no_attempts INTEGER NOT NULL DEFAULT 1,
-- 	total_points INTEGER NOT NULL,
-- 	mandatory BOOLEAN,
--     status status_type, 
-- 	time_limit INTERVAL DEFAULT '1000 years', /* as there is no time limit by default */
-- 	avail_from TIMESTAMP NOT NULL DEFAULT NOW(), /* by default the quiz should be available from NOW() unless specified (assumption) */
-- 	avail_to TIMESTAMP DEFAULT 'infinity', /* by default, the quiz is available forever*/
-- 	published BOOLEAN NOT NULL DEFAULT FALSE,
--     CONSTRAINT check_published_available CHECK (NOT published OR NOW() <= avail_to), /* checks to make sure that the quiz is published only if the avail_to is below the current time */ 
--     available BOOLEAN,
--     staff_nr VARCHAR(5) REFERENCES educator(staff_nr) ON DELETE CASCADE ON UPDATE CASCADE




