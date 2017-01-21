--If you've already created the triggers, disable them temporarily to insert explicit values.
--> DISABLE TRIGGER nsm.trg_Cat_INS ON nsm.Cat;

INSERT INTO nsm.Cat (ParentID, Name, PLeft, PRight, Depth)
SELECT NULL AS ParentID, 'Muffin' AS Name, 1 AS PLeft, 20 AS PRight, 0 AS Depth
UNION
SELECT 1, 'Stripes', 2, 13, 1
UNION
SELECT 1, 'Fluffy', 14, 19, 1
UNION
SELECT 2, 'Tigger', 3, 4, 2
UNION
SELECT 2, 'Jack', 5, 10, 2
UNION
SELECT 2, 'Simon', 11, 12, 2
UNION
SELECT 3, 'Mittens', 15, 16, 2
UNION
SELECT 3, 'Widget', 17, 18, 2
UNION
SELECT 5, 'Smush', 6, 7, 3
UNION
SELECT 5, 'Smash', 8, 9, 3
ORDER BY ParentID, PLeft;

--Re-enable the trigger if you disabled it earlier.
--> ENABLE TRIGGER nsm.trg_Cat_INS ON nsm.Cat;

--Try these new additions after you've created/enabled the insert trigger!
INSERT INTO nsm.Cat (ParentID, Name)
VALUES	(8, 'Gidget');	--child of Widget, depth 3

INSERT INTO nsm.Cat (ParentID, Name)
VALUES	(NULL, 'Catnarok');	--new Root, depth 0

INSERT INTO nsm.Cat (ParentID, Name)
VALUES	(5, 'Smosh');	--child of Jack, depth 3
